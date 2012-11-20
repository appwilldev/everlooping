#!/usr/bin/env luajit

local cosocket = require('everlooping.cosocket')
local ioloop = require('everlooping.ioloop')

function request(host, port, data)
  print('request thread:', coroutine.running())
  local s = cosocket.tcp()
  s:connect(host, port)
  s:send(data)
  while true do
    local l, err = s:receive('*l')
    if l then
      print(l)
    else
      print(l, err)
      break
    end
  end
  s:close()
  print('Request complete.')
end

cosocket.register(function()
  request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: close\r\n\r\n')
  request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: close\r\n\r\n')
  request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: close\r\n\r\n')
end)

-- cosocket.register(function()
--   request('lilydjwg.is-programmer.com', 80, 'GET / HTTP/1.1\r\nHost: lilydjwg.is-programmer.com\r\nConnection: close\r\n\r\n')
-- end)

-- cosocket.register(function()
--   request('lilydjwg.is-programmer.com', 80, 'GET / HTTP/1.1\r\nHost: lilydjwg.is-programmer.com\r\nConnection: close\r\n\r\n')
-- end)

cosocket.register(function()
  request('teamconnected.org', 80, 'GET / HTTP/1.1\r\nHost: teamconnected.org\r\nConnection: close\r\n\r\n')
end)

print('main thread:', coroutine.running())
ioloop.defaultIOLoop():start()
