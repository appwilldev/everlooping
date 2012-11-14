#!/usr/bin/env luajit

local S = require "syscall"
local ffi = require "ffi"
local t, c = S.t, S.c

local oldassert = assert
function assert(c, s)
  return oldassert(c, tostring(s)) -- annoyingly, assert does not call tostring!
end

function printReceived(stream, data)
  print(data)
  stream:close()
end

function start_read(stream)
  stream:read_bytes(16, printReceived)
end

function connected(stream)
  print('connected')
  stream:write('Hi there!\n', start_read)
end

local ioloop = require('everlooping.ioloop').defaultIOLoop()
local IOStream = require('everlooping.iostream').IOStream
local s = assert(S.socket("inet", "stream, nonblock"))
s = IOStream(s)
local sa = assert(t.sockaddr_in(8000, "127.0.0.1"))
s:connect(sa, connected)

local s2 = assert(S.socket("inet", "stream, nonblock"))
s2 = IOStream(s2)
local sa2 = assert(t.sockaddr_in(8001, "127.0.0.1"))
s2:connect(sa2, connected)

ioloop:start()
