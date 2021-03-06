#!/usr/bin/env luajit

local cosocket = require('everlooping.cosocket')
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
    else
      print(l, err)
      break
    end
  end
  print('Request complete.')
end

-- cosocket.register(function()
--   request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: close\r\n\r\n')
--   request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: close\r\n\r\n')
--   request('baidu.com', 80, 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: close\r\n\r\n')
-- end)

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

cosocket.register(function()
  request('twitter.com', 80, 'GET / HTTP/1.1\r\nHost: twitter.com\r\nConnection: close\r\n\r\n')
end)

-- cosocket.register(function()
--   request('teamconnected.org', 80, 'GET / HTTP/1.1\r\nHost: teamconnected.org\r\nConnection: close\r\n\r\n')
-- end)

cosocket.register(function()
  print('request thread:', coroutine.running())
  local host = 'baidu.com'
  local port = 80
  local data = 'GET / HTTP/1.1\r\nHost: baidu.com\r\nConnection: close\r\n\r\n'
  local s = cosocket.tcp()
  s:connect(host, port)
  s:send(data)
  local l, err = s:receive('*a')
  if l then
    print(l)
  else
    print(l, err)
  end
  print('fall into 7-second-long sleep...')
  cosocket.sleep(7)
  print('woke up from 7-second-long sleep!')
  print('Request complete.')
end)

local loop = ioloop.defaultIOLoop()
function speak_out(sig)
  print('received signal!', sig.signo)
end
loop:add_signal_handler('int', speak_out)
loop:add_signal_handler('int', function()
  print('\rbye~')
  loop:stop()
end)
loop:add_signal_handler('quit', speak_out)
loop:remove_signal_handler('quit')
loop:remove_signal_handler('term')
loop:add_signal_handler('term', speak_out)
loop:start()
