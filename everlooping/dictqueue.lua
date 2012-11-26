local setmetatable = setmetatable

--debugging stuff
local _tostring = require('logging').tostring
local print = function(...)
  print(_tostring(...))
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

function dictqueueT:popleft()
  if self._stop > self._start then
    local k = self._data[self._start]
    self._data[self._start] = nil
    self._start = self._start + 1
    if self._start == MAX_INDEX then
      self._start = 0
    end
    local d = self._data[k]
    self._data[k] = nil
    return d
  else
    return nil
  end
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
  self._data[d[1]] = nil
  self._data[d[1]] = self._data[self._start]
  self._start = self._start + 1
  if self._start == MAX_INDEX then
    self._start = 0
  end
  if not isMoveOut and self._deleter then
    self._deleter(d[2])
  end
end
