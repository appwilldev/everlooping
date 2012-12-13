#!/usr/bin/env luajit

local S = require "syscall"

--debugging stuff
local string_sub = string.sub
local string_lower  = string.lower
local string_format = string.format
local debug_getinfo = debug.getinfo
local os_date       = os.date
local io            = io
local logging = require('logging')
local logger = logging.new(function(self, level, message)
  local date = os_date("%Y-%m-%d %H:%M:%S")
  local frame = debug_getinfo(3)
  local s = string_format('[%s] [%s] [%s:%d] %s\n', string_sub(date, 6), level, frame.short_src, frame.currentline, message)
  io.stderr:write(s)
  return true
end)
logger:setLevel('DEBUG')
local print = function(...)
  logger:info(...)
end


local cosocket = require('everlooping.cosocket')
local ioloop = require('everlooping.ioloop')
local netutil = require('everlooping.netutil')

local s = cosocket.tcp()
assert(s:bind('*', 9009))
assert(s:listen(128))

netutil.fork_processes(4, 10)

s:accept(function(s, a)
  local mypid = S.getpid()
  print('client %s:%d connected.', a[1], a[2])
  while true do
    local l, err = s:receive('*l')
    if l then
      print(l)
      if l == 'quit' then
        break
      end
      s:send('[' .. mypid .. '] ' .. l .. '\n')
    else
      print(l, err)
      break
    end
  end
  s:close()
  print('client disconnected.')
end)

print('starting...')
ioloop.defaultIOLoop():start()
