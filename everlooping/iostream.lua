local assert = assert
local setmetatable = setmetatable
local table = table
local string = string

local bit = require('bit')
local S = require('syscall')
local t, c = S.t, S.c
local def_ioloop = require('everlooping.ioloop').defaultIOLoop
local deque = require('everlooping.deque').deque

module('everlooping.iostream')

local bufsize = 4096
local buffer = t.buffer(bufsize)

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
  o._read_buffer_size = 0
  o.ioloop = ioloop or def_ioloop()
  setmetatable(o, IOStreamT)
  return o
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
      --TODO
      self:_handle_connect()
    --TODO
    self._handle_write()
  end
end

function IOStreamT:_handle_read()
  local data = assert(self._sock:read(buf, bufsize))
  self._read_buffer:append(data)
  self._read_buffer_size = self._read_buffer_size + #data
  --TODO
  self:_read_from_buffer()
end

function IOStreamT:_read_from_buffer()
  if self._read_bytes and self._read_buffer_size >= self._read_bytes then
    --TODO
    local cb = self._read_callback
    self._read_callback = nil
    local num_bytes = self._read_bytes
    self._read_bytes = nil
    cb(self._consume(num_bytes))
    return
  end
  --TODO read a line or so
end

function IOStreamT:_consume(n)
  _merge_prefix(self._read_buffer, n)
  self._read_buffer_size = self._read_buffer_size - n
  return self._read_buffer:popleft()
end

local function _merge_prefix(dq, size)
  local prefix = {}
  local remaining = size
  while dq:length() > 0 and remaining > 0 do
    local chunk = dq:popleft()
    if #chunk > remaining then
      dq:appendleft(string.sub(chunk, remaining + 1))
      chunk = string.sub(chunk, 1, remaining)
    table.insert(prefix)
    remaining = remaining - #chunk
  end
  return table.concat(prefix)
end
