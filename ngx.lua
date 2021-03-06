#!/usr/bin/env luajit

local setmetatable = setmetatable
local type = type
local ipairs = ipairs
local tostring = tostring
local require = require
local _print = print
local os = os
local cosocket = require('everlooping.tcppool')
local udp = require('everlooping.udp')
local pcre = require('everlooping.pcre')
local write = function(s) io.stdout:write(s) end
local ffi = require('ffi')
local cjson = require('cjson')

module('ngx')

re = pcre

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

function gsdT:replace(k, v, expire)
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

null = cjson.null -- They should be equal
header = {}
socket = {
  tcp = cosocket.tcp,
  udp = udp.udp,
}

time = os.time
ERR = 'ERROR'

md5 = nil
location = {
  capture = function() end,
}

sha1_bin = function(s)
  local sha1 = require('resty.sha1')
  local L = ffi.load('crypto', true)
  sha1_bin = function(s)
    local sha1ctx = sha1:new()
    sha1ctx:update(s)
    return sha1ctx:final()
  end
  return sha1_bin(s)
end

sleep = cosocket.sleep
log = function(...)
  _print('LOG: ', ...)
end
print = function(...)
  local arg = {...}
  for _, t in ipairs(arg) do
    if type(t) == 'table' then
      for _, i in ipairs(t) do
        local ty = type(i)
        if ty == 'table' then
          print(i)
        else
          write(tostring(i))
        end
      end
    else
      write(tostring(t))
    end
  end
end
say = function(...)
  print(...)
  _print()
end
eof = function() _print('EOF') end
exit = function(n) _print('Exit with ' .. n) end

everlooping = true
