local setmetatable = setmetatable

--debugging stuff
local _tostring = require('logging').tostring
local pure_print = print
local print = function(...)
  print(_tostring{...})
end
local debug = debug

local cosocket = require('everlooping.cosocket')
local defaultIOLoop = require('everlooping.ioloop').defaultIOLoop
local dictqueue = require('everlooping.dictqueue').dictqueue
local dictwithsize = require('everlooping.dictwithsize').dictwithsize

module('everlooping.tcppool')

local PoolT = {
  defaultTimeout = 60,
  defaultPoolsize = 30,
}
PoolT.__index = PoolT

local function hash_key(host, port)
  return host .. ':' .. port
end

function Pool(size, ioloop)
  local o = {}
  o.size = size or PoolT.defaultPoolsize
  o.ioloop = ioloop or defaultIOLoop()
  o._busy_sockets = dictwithsize()
  o._idle_sockets = dictqueue(function(item)
    item[1]:close()
  end)
  setmetatable(o, PoolT)
  return o
end

function PoolT:getout(key)
  local d = self._idle_sockets:getout(key)
  if d then
    self._busy_sockets:set(d[1], true)
    return d
  end
end

function PoolT:put(key, stream, timeout)
  self._busy_sockets:set(stream, nil)
  self._idle_sockets:set(key, {stream, timeout})
  if self._idle_sockets:length() + self._busy_sockets:length() > self.size then
    self._idle_sockets:removeleft()
  end
end

function PoolT:delete(key, value)
  print('deleting because someone asked')
  self._idle_sockets:delete(key, value)
end

local tcpT = {}
tcpT.__index = tcpT
setmetatable(tcpT, cosocket.tcpT)
baseTcpT = cosocket.tcpT

function tcp()
  local o = {}
  setmetatable(o, tcpT)
  return o
end

local function new_socket(self)
  local new = cosocket.tcp()
  self._sock = new._sock
  new:_wrap_stream()
  self.stream = new.stream
end

function tcpT:connect(addr, port)
  self.key = hash_key(addr, port)
  if not pool then
    new_socket(self)
    self.stream._reused = 0
    return baseTcpT.connect(self, addr, port)
  else
    local o = pool:getout(self.key)
    if o then
      self.stream = o[1]
      pool.ioloop:remove_timeout(o[2])
      self.stream._reused = self.stream._reused + 1
      return true
    else
      print('New connection is made', addr, port)
      new_socket(self)
      self.stream._reused = 0
      return baseTcpT.connect(self, addr, port)
    end
  end
end

function tcpT:setkeepalive(timeout, size)
  self._keepalive = true
  if timeout == nil then
    timeout = PoolT.defaultTimeout
  elseif timeout == 0 then
    timeout = 3600 * 24 * 365 -- 1 year
  else
    timeout = timeout / 1000 -- ms to s
  end
  if not pool then
    pool = Pool(size)
  end
  local timeout = pool.ioloop:add_timeout(
    pool.ioloop.time() + timeout, function()
      print('deleting because of timeout')
      pool:delete(self.key, self.stream)
    end)
  pool:put(self.key, self.stream, timeout)
  return 1
end

function tcpT:close()
  if not self._keepalive then
    baseTcpT.close(self)
  end
end

function tcpT:receive(...)
  if not self._keepalive then
    return baseTcpT.receive(self, ...)
  else
    return nil, 'closed'
  end
end

function tcpT:send(...)
  if not self._keepalive then
    return baseTcpT.send(self, ...)
  else
    return nil, 'closed'
  end
end

function tcpT:getreusedtimes()
  if self.stream then
    return self.stream._reused
  else
    return nil
  end
end

register = cosocket.register
sleep = cosocket.sleep
