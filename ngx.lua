#!/usr/bin/env luajit

local setmetatable = setmetatable
local print = print
local os = os
local cosocket = require('everlooping.tcppool')

module('ngx')

shared = setmetatable({}, {
  __index = function(t, i)
    t[i] = {}
    return t[i]
  end
})

ctx = setmetatable({}, {
  __index = function(t, i)
    t[i] = {}
  end
})

null = {}

var = {
  HADDIT_CONFIG = nil,
  MOOCHINE_APP_PATH = nil,
}

time = os.time
log = print
ERR = 'ERROR'

md5 = nil
location = {
  capture = nil,
}

sleep = cosocket.sleep
