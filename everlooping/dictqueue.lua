local setmetatable = setmetatable
local util = require('everlooping.util')
local table_remove = table.remove
local table_insert = table.insert

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

-- Functions:
--  1. quick length calculation
--  2. map key to multi-value
--  3. remove out per LRU
--
-- Data Structure:
--
-- one index corresponding to one value
-- Part 1: index to key which may be the same
-- Part 2: key to value
--   {key = items}
--   where items is an array of {index, value}
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
  print('deleting from removeleft')
  self:delete(nil, nil, nil, true)
end

function dictqueueT:length()
  local l = self._stop - self._start
  if l < 0 then
    l = l + MAX_INDEX
  end
  return l
end

function dictqueueT:getout(key)
  local d = self._data[key]
  if d then
    local ret = d[1][2]
    self:delete(key, ret, true)
    return ret
  end
end

function dictqueueT:set(key, val)
  local d = self._data[key]
  if d then
    if util.table_index(d, val, function(a, v)
        return a[2] == v
      end) then
      -- already there, do nothing
      return
    else
      -- same key, different connection
      table_insert(d, {self._stop, val})
    end
  else
    -- new key
    self._data[key] = {{self._stop, val}}
  end
  -- advance the end index
  self._data[self._stop] = key
  self._stop = self._stop + 1
  if self._stop == MAX_INDEX then
    self._stop = 0
  end
end

function dictqueueT:delete(key, value, isMoveOut, removeleft)
  local data = self._data
  local start = self._start
  if removeleft then
    local index = start
    -- store the key
    local k = data[index]
    -- invalid leftmost index will be done at the end
    -- remove the value of the index
    local d = data[key]
    local pos = util.table_index(d, index, function(a, b) return a[1] == b end)
    local item = table_remove(d, pos)
    -- trash the value
    if self._deleter then
      self._deleter(item[2])
    end
  else
    -- remove the value in key
    local d = data[key]
    local pos = util.table_index(d, value, function(a, b) return a[2] == b end)
    local item = table_remove(d, pos)
    -- trash the value if should
    if not isMoveOut and self._deleter then
      self._deleter(item[2])
    end
    -- in order to invalid the index...
    local index = item[1]
    -- ...we move the start index here
    -- ...only when index is not already start index
    if index ~= start then
      local start_key = data[start]
      data[index] = start_key
      local start_d = data[start_key]
      pos = util.table_index(start_d, start, function(a, b) return a[1] == b end)
      start_d[pos][1] = index
    end
    data[start] = nil
    -- now check if there's no value for key
    if #d == 0 then
      -- if so, remove the key
      data[key] = nil
    end
  end

  -- advance the start index
  self._start = start + 1
  if self._start == MAX_INDEX then
    self._start = 0
  end
end
