#!/usr/bin/env luajit

local assert = assert
local setmetatable = setmetatable
local type = type
local os = os

local S = require('syscall')
local t, c = S.t, S.c
local ffi = require('ffi')

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
  opts = opts or {}
  local o = {}
  o.time = opts.time or os.time
  o._handers = {}
  o._fds = {}
  o._epoll_fd = assert(S.epoll_create())
  o._stopped = false

  self.__index = self
  setmetatable(o, self)
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
  assert(self._epoll_fd:epoll_ctl('del', fd, 0))
end

function IOLoop:start()
  if self._stopped then
    self._stopped = false
    return
  end

  while not self._stopped do
    local poll_timeout = 3600000
    local events, err = self._epoll_fd:epoll_wait(events, MAX_EVENTS, poll_timeout)
    if events == nil and err ~= 'Interrupted system call' then
      events = {} -- continue to next loop
    end

    for i = 1, #events do
      local ev = events[i]
      self._handers[ev.fd](self._fds[ev.fd], ev)
    end
  end
end

function IOLoop:stop()
  self._stopped = true
end

function IOLoop:close()
  self._epoll_fd:close()
end

function defaultIOLoop()
  if singleton == nil then
    singleton = IOLoop:new()
  end
  return singleton
end
