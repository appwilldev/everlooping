#!/usr/bin/env luajit

local cosocket = require('everlooping.tcppool')
local ioloop = require('everlooping.ioloop')
ngx = require('ngx')
local redis = require("resty.redis")
local cjson = require("cjson")

cosocket.register(function()
  local red = redis:new()

  red:set_timeout(1000) -- 1 sec

  local ok, err = red:connect("localhost", 6379)
  if not ok then
    print("failed to connect: ", err)
    return
  end

  ok, err = red:set("dog", "an aniaml")
  if not ok then
    print("failed to set dog: ", err)
    return
  end

  print("set result: ", ok)
  red:set_keepalive()

  local red = redis:new()

  red:set_timeout(1000) -- 1 sec

  local ok, err = red:connect("localhost", 6379)
  if not ok then
    print("failed to connect: ", err)
    return
  end
  local res, err = red:get("dog")
  if not res then
    print("failed to get dog: ", err)
  end
  print("get result: ", res)

  if res == cjson.null then
    print("dog not found.")
  end
  red:set_keepalive()

end)

cosocket.register(function()
  cosocket.sleep(1)
  local red = redis:new()

  red:set_timeout(1000) -- 1 sec

  local ok, err = red:connect("localhost", 6379)
  if not ok then
    print("failed to connect: ", err)
    return
  end
  local res, err = red:get("dog")
  if not res then
    print("failed to get dog: ", err)
  end
  print("get result: ", res)

  if res == cjson.null then
    print("dog not found.")
  end

  red:set_keepalive()
  print('reused: ' .. red:get_reused_times())
end)

ioloop.defaultIOLoop():start()
