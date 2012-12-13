#!/usr/bin/env luajit

local setmetatable = setmetatable
local type = type
local ipairs = ipairs
local error = error
local next = next
local min = math.min
local os = os
local table = table

local S = require('syscall')
local t, c = S.t, S.c
local ffi = require('ffi')
local Waker = require('everlooping.waker').Waker
local PQueue = require('everlooping.pqueue').PQueue
local util = require('everlooping.util')
local partial = util.partial

local oldassert = assert
local function assert(c, s)
  return oldassert(c, tostring(s)) -- annoyingly, assert does not call tostring!
end

--debugging stuff
local debug = debug
local string_sub = string.sub
local string_lower  = string.lower
local string_format = string.format
local debug_getinfo = debug.getinfo
local os_date       = os.date
local io            = io
local logging = require('logging')
local logger = logging.new(function(self, level, message)
  local date = os_date("%Y-%m-%d %H:%M:%S")
  local frame = debug_getinfo(3)
  local s = string_format('[%s] [%s] [%s:%d] %s\n', string_sub(date, 6), level, frame.short_src, frame.currentline, message)
  io.stderr:write(s)
  return true
end)
logger:setLevel('DEBUG')
local print = function(...)
  logger:info(...)
end

module('everlooping.ioloop')

IOLoop = {}
local singleton
local MAX_EVENTS = 1024
local epoll_events = t.epoll_events(MAX_EVENTS)

local function getfd(fd)
  if type(fd) == "number" or ffi.istype(t.int, fd) then return fd end
  return fd:getfd()
end

function IOLoop:new(opts)
  IOLoop._initialized = true
  opts = opts or {}
  local o = {}
  o.time = opts.time or util.time
  o._handers = {}
  o._fds = {}
  o._epoll_fd = assert(S.epoll_create())
  o._stopped = false
  o._callbacks = {}
  o._timeouts = PQueue()
  o._sig_handlers = {}
  o._sigfd = -1

  self.__index = self
  setmetatable(o, self)
  o._waker = Waker:new()
  o:add_handler(o._waker:fileno(), function()
    o._waker:consume()
  end, 'in')
  return o
end

function IOLoop:add_handler(fd, handler, events)
  local ifd = getfd(fd)
  self._handers[ifd] = handler
  self._fds[ifd] = fd
  assert(self._epoll_fd:epoll_ctl('add', fd, events))
end

function IOLoop:update_handler(fd, events)
  assert(self._epoll_fd:epoll_ctl('mod', fd, events))
end

function IOLoop:remove_handler(fd)
  local ifd = getfd(fd)
  assert(self._epoll_fd:epoll_ctl('del', fd, 0))
  self._fds[ifd] = nil
  self._handers[ifd] = nil
  self:_may_auto_stop()
end

function IOLoop:_on_signal()
  local sig = t.signalfd_siginfo()
  S.read(self._sigfd, sig, 128)
  self._sig_handlers[sig.signo](sig)
end

function IOLoop:add_signal_handler(sig, handler)
  --return nil, err on error
  local signo = c.SIG[sig]
  if not signo then
    return nil, 'bad signal name'
  end
  self._sig_handlers[signo] = handler
  local sigset = assert(S.sigprocmask('block', sig))
  sigset:add(signo)
  local fd = assert(S.signalfd(sigset, 'nonblock', self._sigfd))
  fd:nogc()
  self._sigfd = getfd(fd)
  if not self._fds[self._sigfd] then
    self:add_handler(self._sigfd, partial(self._on_signal, self), 'in')
  end
  return true
end

function IOLoop:remove_signal_handler(sig)
  --return nil, err on error
  local signo = c.SIG[sig]
  if not signo then
    return nil, 'bad signal name'
  end
  if self._sigfd < 0 then
    return nil, 'nothing to remove'
  end
  self._sig_handlers[signo] = nil
  local sigset = assert(S.sigprocmask('unblock', sig))
  sigset:del(signo)
  if sigset.isemptyset then
    self:_close_sigfd()
  else
    local fd = assert(S.signalfd(sigset, 'nonblock', self._sigfd))
    fd:nogc()
    self._sigfd = getfd(fd)
  end
  return true
end

function IOLoop:_close_sigfd()
  self:remove_handler(self._sigfd)
  S.close(self._sigfd)
  self._sigfd = -1
end

function IOLoop:_may_auto_stop()
  if #self._timeouts == 0 then
    local nfds = util.table_length(self._fds)
    if nfds == 1 or (nfds == 2 and self._sigfd >= 0) then
      self:add_callback(function()
        self:stop()
      end)
    end
  end
end

function IOLoop:add_callback(callback)
  table.insert(self._callbacks, callback)
  self._waker:wake()
end

function IOLoop:add_timeout(deadline, callback)
  local timeout = {callback=callback}
  return self._timeouts:push(deadline, timeout)
  -- return timeout
end

function IOLoop:remove_timeout(timeout)
  -- timeout.callback = nil
  self._timeouts:remove(timeout)
end

function IOLoop:start()
  if self._stopped then
    self._stopped = false
    return
  end

  while not self._stopped do
    local poll_timeout = 3600000
    local callbacks = self._callbacks
    self._callbacks = {}
    for _, callback in ipairs(callbacks) do
      callback()
    end

    if #self._timeouts > 0 then
      local now = self.time()
      local to = self._timeouts
      while #to > 0 do
        if to[1][2].callback == nil then --cancelled
          to:pop()
        elseif to[1][1] <= now then
          local timeout = to:pop()[2]
          timeout.callback()
        else
          local ms = (to[1][1] - now) * 1000
          poll_timeout = min(ms, poll_timeout)
          break
        end
      end
      self:_may_auto_stop()
    end

    if #self._callbacks > 0 then
      poll_timeout = 0
    end

    local events, err = self._epoll_fd:epoll_wait(events, MAX_EVENTS, poll_timeout)
    if events == nil then
      if err.INTR then
        events = {} -- continue to next loop
      else
        error(err)
      end
    end

    for i = 1, #events do
      local ev = events[i]
      self._handers[ev.fd](self._fds[ev.fd], ev)
    end
  end
end

function IOLoop:stop()
  self._stopped = true
  self._waker:wake()
end

function IOLoop:close()
  if self._sigfd >= 0 then
    self:_close_sigfd()
  end
  self:remove_handler(self._waker:fileno())
  self._waker:close()
  self._epoll_fd:close()
end

function defaultIOLoop()
  if singleton == nil then
    singleton = IOLoop:new()
  end
  return singleton
end
