#!/usr/bin/env luajit

local assert = assert
local table = table
local string = string
local select = select
local unpack = unpack
local pairs = pairs
local ipairs = ipairs
local type = type

local S = require('syscall')
local t, c = S.t, S.c
local ffi = require('ffi')

module('everlooping.util')

function partial(func, ...)
  if select("#", ...) == 0 then
    return func
  end
  local args = {...}
  return function(...)
    local _args = {...}
    local real_args = {unpack(args)}
    for _, v in ipairs(_args) do
      table.insert(real_args, v)
    end
    return func(unpack(real_args))
  end
end

function table_length(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

function bind_socket(port, address, family, backlog)
  --family is inet or inet6
  backlog = backlog or 128
  family = family or 'inet'
  local wildaddr
  if family == 'inet' then
    wildaddr = '0.0.0.0'
  else
    wildaddr = '::'
  end
  address = address or wildaddr
  local s = assert(S.socket(family, "stream, nonblock"))
  local sa
  if family == 'inet' then
    sa = assert(t.sockaddr_in(port, address))
  else
    sa = assert(t.sockaddr_in6(port, address))
    --setsockopt(IPPROTO_IPV6, IPV6_V6ONLY, 1)
    s:setsockopt(41, 26, true)
  end
  s:setsockopt("socket", "reuseaddr", true)
  assert(s:bind(sa))
  s:listen(backlog)
  return s
end

ffi.cdef[[
struct hostent {
  char  *h_name;            /* official name of host */
  char **h_aliases;         /* alias list */
  int    h_addrtype;        /* host address type */
  int    h_length;          /* length of address */
  char **h_addr_list;       /* list of addresses */
};
struct hostent *gethostbyname(const char *name);
]]

function simpleDNSQuery(host)
  local ans = ffi.C.gethostbyname(host)
  if ans == nil then
    return nil
  end
  local ip = ffi.string(ans.h_addr_list[0], 4)
  return table.concat({string.byte(ip, 1, 4)}, '.')
end

function flatten_table(t)
  local s = ''
  for _, v in ipairs(t) do
    if type(v) == 'table' then
      s = s .. flatten_table(v)
    else
      s = s .. v
    end
  end
  return s
end
