#!/usr/bin/env luajit

local ffi = require('ffi')
local bit = require('bit')

local type = type
local tonumber = tonumber
local print = print

require('everlooping.pcre_header')
local partial = require('everlooping.util').partial

module(...)

local L = ffi.load('pcre')

local flags = {
  a = L.PCRE_ANCHORED,
  d = 0, --ignored. should call L.pcre_dfa_exec
  i = L.PCRE_CASELESS,
  j = 0, --ignored
  m = L.PCRE_MULTILINE,
  o = 0, --ignored
  s = L.PCRE_DOTALL,
  u = L.PCRE_UTF8,
  x = L.PCRE_EXTENDED,
}

local function options2flags(options)
  local f = 0
  for i=1, #options do
    f = bit.bor(f, flags[options:sub(i, i)])
  end
  return f
end

function match(subject, regex, options, ctx)
  --[[
  ctx
    pos
    _rectx: for reuse; should manually call pcre_free on re field
    _index: boolean for retrieving indexes instead of strings, 1-based
  --]]

  --[[
  The original function:

  Matches the subject string using the Perl compatible regular expression regex
  with the optional options.

  Only the first occurrence of the match is returned, or nil if no match is
  found. In case of fatal errors, like seeing bad UTF-8 sequences in UTF-8 mode,
  a Lua exception will be raised.

  When a match is found, a Lua table captures is returned, where captures[0]
  holds the whole substring being matched, and captures[1] holds the first
  parenthesized sub-pattern's capturing, captures[2] the second, and so on.
  --]]
  local o = 0
  local pos
  if not ctx or not ctx.pos then
    pos = 0
  else
    pos = ctx.pos
  end
  local re, n, size, ovector
  if type(ctx._rectx) == 'table' then
    re = ctx._rectx.re
    n = ctx._rectx.n
    size = ctx._rectx.size
    ovector = ctx._rectx.ovector
    o = ctx._rectx.options
  else
    if options then
      o = options2flags(options)
    end
    local errptr = ffi.new('const char*[1]')
    local intptr = ffi.new('int[1]')
    re = L.pcre_compile(regex, o, errptr, intptr, nil)
    if re == nil then
      return nil, ffi.string(errptr[0]), intptr[0]
    end
    L.pcre_fullinfo(re, nil, 2 --[[PCRE_INFO_CAPTURECOUNT]], intptr)
    n = intptr[0]
    size = (n + 1) * 3
    ovector = ffi.new('int['..size..']')
  end
  local st = L.pcre_exec(re, nil, subject, #subject, pos, 0, ovector, size)
  local err
  if st == -1 then
    -- no match
    if not ctx._rectx then
      L.pcre_free(re)
    end
    return nil
  elseif st < 0 then
    err = 'pcre_exec failed with error code ' .. ret
  end
  if not ctx._rectx then
    L.pcre_free(re)
  elseif ctx._rectx == true then
    ctx._rectx = {
      re = re,
      n = n,
      size = size,
      ovector = ovector,
      options = o,
    }
  end
  if err then
    return nil, err
  end
  local ret = {}
  if ctx then
    ctx.pos = ovector[1]
  end
  if ctx._index then
    for i=0, n*2, 2 do
      ret[i/2] = {ovector[i]+1, ovector[i+1]}
    end
  else
    for i=0, n*2, 2 do
      if ovector[i] >= 0 then
        ret[i/2] = subject:sub(ovector[i]+1, ovector[i+1])
      end
    end
  end
  return ret
end

function gmatch(subject, regex, options, index)
  local ctx = { pos = 0, _rectx = true }
  if index then
    ctx._index = true
  end
  return function()
    while ctx.pos < #subject do
      local ret = match(subject, regex, options, ctx)
      if not ret then
        L.pcre_free(ctx._rectx.re)
      end
      return ret
    end
  end
end

local function _sub_replace(subject, m, s)
  if s == '$' then
    return '$'
  else
    local n = tonumber(s)
    if n then
      if m[n] then
        return subject:sub(m[n][1], m[n][2])
      else
        return ''
      end
    else
      return n
    end
  end
end

function sub(subject, regex, replace, options)
  local m = match(subject, regex, options, { _index = true })
  local r = replace:gsub('%$(.)', partial(_sub_replace, subject, m))
  if m then
    return subject:sub(1, m[0][1]-1) .. r .. subject:sub(m[0][2]+1), 1
  else
    return subject, 0
  end
end

function gsub(subject, regex, replace, options)
  local count = 0
  local s = subject
  for m in gmatch(subject, regex, options, true) do
    local r = replace:gsub('%$(.)', partial(_sub_replace, subject, m))
    s = s:sub(1, m[0][1]-1) .. r .. s:sub(m[0][2]+1)
    count = count + 1
  end
  return s, count
end
