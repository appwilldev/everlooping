local assert = assert
local setmetatable = setmetatable
local table = table
local string = string
local select = select
local unpack = unpack
local ipairs = ipairs
local error = error

local bit = require('bit')
local S = require('syscall')
local t, c = S.t, S.c
local def_ioloop = require('everlooping.ioloop').defaultIOLoop
local deque = require('everlooping.deque').deque

--debugging stuff
local _tostring = require('logging').tostring
local print = function(...)
  print(_tostring(...))
end

module('everlooping.iostream')

local bufsize = 4096
local buffer = t.buffer(bufsize)
local _merge_prefix

local IOStreamT = {
  IN  = 0x001,
  OUT = 0x004,
}
IOStreamT.__index = IOStreamT

local function partial(func, ...)
  if select("#", ...) == 0 then
    return func
  end
  local args = {...}
  return function(...)
    local _args = {...}
    local real_args = {unpack(args)}
    for _, v in ipairs(_args) do
      table.insert(real_args, v)
    end
    return func(unpack(real_args))
  end
end

function IOStream(sock, ioloop)
  local o = {}
  o._sock = sock
  o._read_buffer = deque()
  o._write_buffer = deque()
  o._read_buffer_size = 0
  o.ioloop = ioloop or def_ioloop()
  setmetatable(o, IOStreamT)
  return o
end

function IOStreamT:connect(address, callback)
  self._connecting = true
  self._sock:connect(address)
  self._connect_callback = callback
  self:_add_io_state(self.OUT)
end

function IOStreamT:read_bytes(num_bytes, callback)
  self._read_callback = callback
  self._read_bytes = num_bytes
  self:_read_from_buffer()
  self:_add_io_state(self.IN)
end

function IOStreamT:write(data, callback)
  self._write_buffer:append(data)
  self._write_callback = callback
  if not self._connecting then
    self:_handle_write()
  end
end

function IOStreamT:close()
  self._sock:close()
end

function IOStreamT:_add_io_state(state)
  if self._state == nil then
    self._state = state
    self.ioloop:add_handler(self._sock, partial(self._handle_events, self), self._state)
  elseif bit.band(self._state, state) == 0 then
    self._state = bit.bor(self._state, state)
    self.ioloop:update_handler(self._sock, self._state)
  end
end

function IOStreamT:_handle_events(fd, events)
  if events.IN then
    self:_handle_read()
  end
  if events.OUT then
    if self._connecting then
      self:_handle_connect()
    end
    self:_handle_write()
  end
  local state = 0
  if self:reading() then
    state = bit.bor(0, self.IN)
  end
  if self:writing() then
    state = bit.bor(0, self.OUT)
  end
  if state ~= self._state then
    self._state = state
    self.ioloop:update_handler(self._sock, self._state)
  end
end

function IOStreamT:reading()
  return self._read_callback ~= nil
end

function IOStreamT:writing()
  return self._write_buffer:length() > 0
end

function IOStreamT:_run_callback(callback, ...)
  self.ioloop:add_callback(partial(callback, self, ...))
end

function IOStreamT:_handle_connect()
  local err = self._sock:getsockopt(1, 4) -- SOL_SOCKET, SO_ERROR
  if err ~= 0 then
    error(t.error(err))
  end
  if self._connect_callback then
    local callback = self._connect_callback
    self._connect_callback = nil
    self:_run_callback(callback)
  end
  self._connecting = false
end

function IOStreamT:_handle_read()
  local data = assert(self._sock:read(buf, bufsize))
  self._read_buffer:append(data)
  self._read_buffer_size = self._read_buffer_size + #data
  self:_read_from_buffer()
end

function IOStreamT:_handle_write()
  local wbuf = self._write_buffer
  local num_bytes
  while wbuf:length() > 0 do
    num_bytes = self._sock:send(wbuf:leftmost())
    if not num_bytes then
      break
    end
    _merge_prefix(wbuf, num_bytes or 0)
    wbuf:popleft()
  end
  if wbuf:length() == 0 and self._write_callback then
    local callback = self._write_callback
    self._write_callback = nil
    self:_run_callback(callback)
  end
end

function IOStreamT:_read_from_buffer()
  if self._read_bytes and self._read_buffer_size >= self._read_bytes then
    local callback = self._read_callback
    self._read_callback = nil
    local num_bytes = self._read_bytes
    self._read_bytes = nil
    self:_run_callback(callback, self:_consume(num_bytes))
    return true
  end
  --TODO read a line or so
  return false
end

function IOStreamT:_consume(n)
  _merge_prefix(self._read_buffer, n)
  self._read_buffer_size = self._read_buffer_size - n
  return self._read_buffer:popleft()
end

function _merge_prefix(dq, size)
  local prefix = {}
  local remaining = size
  while dq:length() > 0 and remaining > 0 do
    local chunk = dq:popleft()
    if #chunk > remaining then
      dq:appendleft(string.sub(chunk, remaining + 1))
      chunk = string.sub(chunk, 1, remaining)
    end
    table.insert(prefix, chunk)
    remaining = remaining - #chunk
  end
  dq:appendleft(table.concat(prefix))
end
