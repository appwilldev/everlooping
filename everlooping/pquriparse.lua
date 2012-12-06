#!/usr/bin/env lua

local E = require('datautil.escape')
local D = require('datautil.dict')

local pairs = pairs
local error = error
local table_insert = table.insert
local table_concat = table.concat

local print = print

module(...)

function parse(uri)
  local s = uri
  if s:sub(1, 11) ~= 'postgres://' and s:sub(1, 13) ~= 'postgresql://' then
    return s
  end

  if s:sub(9, 9) == ':' then
    s = s:sub(12)
  else
    s = s:sub(14)
  end

  s = E.URIunescape(s)

  local info = {}

  -- parse and remove password so it won't be taken as a port precedent
  local a, b = s:find(':[^@:/?&]*@')
  if a then
    local password = s:sub(a+1, b-1)
    if password ~= '' then
      info.password = password
    end
    s = s:sub(1, a-1) .. s:sub(b)
  end

  local pos, sep, nextType
  while s ~= '' do
    pos = s:find('[%[@:/?&]')
    if pos then
      sep = s:sub(pos, pos)
    else
      pos = #s+1
      sep = nil
    end
    if nextType == nil then
      if sep == '@' then
        info.user = s:sub(1, pos-1)
        s = s:sub(pos+1)
      elseif sep == '[' and pos == 1 then
        pos = s:find('%]')
        info.hostaddr = s:sub(1, pos)
        s = s:sub(pos+1)
      else
        info.host = s:sub(1, pos-1)
        s = s:sub(pos+1)
        if sep == ':' then
          nextType = 'port'
        elseif sep == '?' then
          nextType = 'query'
        elseif sep == '/' then
          nextType = 'dbname'
        elseif sep == nil then
          break
        else
          error('failed to parse URI: ' .. uri)
        end
      end
    else
      if nextType == 'query' then
        D.update(info, E.parseQuery(s))
        break
      else
        info[nextType] = s:sub(1, pos-1)
        if pos then
          s = s:sub(pos+1)
        else
          s = ''
        end
      end
      if sep == ':' then
        nextType = 'port'
      elseif sep == '?' then
        nextType = 'query'
      elseif sep == '/' then
        nextType = 'dbname'
      end
    end
  end
  if info.host == '' then
    info.host = nil
  end

  local ret = {}
  for k, v in pairs(info) do
    table_insert(ret, k .. '=' .. v)
  end
  return table_concat(ret, ' ')
end
