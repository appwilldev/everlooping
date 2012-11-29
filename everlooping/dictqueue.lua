local setmetatable = setmetatable

--debugging stuff
local _tostring = require('logging').tostring
local print = function(...)
  print(_tostring{...})
end

module('everlooping.dictqueue')

local dictqueueT = {}
dictqueueT.__index = dictqueueT

-- big enough
local MAX_INDEX = 1048576

function dictqueue(deleter)
  local o = {}
  o._start = 0
  o._stop = 0
  o._data = {}
  o._deleter = deleter
  setmetatable(o, dictqueueT)
  return o
end

function dictqueueT:removeleft()
  local k = self._data[self._start]
  self:delete(k)
end

function dictqueueT:length()
  local l = self._stop - self._start
  if l < 0 then
    l = l + MAX_INDEX
  end
  return l
end

function dictqueueT:get(key)
  local d = self._data[key]
  if d then
    return d[2]
  else
    return nil
  end
end

function dictqueueT:set(key, val)
  local d = self._data[key]
  if d then
    -- already there, do nothing
    return
  end
  self._data[self._stop] = key
  self._data[key] = {self._stop, val}
  self._stop = self._stop + 1
  if self._stop == MAX_INDEX then
    self._stop = 0
  end
end

function dictqueueT:delete(key, isMoveOut)
  local d = self._data[key]
  self._data[key] = nil
  local other_key = self._data[self._start]
  self._data[d[1]] = self._data[self._start]
  self._data[self._start] = nil
  if self._data[other_key] then
    self._data[other_key][1] = d[1]
  end

  self._start = self._start + 1
  if self._start == MAX_INDEX then
    self._start = 0
  end
  if not isMoveOut and self._deleter then
    self._deleter(d[2])
  end
end
