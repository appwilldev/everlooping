#!/usr/bin/env luajit

local print = print
local setmetatable = setmetatable
local type = type
local ipairs = ipairs
local coroutine = coroutine
local table_insert = table.insert
local string_rep = string.rep

local cosocket = require('everlooping.tcppool')
local ioloop = require('everlooping.ioloop')
local defaultIOLoop = require('everlooping.ioloop').defaultIOLoop
local util = require('everlooping.util')
local partial = util.partial

local S = require('syscall')
local t, c = S.t, S.c
local ffi = require('ffi')

local oldassert = assert
function assert(c, s)
  return oldassert(c, tostring(s)) -- annoyingly, assert does not call tostring!
end
require('everlooping.pgsql_header')

module(...)

local P = ffi.load('pq')

pgsqlT = {}
pgsqlT.__index = pgsqlT

function pgsql(ioloop)
  local o = {}
  o._ioloop = ioloop
  setmetatable(o, pgsqlT)
  return o
end

local function _resume_me(co, ...)
  local ok, err = coroutine.resume(co, ...)
  if not ok then
    print('Error!', err)
    print('failed coroutine is:', co)
  end
end

local function _convert_results(res, conn)
  local st = P.PQresultStatus(res)
  if st == P.PGRES_EMPTY_QUERY then
    ret = true
  elseif st == P.PGRES_TUPLES_OK then
    local data = {}
    local n = P.PQnfields(res)
    local rows = P.PQntuples(res)

    local fname = {}
    for j=0, n-1 do
      table_insert(fname, ffi.string(P.PQfname(res, j)))
    end

    for i=0, rows-1 do
      local row = {}
      for j=0, n-1 do
        row[fname[j+1]] = ffi.string(P.PQgetvalue(res, i, j))
      end
      table_insert(data, row)
    end

    ret = {
      fieldnames = fname,
      resultset = data,
    }
  elseif st == P.PGRES_COPY_OUT or
    st == P.PGRES_COPY_IN or
    st == P.PGRES_COPY_BOTH or
    st == P.PGRES_COMMAND_OK then
    ret = true
  elseif st == P.PGRES_BAD_RESPONSE then
    err = "Server is speaking an alien language: " .. ffi.string(PQerrorMessage(conn))
  elseif st == P.PGRES_NONFATAL_ERROR or
    st == P.PGRES_FATAL_ERROR then
    err = "query failed: " .. ffi.string(P.PQerrorMessage(conn))
  else
    err = "shouldn't reach here"
  end
  P.PQclear(res)
  return ret, err
end

function pgsqlT:connect(conn_string)
  local conn = P.PQconnectStart(conn_string)
  if conn == nil then
    return nil, 'cannot allocate memory'
  end

  if not self._ioloop then
    self._ioloop = defaultIOLoop()
  end
  self._conn = conn
  self._fd = P.PQsocket(conn)
  if P.PQstatus(conn) == P.CONNECTION_BAD then
    local err = ffi.string(P.PQerrorMessage(conn))
    self:close()
    return nil, err
  end

  local state = 'out'
  self._ioloop:add_handler(self._fd, partial(_resume_me, coroutine.running()), state)
  local ret, err
  while true do
    coroutine.yield()
    local st = P.PQconnectPoll(conn)
    if st == P.PGRES_POLLING_WRITING then
      state = 'out'
    elseif st == P.PGRES_POLLING_READING then
      state = 'in'
    elseif st == P.PGRES_POLLING_OK then
      ret = true
      break
    elseif st == P.PGRES_POLLING_FAILED then
      err = ffi.string(P.PQerrorMessage(conn))
      break
    else
      err = "shouldn't reach here"
      break
    end
    self._ioloop:update_handler(self._fd, state)
  end
  if ret then
    self._ioloop:update_handler(self._fd, '')
  end

  if P.PQsetnonblocking(conn, 1) ~= 0 then
    ret = nil
    err = ffi.string(P.PQerrorMessage(conn))
  end
  return ret, err
end

function pgsqlT:query(q)
  -- on success, return someting true if no data is fetched back, or a list of
  -- table with fields "resultset" and "fieldnames"
  --
  -- on error, partial result is abandoned and err is set to a string descibing
  -- the one of the errors

  local conn = self._conn
  local ret, err
  local rt = P.PQsendQuery(conn, q)
  if rt ~= 1 then
    err = ffi.string(P.PQerrorMessage(conn))
    return ret, err
  end

  local res = {}
  self._ioloop:update_handler(self._fd, 'in')
  while true do
    local state
    coroutine.yield()
    if P.PQconsumeInput(conn) ~= 1 then
      err = ffi.string(P.PQerrorMessage(conn))
      break
    end

    local r
    while P.PQisBusy(conn) == 0 do
      -- returning 0 means we won't block
      r = P.PQgetResult(conn)
      if r == nil then
        -- query end, returned NULL
        break
      else
        table_insert(res, r)
      end
    end
    if r == nil then
      break
    end
  end
  self._ioloop:update_handler(self._fd, '')
  if err then
    return ret, err
  end

  ret = {}
  for _, v in ipairs(res) do
    local subret, suberr = _convert_results(v, conn)
    if suberr then
      err = suberr
      print(string_rep('=', 33) .. ' QUERY ERROR: ' .. string_rep('=', 33))
      print(suberr:sub(1, -2))
      print(string_rep('=', 80))
    else
      table_insert(ret, subret)
    end
  end
  if err then
    ret = nil
  end
  return ret, err
end

function pgsqlT:close()
  if self._fd >= 0 then
    self._ioloop:remove_handler(self._fd)
    self._fd = -1
  end
  if self._conn then
    P.PQfinish(self._conn)
    self._conn = nil
  end
end
