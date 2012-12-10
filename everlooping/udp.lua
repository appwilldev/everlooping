#!/usr/bin/env luajit

local setmetatable = setmetatable
local type = type
local tostring = tostring
local print = print
local coroutine = coroutine

local S = require('syscall')
local t, c = S.t, S.c
local defaultIOLoop = require('everlooping.ioloop').defaultIOLoop
local util = require('everlooping.util')
local partial = util.partial

local oldassert = assert
local function assert(c, s)
  return oldassert(c, tostring(s)) -- annoyingly, assert does not call tostring!
end

module(...)

udpT = {}
udpT.__index = udpT

local ioloop

function udp(sock)
  local o = {}
  o._sock = sock or assert(S.socket("inet", "dgram, nonblock"))
  setmetatable(o, udpT)
  return o
end

local function _timed_out(co)
  local ok, err = coroutine.resume(co, false, 'Timeout')
  if not ok then
    print('Error!', err)
    print('failed coroutine is:', co)
  end
end

local function _resume_me(co, ...)
  local ok, err = coroutine.resume(co, ...)
  if not ok then
    print('Error!', err)
    print('failed coroutine is:', co)
  end
end

function udpT:settimeout(ms)
  self._timeout = ms / 1000.0
end

function udpT:setpeername(host, port)
  -- if an IP is given, simpleDNSQuery (gethostbyname) will simply copy it
  local ip = util.simpleDNSQuery(host)
  if not ip then
    return nil, 'bad address'
  end
  local sa = t.sockaddr_in(port, ip)
  local ok, err = self._sock:connect(sa)
  if ok then
    return 1
  else
    return nil, tostring(err)
  end
end

function udpT:send(data)
  if type(data) == 'table' then
    data = util.flatten_table(data)
  end
  local ok, err = self._sock:send(data)
  if ok then
    return 1
  else
    return nil, tostring(err)
  end
end

function udpT:receive(size)
  size = size or 8192
  if size > 8192 then
    size = 8192
  end
  if not ioloop then
    ioloop = defaultIOLoop()
  end
  local timeout
  if self._timeout then
    timeout = ioloop:add_timeout(ioloop.time() + self._timeout, partial(_timed_out, coroutine.running()))
  end
  ioloop:add_handler(self._sock, partial(_resume_me, coroutine.running()), 'in')
  local ok, err = coroutine.yield()
  ioloop:remove_timeout(timeout)
  ioloop:remove_handler(self._sock)
  if not ok then
    return nil, err
  end
  -- local buf = t.buffer(size)
  local ok, err = self._sock:read(buf, size)
  if ok then
    return ok
  else
    return nil, tostring(err)
  end
end

function udpT:close()
  self._sock:close()
end
