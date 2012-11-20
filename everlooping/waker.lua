#!/usr/bin/env luajit

local setmetatable = setmetatable
local assert = assert

local S = require('syscall')
local t, c = S.t, S.c
local bufsize = 16
local buffer = t.buffer(bufsize)

module('everlooping.waker')

Waker = {}

function Waker:new()
  local o = {}
  o.pipe = assert(S.pipe("nonblock"))
  self.__index = self
  setmetatable(o, self)
  return o
end

function Waker:fileno()
  return self.pipe[1]
end

function Waker:consume()
  while true do
    local data, err = self.pipe:read(buf, bufsize)
    if not data then
      break
    end
  end
end

function Waker:wake()
  self.pipe:write('x')
end

function Waker:close()
  self.pipe:close()
end
