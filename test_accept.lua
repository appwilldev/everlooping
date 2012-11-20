#!/usr/bin/env luajit

local S = require "syscall"
local ffi = require "ffi"
local t, c = S.t, S.c

local oldassert = assert
function assert(c, s)
  return oldassert(c, tostring(s)) -- annoyingly, assert does not call tostring!
end

local util = require('everlooping.util')
local netutil = require('everlooping.netutil')
local ioloop = require('everlooping.ioloop').defaultIOLoop
local IOStream = require('everlooping.iostream').IOStream

function printReceived(stream, data)
  print(data)
  if string.sub(data, #data, #data) == '\n' then
    stream:write('Hi again\n')
  end
  stream:read_until('\n', printReceived)
end

function start_read(stream)
  stream:read_bytes(16, printReceived)
end

function on_accept(conn)
  print(string.format('%s:%d connected!', conn.addr.addr, conn.addr.port))
  local stream = IOStream(conn.fd)
  stream:write('Hi there! I\'m '.. S.getpid() ..'\n', start_read)
  stream:set_close_callback(function()
    print('Connection closed.')
  end)
end

function send_udp(stream)
  stream:write('Hi UDP!\n')
  stream:read_until('\n', recv_udp)
end

function recv_udp(stream, data)
  print('UDP received: ' .. data)
  stream:close()
end

local s = util.bind_socket(8001)
local s2 = util.bind_socket(8001, nil, 'inet6')
local s3 = assert(S.socket("inet", "dgram, nonblock"))
local s3 = IOStream(s3)
local sa = assert(t.sockaddr_in(8001, "127.0.0.1"))
s3:connect(sa, send_udp)

-- S.fork()
netutil.add_accept_handler(s2, on_accept)
netutil.add_accept_handler(s, on_accept)
ioloop():start()
