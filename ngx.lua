#!/usr/bin/env luajit

local setmetatable = setmetatable
local type = type
local ipairs = ipairs
local tostring = tostring
local _print = print
local os = os
local cosocket = require('everlooping.tcppool')
local write = function(s) io.stdout:write(s) end

module('ngx')

local gsdT = {}
gsdT.__index = gsdT

function gsd()
  local o = {}
  o._data = {}
  setmetatable(o, gsdT)
  return o
end

function gsdT:get(k)
  return self._data[k]
end

function gsdT:set(k, v, expire)
  self._data[k] = v
end

function gsdT:delete(k)
  self._data[k] = nil
end

shared = setmetatable({}, {
  __index = function(t, i)
    t[i] = gsd()
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
socket = {
  tcp = cosocket.tcp,
}

time = os.time
ERR = 'ERROR'

md5 = nil
location = {
  capture = function() end,
}

sleep = cosocket.sleep
log = function(...)
  _print('LOG: ', ...)
end
print = function(t)
  if type(t) == 'table' then
    for _, i in ipairs(t) do
      if type(i) == 'table' then
        print(i)
      else
        write(i)
      end
    end
  else
    write(tostring(t))
  end
end
say = function(t)
  print(t)
  _print()
end
eof = function() _print('EOF') end
exit = function(n) _print('Exit with ' .. n) end
