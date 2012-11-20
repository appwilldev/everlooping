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

-- for debug
local print = print

module('everlooping.cosocket')

local tcpT = {}
tcpT.__index = tcpT

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

function tcpT:connect(addr, port)
  local ip = util.simpleDNSQuery(addr)
  if not ip then
    return nil, 'bad address'
  end
  local sa = t.sockaddr_in(port, ip)
  self.stream:connect(sa, partial(_resume_me, coroutine.running()))
  return coroutine.yield()
end

function tcpT:receive(pattern)
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
      error('NotImplementedError: read_until_close')
    else
      error('bad format for tcp:receive')
    end
  end
  self.stream:set_close_callback(nil)
  return ret, err
end

function tcpT:settimeout()
  print('NotImplemented: settimeout')
end

function tcpT:send(data)
  self.stream:write(data, partial(_resume_me, coroutine.running()))
  coroutine.yield()
  return #data
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
