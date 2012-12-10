#!/usr/bin/env luajit

local ioloop = require('everlooping.ioloop')
ngx = require('ngx')
local resolver = require("resty.dns.resolver")
local cosocket = require('everlooping.tcppool')

function test_dns(host)
  local r, err = resolver:new{
    nameservers = {"8.8.8.8", {"8.8.4.4", 53} },
    retrans = 5,  -- 5 retransmissions on receive timeout
    timeout = 2000,  -- 2 sec
  }

  if not r then
    ngx.say("failed to instantiate the resolver: ", err)
    os.exit(1)
  end

  local answers, err = r:query(host)
  if not answers then
    ngx.say("failed to query the DNS server: ", err)
    return
  end

  for i = 1, #answers do
    local ans = answers[i]
    ngx.say(ans.name, " ", ans.address or ans.cname,
    " type:", ans.type, " class:", ans.class,
    " ttl:", ans.ttl)
  end
end

cosocket.register(function()
  test_dns('www.google.com')
end)

cosocket.register(function()
  test_dns('twitter.com')
end)

cosocket.register(function()
  test_dns('tlskadklfh.com')
end)

ioloop.defaultIOLoop():start()
