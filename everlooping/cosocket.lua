#!/usr/bin/env luajit

local assert = assert
local setmetatable = setmetatable
local error = error
local tonumber = tonumber
local table = table
local coroutine = coroutine
local string = string

local S = require('syscall')
local t, c = S.t, S.c
local util = require('everlooping.util')
local partial = util.partial
local IOStream = require('everlooping.iostream').IOStream
local defaultIOLoop = require('everlooping.ioloop').defaultIOLoop

-- for debug
local print = print

module('everlooping.cosocket')

tcpT = {}
tcpT.__index = tcpT

-- defer possible defaultIOLoop creation
local ioloop

function tcp()
  local o = {}
  o._sock = assert(S.socket("inet", "stream, nonblock"))
  o.stream = IOStream(o._sock)
  setmetatable(o, tcpT)
  return o
end

local function _resume_me(co, stream, ...)
  local ok, err = coroutine.resume(co, ...)
  if not ok then
    print('Error!', err)
    print('failed coroutine is:', co)
  end
end

local function _timed_out(co, stream)
  stream:close()
  local ok, err = coroutine.resume(co, false, 'Timeout')
  if not ok then
    print('Error!', err)
    print('failed coroutine is:', co)
  end
end

function sleep(secs)
  if not ioloop then
    ioloop = defaultIOLoop()
  end
  ioloop:add_timeout(ioloop.time() + secs, partial(_resume_me, coroutine.running()))
  return coroutine.yield()
end

function tcpT:_adjust_timeout()
  if self._timeoutlen == nil then
    return
  end
  if not ioloop then
    ioloop = defaultIOLoop()
  end
  self._timeout = ioloop:add_timeout(
    ioloop.time() + self._timeoutlen, partial(_timed_out, coroutine.running(), self.stream)
  )
end

function tcpT:_not_timedout()
  if self._timeout then
    ioloop:remove_timeout(self._timeout)
    self._timeout = nil
  end
end

function tcpT:connect(addr, port)
  self:_adjust_timeout()
  local ip = util.simpleDNSQuery(addr)
  if not ip then
    self:_not_timedout()
    return nil, 'bad address'
  end
  local sa = t.sockaddr_in(port, ip)
  self.stream:connect(sa, partial(_resume_me, coroutine.running()))
  local ok, err = coroutine.yield()
  self:_not_timedout()
  return ok, err
end

function tcpT:receive(pattern)
  self:_adjust_timeout()
  local co = coroutine.running()
  self.stream:set_close_callback(function()
    _resume_me(co, self.stream, nil, 'closed')
  end)

  local n = tonumber(pattern)
  local ret, err
  if n then
    self.stream:read_bytes(n, partial(_resume_me, coroutine.running()))
    ret, err = coroutine.yield()
  else
    if pattern == '*l' or pattern == nil then
      self.stream:read_until('\n', partial(_resume_me, coroutine.running()))
      ret, err = coroutine.yield()
      if ret then
        ret = string.gsub(ret, '[\r\n]', '')
      end
    elseif pattern == '*a' then
      self.stream:read_until_close(partial(_resume_me, coroutine.running()))
      ret, err = coroutine.yield()
    else
      error('bad format for tcp:receive')
    end
  end
  self.stream:set_close_callback(nil)
  self:_not_timedout()
  return ret, err
end

function tcpT:settimeout(ms)
  self._timeoutlen = ms / 1000
end

function tcpT:send(data)
  self:_adjust_timeout()
  self.stream:write(data, partial(_resume_me, coroutine.running()))
  local ok, err = coroutine.yield()
  self:_not_timedout()
  -- ok will always be nil
  if err then
    return ok, err
  else
    return #data
  end
end

function tcpT:close()
  self.stream:close()
end

function register(func)
  local co = coroutine.create(func)
  local ok, err = coroutine.resume(co)
  if not ok then
    print('Error running cosocket coroutine:', err)
  end
end
