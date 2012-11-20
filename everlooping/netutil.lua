#!/usr/bin/env luajit

local defaultIOLoop = require('everlooping.ioloop').defaultIOLoop

module('everlooping.netutil')

function add_accept_handler(sock, callback, ioloop)
  ioloop = ioloop or defaultIOLoop()
  function accept_handler(fd, events)
    while true do
      local conn, err = sock:accept()
      if not conn then
        if err.AGAIN or err.WOULDBLOCK then
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

