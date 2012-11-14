local setmetatable = setmetatable
local t_insert = table.insert

module('everlooping.deque')

local dequeT = {}
dequeT.__index = dequeT

--FIXME when the index goes too large...
function deque()
  local o = {}
  o._start = 1
  o._stop = 0
  setmetatable(o, dequeT)
  return o
end

function dequeT:popleft()
  if self._stop >= self._start then
    local d = self[self._start]
    self[self._start] = nil
    self._start = self._start + 1
    return d
  else
    return nil
  end
end

function dequeT:appendleft(d)
  self._start = self._start - 1
  self[self._start] = d
end

function dequeT:append(d)
  self._stop = self._stop + 1
  self[self._stop] = d
end

function dequeT:length()
  return self._stop - self._start + 1
end

function dequeT:leftmost()
  return self[self._start]
end
