local setmetatable = setmetatable
local insert = table.insert
local floor = math.floor

module('everlooping.pqueue')

local PQueueT = {}
PQueueT.__index = PQueueT

function PQueue()
  local o = {}

  setmetatable(o, PQueueT)
  return o
end

function PQueueT:push(value, data)
  local d = {value, data}
  insert(self, d)
  self:_heapifyup(#self)
end

function PQueueT:_heapifyup(n)
  if n == 1 then
    return
  end
  local data = self[n]
  local parent_pos = floor(n/2)
  local parent = self[parent_pos]
  if data[1] < parent[1] then
    self[n] = parent
    self[parent_pos] = data
    self:_heapifyup(parent_pos)
  end
end

function PQueueT:pop()
  local data = self[1]
  if not data then
    return nil
  end
  local newroot = self[#self]
  self[1] = newroot
  self[#self] = nil
  self:_heapifydown(1)
  return data
end

function PQueueT:_heapifydown(n)
  local data = self[n]
  local lchild_pos = 2 * n
  local rchild_pos = 2 * n + 1
  local lchild = self[lchild_pos]
  if not lchild then
    return
  end
  local rchild = self[rchild_pos]
  local should_swapleft
  if data[1] > lchild[1] then
    should_swapleft = true
  end
  if rchild and data[1] > rchild[1] then
    if (should_swapleft and lchild[1] > rchild[1]) or not should_swapleft then
      self[rchild_pos] = data
      self[n] = rchild
      self:_heapifydown(rchild_pos)
      should_swapleft = false
    end
  end
  if should_swapleft then
    self[lchild_pos] = data
    self[n] = lchild
    self:_heapifydown(lchild_pos)
  end
end
