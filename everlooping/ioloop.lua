#!/usr/bin/env luajit

local assert = assert
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

--debugging stuff
local string_sub = string.sub
local string_lower  = string.lower
local string_format = string.format
local debug_getinfo = debug.getinfo
local os_date       = os.date
local io            = io
local logging = require('logging')
local logger = logging.new(function(self, level, message)
  local date = os_date("%Y-%m-%d %H:%M:%S")
  local frame = debug_getinfo(4)
  local s = string_format('[%s] [%s] [%s:%d] %s\n', string_sub(date, 6), level, frame.short_src, frame.currentline, message)
  io.stderr:write(s)
  return true
end)
logger:setLevel('DEBUG')
local print = function(...)
  logger:info(...)
end

module('everlooping.ioloop')

local IOLoop = {}
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
  o.time = opts.time or os.time
  o._handers = {}
  o._fds = {}
  o._epoll_fd = assert(S.epoll_create())
  o._stopped = false
  o._callbacks = {}
  o._timeouts = PQueue()

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

function IOLoop:_may_auto_stop()
  if util.table_length(self._fds) == 1 and #self._timeouts == 0 then
    self:add_callback(function()
      self:stop()
    end)
  end
end

function IOLoop:add_callback(callback)
  table.insert(self._callbacks, callback)
  self._waker:wake()
end

function IOLoop:add_timeout(deadline, callback)
  local timeout = {callback=callback}
  self._timeouts:push(deadline, timeout)
  return timeout
end

function IOLoop:remove_timeout(timeout)
  timeout.callback = nil
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
          local seconds = to[1][1] - now
          poll_timeout = min(seconds, poll_timeout)
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
