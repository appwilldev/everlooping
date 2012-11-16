#!/usr/bin/env luajit

local S = require "syscall"
local ffi = require "ffi"
local t, c = S.t, S.c

local oldassert = assert
function assert(c, s)
  return oldassert(c, tostring(s)) -- annoyingly, assert does not call tostring!
end

local add_accept_handler = require('everlooping.ioloop').add_accept_handler
local ioloop = require('everlooping.ioloop').defaultIOLoop()
local IOStream = require('everlooping.iostream').IOStream

function printReceived(stream, data)
  print(data)
  if string.sub(data, #data, #data) == '\n' then
    stream:close()
  else
    stream:read_until('\n', printReceived)
  end
end

function start_read(stream)
  stream:read_bytes(16, printReceived)
end

function on_accept(conn)
  print(string.format('%s:%d connected!', conn.addr.addr, conn.addr.port))
  local stream = IOStream(conn.fd)
  stream:write('Hi there!\n', start_read)
end

local s = assert(S.socket("inet", "stream, nonblock"))
s:setsockopt("socket", "reuseaddr", true)
local sa = assert(t.sockaddr_in(8001, "0.0.0.0"))
s:bind(sa)
s:listen(32)
add_accept_handler(s, on_accept)

ioloop:start()
