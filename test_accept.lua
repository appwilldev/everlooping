#!/usr/bin/env luajit

local S = require "syscall"
local ffi = require "ffi"
local t, c = S.t, S.c

local oldassert = assert
function assert(c, s)
  return oldassert(c, tostring(s)) -- annoyingly, assert does not call tostring!
end

local util = require('everlooping.util')
local ioloop = require('everlooping.ioloop').defaultIOLoop
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
  stream:write('Hi there! I\'m '.. S.getpid() ..'\n', start_read)
  stream:set_close_callback(function()
    print('Peer closed the connection!')
  end)
end

local s = util.bind_socket(8001)
util.add_accept_handler(s, on_accept)
local s = util.bind_socket(8001, nil, 'inet6')
util.add_accept_handler(s, on_accept)

-- S.fork()
ioloop():start()
