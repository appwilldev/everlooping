local setmetatable = setmetatable

module('everlooping.pqueue')

function PQueue:new()
  local o = {}

  setmetatable(o, self)
  self.__index = self
  return o
end

