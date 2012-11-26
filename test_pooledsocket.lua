#!/usr/bin/env luajit

local cosocket = require('everlooping.tcppool')
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
  request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: keep-alive\r\n\r\n')
  cosocket.sleep(2)
  request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: keep-alive\r\n\r\n')
  cosocket.sleep(6)
  request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: keep-alive\r\n\r\n')
end)

-- cosocket.register(function()
--   request('lilydjwg.is-programmer.com', 80, 'GET / HTTP/1.1\r\nHost: lilydjwg.is-programmer.com\r\nConnection: close\r\n\r\n')
-- end)

-- cosocket.register(function()
--   request('www.google.com', 80, 'GET / HTTP/1.1\r\nHost: www.google.com\r\nConnection: close\r\n\r\n')
--   print('fall into 4-second-long sleep...')
--   cosocket.sleep(4)
--   print('woke up from 4-second-long sleep!')
--   request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: close\r\n\r\n')
--   print('fall into 3-second-long sleep...')
--   cosocket.sleep(3)
--   print('woke up from 3-second-long sleep!')
-- end)

-- cosocket.register(function()
--   request('twitter.com', 80, 'GET / HTTP/1.1\r\nHost: twitter.com\r\nConnection: close\r\n\r\n')
-- end)

-- cosocket.register(function()
--   request('teamconnected.org', 80, 'GET / HTTP/1.1\r\nHost: teamconnected.org\r\nConnection: close\r\n\r\n')
-- end)

-- cosocket.register(function()
--   print('request thread:', coroutine.running())
--   local host = 'baidu.com'
--   local port = 80
--   local data = 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: close\r\n\r\n'
--   local s = cosocket.tcp()
--   s:connect(host, port)
--   s:send(data)
--   local l, err = s:receive('*a')
--   if l then
--     print(l)
--   else
--     print(l, err)
--   end
--   print('fall into 7-second-long sleep...')
--   cosocket.sleep(7)
--   print('woke up from 7-second-long sleep!')
--   print('Request complete.')
-- end)

ioloop.defaultIOLoop():start()
