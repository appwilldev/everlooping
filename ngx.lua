#!/usr/bin/env luajit

local setmetatable = setmetatable
local type = type
local ipairs = ipairs
local _print = print
local os = os
local cosocket = require('everlooping.tcppool')
local write = function(s) io.stdout:write(s) end

module('ngx')

shared = setmetatable({}, {
  __index = function(t, i)
    t[i] = {}
    return t[i]
  end
})

ctx = setmetatable({}, {
  __index = function(t, i)
    t[i] = {}
    return t[i]
  end
})

null = {}
header = {}

time = os.time
ERR = 'ERROR'

md5 = nil
location = {
  capture = nil,
}

sleep = cosocket.sleep
log = function(...)
  _print('LOG: ', ...)
end
print = function(t)
  for _, i in ipairs(t) do
    if type(i) == 'table' then
      print(i)
    else
      write(i)
    end
  end
end
say = function(t)
  print(t)
  _print()
end
eof = function() _print('EOF') end
exit = function(n) _print('Exit with ' .. n) end
