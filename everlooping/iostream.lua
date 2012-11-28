local assert = assert
local setmetatable = setmetatable
local table = table
local string = string
local error = error
local math = math

local bit = require('bit')
local S = require('syscall')
local t, c = S.t, S.c
local def_ioloop = require('everlooping.ioloop').defaultIOLoop
local deque = require('everlooping.deque').deque
local partial = require('everlooping.util').partial

--debugging stuff
local _tostring = require('logging').tostring
local print = function(...)
  print(_tostring(...))
end

module('everlooping.iostream')

local bufsize = 4096
local buffer = t.buffer(bufsize)
local _merge_prefix, _double_prefix

local IOStreamT = {
  IN  = 0x001,
  OUT = 0x004,
  ERR = 0x008,
  HUP = 0x010,
}
IOStreamT.__index = IOStreamT

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
  local ok, err = self._sock:connect(address)
  if not ok and not err.INPROGRESS then
    print{'iostream connect', ok, err}
    self:_run_callback(callback, false, err)
  else
    self._connect_callback = callback
    self:_add_io_state(self.OUT)
  end
end

function IOStreamT:read_bytes(num_bytes, callback)
  self:_set_read_callback(callback)
  self._read_bytes = num_bytes
  self:_try_inline_read()
end

function IOStreamT:read_until(delimiter, callback)
  self:_set_read_callback(callback)
  self._read_delimiter = delimiter
  self:_try_inline_read()
end

function IOStreamT:read_until_close(callback)
  self:_set_read_callback(callback)
  if self._closed then
    self:_run_callback(callback, self:_consume(self._read_buffer_size))
    self._read_callback = nil
    return
  end
  self._read_until_close = true
  self:_add_io_state(self.IN)
end

function IOStreamT:_set_read_callback(callback)
  if self._read_callback then
    error('Already reading')
  elseif self._closed then
    error('closed')
  end
  self._read_callback = callback
end

function IOStreamT:_try_inline_read()
  if not self:_read_from_buffer() then
    self:_add_io_state(self.IN)
  end
end

function IOStreamT:write(data, callback)
  if self._closed then
    return nil, 'closed'
  end
  self._write_buffer:append(data)
  self._write_callback = callback
  if not self._connecting then
    self:_handle_write()
  end
end

function IOStreamT:close()
  if not self._closed then
    if self._read_until_close then
      callback = self._read_callback
      self._read_callback = nil
      self._read_until_close = nil
      self:_run_callback(callback, self:_consume(self._read_buffer_size))
      -- self._close_callback may have changed; let't try again from the start
      self:_run_callback(self.close, self)
      return
    end
    if self._close_callback then
      local callback = self._close_callback
      self._close_callback = nil
      self:_run_callback(callback)
    end
    self._write_buffer = nil
    self._read_buffer = nil
    self.ioloop:remove_handler(self._sock)
    self._sock:close()
    self._closed = true
  end
end

function IOStreamT:_add_io_state(state)
  if self._state == nil then
    self._state = bit.bor(state, self.HUP)
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
  if self._closed then
    --trigger seq:
    --  server: send, recv
    --  peer: connect, recv, close
    return
  end
  if events.OUT then
    if self._connecting then
      self:_handle_connect()
    end
    self:_handle_write()
  end
  if events.HUP or events.ERR then
    --trigger seq:
    --  server: send, recv, send
    --  peer: connect, recv, send, close
    --timeout
    self:close()
    return
  end
  local state = bit.bor(self.HUP, self.ERR)
  if self:reading() then
    state = bit.bor(state, self.IN)
  end
  if self:writing() then
    state = bit.bor(state, self.OUT)
  end
  if state ~= self._state then
    self._state = state
    self.ioloop:update_handler(self._sock, self._state)
  end
end

function IOStreamT:set_close_callback(callback)
  self._close_callback = callback
end

function IOStreamT:reading()
  return self._read_callback ~= nil
end

function IOStreamT:writing()
  return self._write_buffer and self._write_buffer:length() > 0
end

function IOStreamT:_run_callback(callback, ...)
  self.ioloop:add_callback(partial(callback, self, ...))
end

function IOStreamT:_handle_connect()
  local err = self._sock:getsockopt(1, 4) -- SOL_SOCKET, SO_ERROR
  if self._connect_callback then
    local callback = self._connect_callback
    self._connect_callback = nil
    if err ~= 0 then
      self:_run_callback(callback, false, t.error(err))
    else
      self:_run_callback(callback, true)
    end
  end
  self._connecting = false
end

function IOStreamT:_handle_read()
  local data, err = self._sock:read(buf, bufsize)
  if not data then
    self:close()
    return
  end
  self._read_buffer:append(data)
  self._read_buffer_size = self._read_buffer_size + #data
  self:_read_from_buffer()
  --peer closes the connection
  if #data == 0 then
    self:close()
  end
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
  if self._read_bytes then
    if self._read_buffer_size >= self._read_bytes then
      local callback = self._read_callback
      self._read_callback = nil
      local num_bytes = self._read_bytes
      self._read_bytes = nil
      self:_run_callback(callback, self:_consume(num_bytes))
      return true
    end
  elseif self._read_delimiter then
    if self._read_buffer:length() > 0 then
      while true do
        local loc = string.find(self._read_buffer:leftmost(), self._read_delimiter, 1, true)
        if loc then
          local callback = self._read_callback
          local delimiter_len = #self._read_delimiter
          self._read_callback = nil
          self._read_delimiter = nil
          self:_run_callback(callback, self:_consume(loc + delimiter_len - 1))
          return true
        end
        if self._read_buffer:length() == 1 then
          break
        end
        _double_prefix(self._read_buffer)
      end
    end
  end
  return false
end

function IOStreamT:_consume(n)
  _merge_prefix(self._read_buffer, n)
  self._read_buffer_size = self._read_buffer_size - n
  return self._read_buffer:popleft()
end

function IOStreamT:getfd()
  return self._sock
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

function _double_prefix(deque)
  local first_len = #deque:leftmost()
  local new_len = math.max(first_len * 2, first_len + #deque:at(2))
  _merge_prefix(deque, new_len)
end
