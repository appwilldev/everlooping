#!/usr/bin/env luajit

local assert = assert

local S = require('syscall')
local t, c = S.t, S.c
local ffi = require('ffi')
local defaultIOLoop = require('everlooping.ioloop').defaultIOLoop

module('everlooping.util')

function add_accept_handler(sock, callback, ioloop)
  ioloop = ioloop or defaultIOLoop()
  function accept_handler(fd, events)
    while true do
      local conn, err = sock:accept()
      if not conn then
        if err.EAGAIN or err.EWOULDBLOCK then
          return
        end
        error(err)
      end
      callback(conn)
    end
  end
  ioloop:add_handler(sock, accept_handler, "in")
end

function fork_processes(n)
  if IOLoop._initialized then
    error('cannot fork after IOLoop intialized.')
  end
  --TODO fork and manage child processes
end

function bind_socket(port, address, family, backlog)
  --family is inet or inet6
  backlog = backlog or 128
  family = family or 'inet'
  local wildaddr
  if family == 'inet' then
    wildaddr = '0.0.0.0'
  else
    wildaddr = '::'
  end
  address = address or wildaddr
  local s = assert(S.socket(family, "stream, nonblock"))
  local sa
  if family == 'inet' then
    sa = assert(t.sockaddr_in(port, address))
  else
    sa = assert(t.sockaddr_in6(port, address))
    --setsockopt(IPPROTO_IPV6, IPV6_V6ONLY, 1)
    s:setsockopt(41, 26, true)
  end
  s:setsockopt("socket", "reuseaddr", true)
  assert(s:bind(sa))
  s:listen(backlog)
  return s
end
