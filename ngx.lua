#!/usr/bin/env luajit

local setmetatable = setmetatable
local type = type
local ipairs = ipairs
local _print = print
local os = os
local cosocket = require('everlooping.tcppool')

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
say = _print
print = function(t)
  for _, i in ipairs(t) do
    if type(i) == 'table' then
      print(i)
    else
      _print(i)
    end
  end
end
eof = function() _print('EOF') end
exit = function(n) _print('Exit with ' .. n) end
