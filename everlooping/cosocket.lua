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
local IOStream = require('everlooping.iostream').IOStream

-- for debug
local print = print

module('everlooping.cosocket')

local _fd2coroutine = {}

local tcpT = {}
tcpT.__index = tcpT

function tcp()
  local o = {}
  o._sock = assert(S.socket("inet", "stream, nonblock"))
  coroutine.yield(o._sock)
  o.stream = IOStream(o._sock)
  setmetatable(o, tcpT)
  return o
end

local function _resume_me(stream, ...)
  local co = _fd2coroutine[stream:getfd()]
  if not co then
    error('coroutine for fd ' .. stream:getfd() .. 'not found!')
  end
  coroutine.resume(co, ...)
end

function tcpT:connect(addr, port)
  local ip = util.simpleDNSQuery(addr)
  if not ip then
    return nil
  end
  local sa = t.sockaddr_in(port, ip)
  self.stream:connect(sa, _resume_me)
  coroutine.yield()
end

function tcpT:receive(pattern)
  self.stream:set_close_callback(function()
    _resume_me(self.stream, nil, 'closed')
  end)

  local n = tonumber(pattern)
  local ret, err
  if n then
    self.stream:read_bytes(n, _resume_me)
    ret, err = coroutine.yield()
  else
    if pattern == '*l' then
      self.stream:read_until('\n', _resume_me)
      ret, err = coroutine.yield()
      if ret then
        ret = string.gsub(ret, '[\r\n]', '')
      end
    elseif pattern == '*a' then
      error('NotImplementedError: read_until_close')
    else
      error('bad format for tcp:receive')
    end
  end
  self.stream:set_close_callback(nil)
  return ret, err
end

function tcpT:send(data)
  self.stream:write(data, _resume_me)
  coroutine.yield()
  return #data
end

function tcpT:close()
  self.stream:close()
end

function register(func)
  local co = coroutine.create(func)
  local ok, fd = coroutine.resume(co)
  if ok then
    _fd2coroutine[fd] = co
    ok, fd = coroutine.resume(co)
  end
  if not ok then
    print('Error!', fd)
  end
end
