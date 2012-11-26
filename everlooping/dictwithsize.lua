local setmetatable = setmetatable

--debugging stuff
local _tostring = require('logging').tostring
local print = function(...)
  print(_tostring(...))
end

module('everlooping.dictwithsize')

local dictwithsizeT = {}
dictwithsizeT.__index = dictwithsizeT

function dictwithsize()
  local o = {}
  o._length = 0
  o._data = {}
  setmetatable(o, dictwithsizeT)
  return o
end

function dictwithsizeT:set(i, v)
  local t = self._data
  if t[i] ~= nil then
    if v == nil then
      self._length = self._length - 1
    end
  else
    if v ~= nil then
      self._length = self._length + 1
    end
  end
  t[i] = v
end

function dictwithsizeT:get(i)
  return self._data[i]
end

function dictwithsizeT:length()
  return self._length
end
