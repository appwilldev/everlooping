#!/usr/bin/env luajit

ngx = require('ngx')

ngx.var = {
  MOOCHINE_APP_PATH = os.getenv('PWD'),
  MOOCHINE_APP_NAME = 'test',
  HADDIT_APP_PATH = os.getenv('HADDIT_HOME') .. '/luasrc',
  HADDIT_CONFIG = os.getenv('PWD') .. '/conf/haddit.config',
  request_method = 'GET',
  REQUEST_URI = '/new_device',
}

ngx.req = {
  get_headers = function()
    return {}
  end,
  get_uri_args = function()
    return {
      macaddr = 'xxx0',
    }
  end,
}

local ffi = require('ffi')
-- keep the reference in L
local L = ffi.load('crypto', true)
local L2 = ffi.load('ngxc', true)

local cosocket = require('everlooping.tcppool')
local ioloop = require('everlooping.ioloop')

cosocket.register(function()
  assert(loadfile(arg[1]))()

  print('Headers:')
  for k, v in pairs(ngx.header) do
    print(k .. ': ' .. v)
  end

  ioloop.defaultIOLoop():stop()
end)

ioloop.defaultIOLoop():start()
