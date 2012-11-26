local setmetatable = setmetatable

--for debug
local print = print

local cosocket = require('everlooping.cosocket')
local defaultIOLoop = require('everlooping.ioloop').defaultIOLoop

module('everlooping.tcppool')

local PoolT = {
  defaultTimeout = 60 * 1000,
  defaultPoolsize = 30,
}
PoolT.__index = PoolT

local function hash_key(host, port)
  return host .. ':' .. port
end

function Pool(size, ioloop)
  local o = {}
  o.size = size or PoolT.defaultTimeout
  o.ioloop = ioloop or defaultIOLoop()
  o._busy_sockets = {}
  o._idle_sockets = {}
  setmetatable(o, PoolT)
  return o
end

function PoolT:getout(key)
  if self._idle_sockets[key] then
    local stream = self._idle_sockets[key]
    self._idle_sockets[key] = nil
    self._busy_sockets[stream] = true
    return stream
  end
end

local tcpT = {}
tcpT.__index = tcpT
setmetatable(tcpT, cosocket.tcpT)
baseTcpT = cosocket.tcpT

function tcp()
  local o = cosocket.tcp()
  setmetatable(o, tcpT)
  return o
end

function tcpT:connect(addr, port)
  self.key = hash_key(addr, port)
  if not pool then
    self.stream._reused = 0
    return baseTcpT.connect(self, addr, port)
  else
    local o = pool:getout(self.key)
    if o then
      print('reusing socket with key: ' .. self.key)
      self.stream = o[1]
      pool.ioloop:remove_timeout(o[2])
      self.stream._reused = self.stream._reused + 1
      return true
    else
      self.stream._reused = 0
      return baseTcpT.connect(self, addr, port)
    end
  end
end

function tcpT:setkeepalive(timeout, size)
  if not pool then
    pool = Pool(size)
  end
  if pool._busy_sockets[self.stream] then
    pool._busy_sockets[self.stream] = nil
  end
  local timeout = pool.ioloop:add_timeout(
    pool.ioloop.time() + (timeout or pool.defaultTimeout),
    function()
      pool._idle_sockets[self.key] = nil
      self.stream:close()
    end)
  self._keepalive = true
  pool._idle_sockets[self.key] = {self.stream, timeout}
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
