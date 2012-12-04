#!/usr/bin/env luajit

-- for debug
local _tostring = require('logging').tostring
local write = function(s) io.stdout:write(s) end
local print = function(...)
  print(_tostring{...})
end

local PQ = require('everlooping.pgsql')
local cosocket = require('everlooping.cosocket')
local ioloop = require('everlooping.ioloop')

cosocket.register(function()
  print('request thread:', coroutine.running())
  write('\n')
  p = PQ.pgsql()
  local ok, err = p:connect('dbname=teamconnected')
  if not ok then
    write(err)
  end

  ok, err = p:query('select * from msg_entity limit 2')
  if not ok then
    write(err)
  else
    for _, name in ipairs(ok.fieldnames) do
      write(string.format('%-15s', name))
    end
    write('\n' .. string.rep('=', 15 * #ok.fieldnames) .. '\n')
    for _, row in ipairs(ok.resultset) do
      for _, val in ipairs(row) do
        write(string.format('%-15s', val))
      end
      write('\n')
    end
  end
  write('\n')

  ok, err = p:query('select 1+3 * 7')
  if not ok then
    write(err)
  else
    for _, name in ipairs(ok.fieldnames) do
      write(string.format('%-15s', name))
    end
    write('\n' .. string.rep('=', 15 * #ok.fieldnames) .. '\n')
    for _, row in ipairs(ok.resultset) do
      for _, val in ipairs(row) do
        write(string.format('%-15s', val))
      end
      write('\n')
    end
  end
  write('\n')

  ok, err = p:query("copy (select * from msg_entity order by id) to '/tmp/testdata'")
  if not ok then
    write(err)
  end

  write('\nexpecting error messages:\n\n')
  ok, err = p:query('select * from notthere')
  if not ok then
    write(err)
  end
  p:close()
  print('Request complete.')
end)

ioloop.defaultIOLoop():start()
