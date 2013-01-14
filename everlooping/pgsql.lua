#!/usr/bin/env luajit

local print = print
local setmetatable = setmetatable
local type = type
local ipairs = ipairs
local coroutine = coroutine
local table_insert = table.insert
local string_rep = string.rep

local tcppool = require('everlooping.tcppool')
local ioloop = require('everlooping.ioloop')
local defaultIOLoop = require('everlooping.ioloop').defaultIOLoop
local util = require('everlooping.util')
local parse = require('everlooping.pquriparse').parse
local partial = util.partial

local S = require('syscall')
local t, c = S.t, S.c
local ffi = require('ffi')

local oldassert = assert
function assert(c, s)
  return oldassert(c, tostring(s)) -- annoyingly, assert does not call tostring!
end

local _tostring = require('logging').tostring
local print = function(...)
  print(_tostring{...})
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

function pgsqlT:_get_conn_from_pool()
  if not tcppool.pool then
    return nil
  end
  return tcppool.pool:getout(self.key)
end

function _close_connection(conn, ioloop, fd)
  if fd >= 0 then
    ioloop:remove_handler(fd)
  end
  if conn then
    P.PQfinish(conn[1])
  end
end

function pgsqlT:connect(conn_string)
  if not self._ioloop then
    self._ioloop = defaultIOLoop()
  end
  self.key = conn_string

  local conn
  local o = self:_get_conn_from_pool(conn_string)
  if o then
    conn = o[1]
    print('resuing pgsql connection.', conn)
    tcppool.pool.ioloop:remove_timeout(o[2])
    conn._reused = conn._reused + 1
    self._conn = conn
    self._fd = P.PQsocket(conn[1])
    return true, nil
  end

  conn = P.PQconnectStart(parse(conn_string))
  if conn == nil then
    return nil, 'cannot allocate memory'
  end

  self._fd = P.PQsocket(conn)
  self._conn = {
    conn, _reused=0, 
    close = partial(_close_connection, self._conn, self._ioloop, self._fd),
  }
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
  -- on success, return something true if no data is fetched back, or a list of
  -- table with fields "resultset" and "fieldnames"
  --
  -- on error, partial result is abandoned and err is set to a string descibing
  -- the one of the errors

  local conn = self._conn[1]
  local ret, err
  local rt = P.PQsendQuery(conn, q)
  if rt ~= 1 then
    err = ffi.string(P.PQerrorMessage(conn))
    return ret, err
  end

  local res = {}
  self._ioloop:remove_handler(self._fd)
  self._ioloop:add_handler(self._fd, partial(_resume_me, coroutine.running()), 'in')
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

function pgsqlT:setkeepalive(timeout, size)
  self._keepalive = true
  if timeout == nil then
    timeout = tcppool.PoolT.defaultTimeout
  elseif timeout == 0 then
    timeout = 3600 * 24 * 365 -- 1 year
  else
    timeout = timeout / 1000 -- ms to s
  end
  if not tcppool.pool then
    tcppool.pool = tcppool.Pool(size)
  end
  local pool = tcppool.pool
  local timeout = pool.ioloop:add_timeout(
    pool.ioloop.time() + timeout, function()
      print('deleting because of timeout')
      pool:delete(self.key, self._conn)
    end)
  pool:put(self.key, self._conn, timeout)
  return 1
end

function pgsqlT:close()
  if self._keepalive then
    return
  end

  if self._fd >= 0 then
    self._ioloop:remove_handler(self._fd)
    self._fd = -1
  end
  if self._conn then
    P.PQfinish(self._conn[1])
    self._conn = nil
  end
end
