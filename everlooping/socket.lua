local assert = assert
local type = type
local coroutine = coroutine
local table = table
local string = string
local error = error

local S = require('syscall')
local t, c = S.t, S.c
local def_ioloop = require('everlooping.ioloop').defaultIOLoop

module('everlooping.socket')

local socket = {}
local bufsize = 4096
local buffer = t.buffer(bufsize)

function tcp(ioloop)
  local o = {}
  o._sock = assert(S.socket("inet", "stream, nonblock"))
  o._ioloop = ioloop or def_ioloop()
  self.__index = socket
  setmetatable(o, socket)
  return o
end

function socket:connect(host, port)
  local sa = assert(t.sockaddr_in(port, host))
  local s = self._sock
  s:connect(sa)
  self._ioloop:add_handler(s, _resume, "out")
  coroutine.yield(s)
end

function socket:send(data, i, j)
  if i then
    data = string.sub(data, i, j)
  end
  local total = #data
  local s = self._sock
  while #data > 0 do
    local sent, err = s:send(data)
    if not sent then
      if err == 'Interrupted system call' then
      elseif err == 'Resource temporarily unavailable' then
        self._ioloop:update_handler(s, _resume, "out")
        coroutine.yield(s)
      else
        return sent, err
      end
    end
    data = string.sub(data, sent)
  end
  return total
end

function socket:receive(pattern)
  local s = self._sock
  if type(pattern) == 'number' then
    local to_read = pattern
    while to_read > 0 do
      local data, err = s:read(buf, bufsize)
      if not data then
        if err == 'Interrupted system call' then
        elseif err == 'Resource temporarily unavailable' then
          self._ioloop:update_handler(s, _resume, "in")
          coroutine.yield(s)
        else
          return data, err
        end
      end
    end
  else
    error('TBD.')
  end
end

local _coroutines = {}
local _yielded_coroutines = {}

function register(func)
  table.insert(_coroutines, coroutine.create(func))
end

function _resume(fd, event)
  coroutine.resume(_yielded_coroutines[fd], event)
  _yielded_coroutines[fd] = nil
end

function run(ioloop)
  ioloop = ioloop or def_ioloop()
  for i=1, #_coroutines do
    local fd = coroutine.resume(_coroutines[i])
    _yielded_coroutines[fd] = _coroutines[i]
  end
  ioloop:start()
end
