#!/usr/bin/env luajit

local error = error
local tonumber = tonumber
local tostring = tostring
local next = next
local print = print
local string = string
local os = os

local S = require "syscall"
local t, c = S.t, S.c
local ioloop = require('everlooping.ioloop')
local defaultIOLoop = ioloop.defaultIOLoop

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

function fork_processes(n, max_restarts)
  if not max_restarts then
    max_restarts = 100
  end
  if ioloop.IOLoop._initialized then
    error('cannot fork after IOLoop intialized.')
  end
  local num = tonumber(n)
  if not num or num < 1 then
    error('cannot fork ' .. tostring(n) .. 'processes')
  end
  local children = {}
  local function start_child(i)
    local pid = S.fork()
    if pid == 0 then
      _task_id = i
      return i
    elseif pid > 0 then
      children[pid] = i
    else
      error('fork failed with ' .. pid)
    end
  end

  for i=1, n do
    local id = start_child(i)
    if id then
      return id
    end
  end

  local restarts = 0
  while next(children) do
    local wres = S.wait()
    local id = children[wres.pid]
    local continue = false
    if wres.WIFSIGNALED then
      print(string.format('WARNING: child %d (pid %d) killed by signal %d, restarting', id, wres.pid, wres.WTERMSIG))
    elseif wres.WIFEXITED then
      print(string.format('WARNING: child %d (pid %d) exited with status %d, restarting', id, wres.pid, wres.EXITSTATUS))
    else
      print(string.format('INFO: child %d (pid %d) exited normally.', id, wres.pid))
      continue = true
    end

    if not continue then
      restarts = restarts + 1
      if restarts > max_restarts then
        error('too many child restarts, giving up')
      end
      local new_id = start_child(id)
      if new_id then
        return new_id
      end
    end
  end

  os.exit()
end

