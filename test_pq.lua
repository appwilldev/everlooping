#!/usr/bin/env luajit

local _tostring = require('logging').tostring
local print = function(...)
  print(_tostring(...))
end

local PQueue = require('everlooping.pqueue').PQueue

local q = PQueue()
for i=10, 1, -1 do q:push(i, 'a' .. i) end
for i=11, 15 do q:push(i, 'a' .. i) end
q:push(-2, 'lksajdf')
q:push(45, 98)

while true do
  local d = q:pop()
  if not d then
    break
  end
  print(d)
end
