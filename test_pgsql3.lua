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
  for i=0, 200 do
    print(util.time() .. ': moew~')
    cosocket.sleep(0.1)
  end
end)

local data = [[
(-6, 'test1',   'haha1',   'str'), 
(-6, 'test2',   'haha2',   'str'), 
(-6, 'test3',   'haha3',   'str'), 
(-6, 'test4',   'haha4',   'str'), 
(-6, 'test5',   'haha5',   'str'), 
(-6, 'test6',   'haha6',   'str'), 
(-6, 'test7',   'haha7',   'str'), 
(-6, 'test8',   'haha8',   'str'), 
(-6, 'test9',   'haha9',   'str'), 
(-6, 'test10',  'haha10',  'str'), 
(-6, 'test11',  'haha11',  'str'), 
(-6, 'test12',  'haha12',  'str'), 
(-6, 'test13',  'haha13',  'str'), 
(-6, 'test14',  'haha14',  'str'), 
(-6, 'test15',  'haha15',  'str'), 
(-6, 'test16',  'haha16',  'str'), 
(-6, 'test17',  'haha17',  'str'), 
(-6, 'test18',  'haha18',  'str'), 
(-6, 'test19',  'haha19',  'str'), 
(-6, 'test20',  'haha20',  'str'), 
(-6, 'test21',  'haha21',  'str'), 
(-6, 'test22',  'haha22',  'str'), 
(-6, 'test23',  'haha23',  'str'), 
(-6, 'test24',  'haha24',  'str'), 
(-6, 'test25',  'haha25',  'str'), 
(-6, 'test26',  'haha26',  'str'), 
(-6, 'test27',  'haha27',  'str'), 
(-6, 'test28',  'haha28',  'str'), 
(-6, 'test29',  'haha29',  'str'), 
(-6, 'test30',  'haha30',  'str'), 
(-6, 'test31',  'haha31',  'str'), 
(-6, 'test32',  'haha32',  'str'), 
(-6, 'test33',  'haha33',  'str'), 
(-6, 'test34',  'haha34',  'str'), 
(-6, 'test35',  'haha35',  'str'), 
(-6, 'test36',  'haha36',  'str'), 
(-6, 'test37',  'haha37',  'str'), 
(-6, 'test38',  'haha38',  'str'), 
(-6, 'test39',  'haha39',  'str'), 
(-6, 'test40',  'haha40',  'str'), 
(-6, 'test41',  'haha41',  'str'), 
(-6, 'test42',  'haha42',  'str'), 
(-6, 'test43',  'haha43',  'str'), 
(-6, 'test44',  'haha44',  'str'), 
(-6, 'test45',  'haha45',  'str'), 
(-6, 'test46',  'haha46',  'str'), 
(-6, 'test47',  'haha47',  'str'), 
(-6, 'test48',  'haha48',  'str'), 
(-6, 'test49',  'haha49',  'str'), 
(-6, 'test50',  'haha50',  'str'), 
(-6, 'test51',  'haha51',  'str'), 
(-6, 'test52',  'haha52',  'str'), 
(-6, 'test53',  'haha53',  'str'), 
(-6, 'test54',  'haha54',  'str'), 
(-6, 'test55',  'haha55',  'str'), 
(-6, 'test56',  'haha56',  'str'), 
(-6, 'test57',  'haha57',  'str'), 
(-6, 'test58',  'haha58',  'str'), 
(-6, 'test59',  'haha59',  'str'), 
(-6, 'test60',  'haha60',  'str'), 
(-6, 'test61',  'haha61',  'str'), 
(-6, 'test62',  'haha62',  'str'), 
(-6, 'test63',  'haha63',  'str'), 
(-6, 'test64',  'haha64',  'str'), 
(-6, 'test65',  'haha65',  'str'), 
(-6, 'test66',  'haha66',  'str'), 
(-6, 'test67',  'haha67',  'str'), 
(-6, 'test68',  'haha68',  'str'), 
(-6, 'test69',  'haha69',  'str'), 
(-6, 'test70',  'haha70',  'str'), 
(-6, 'test71',  'haha71',  'str'), 
(-6, 'test72',  'haha72',  'str'), 
(-6, 'test73',  'haha73',  'str'), 
(-6, 'test74',  'haha74',  'str'), 
(-6, 'test75',  'haha75',  'str'), 
(-6, 'test76',  'haha76',  'str'), 
(-6, 'test77',  'haha77',  'str'), 
(-6, 'test78',  'haha78',  'str'), 
(-6, 'test79',  'haha79',  'str'), 
(-6, 'test80',  'haha80',  'str'), 
(-6, 'test81',  'haha81',  'str'), 
(-6, 'test82',  'haha82',  'str'), 
(-6, 'test83',  'haha83',  'str'), 
(-6, 'test84',  'haha84',  'str'), 
(-6, 'test85',  'haha85',  'str'), 
(-6, 'test86',  'haha86',  'str'), 
(-6, 'test87',  'haha87',  'str'), 
(-6, 'test88',  'haha88',  'str'), 
(-6, 'test89',  'haha89',  'str'), 
(-6, 'test90',  'haha90',  'str'), 
(-6, 'test91',  'haha91',  'str'), 
(-6, 'test92',  'haha92',  'str'), 
(-6, 'test93',  'haha93',  'str'), 
(-6, 'test94',  'haha94',  'str'), 
(-6, 'test95',  'haha95',  'str'), 
(-6, 'test96',  'haha96',  'str'), 
(-6, 'test97',  'haha97',  'str'), 
(-6, 'test98',  'haha98',  'str'), 
(-6, 'test99',  'haha99',  'str'), 
(-6, 'test100', 'haha100', 'str')
]]

cosocket.register(function()
  print('request thread:', coroutine.running())
  write('\n')
  p = PQ.pgsql()
  local ok, err = p:connect('host=127.0.0.1 dbname=teamconnected')
  if not ok then
    write(err)
  end

  -- ok, err = p:query("select * from account_entity_2 limit 4")
  print('insert begin')
  ok, err = p:query("insert into msg_entity values " .. data)
  if not ok then
    write(err)
  end
  print('insert end')

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
