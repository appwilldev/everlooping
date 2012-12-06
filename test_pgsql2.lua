#!/usr/bin/env luajit

-- for debug
local _tostring = require('logging').tostring
local write = function(s) io.stdout:write(s) end
local tprint = function(...)
  print(_tostring{...})
end

local PQ = require('everlooping.pgsql')
local cosocket = require('everlooping.tcppool')
local util = require('everlooping.util')
local ioloop = require('everlooping.ioloop')

function request(host, port, data)
  print('request thread:', coroutine.running())
  local s = cosocket.tcp()
  s:settimeout(2000)
  local ok, err = s:connect(host, port)
  if not ok then
    print(err)
    return
  end
  s:send(data)
  while true do
    local l, err = s:receive('*l')
    if l then
      print(l)
      if l == '</html>' then
        break
      end
    else
      print(l, err)
      break
    end
  end
  s:setkeepalive(5000)
  print('Request complete.')
end

cosocket.register(function()
  for i=0, 10 do
    print(util.time() .. ': moew~')
    cosocket.sleep(0.1)
  end
end)

cosocket.register(function()
  print('request thread:', coroutine.running())
  write('\n')
  p = PQ.pgsql()
  local ok, err = p:connect('postgres://postgres:@localhost/haddit_dev')
  if not ok then
    write(err)
  end

  -- ok, err = p:query("select * from account_entity_2 limit 4")
  print('begin copying')
  ok, err = p:query("copy account_entity_2 to '/tmp/testdata'")
  if not ok then
    write(err)
  end
  print('end copying')

  p:close()
  print('Request complete.')
end)

-- cosocket.register(function()
--   request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: keep-alive\r\n\r\n')
--   cosocket.sleep(2)
--   request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: keep-alive\r\n\r\n')
--   cosocket.sleep(6)
--   request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: keep-alive\r\n\r\n')
-- end)

ioloop.defaultIOLoop():start()
