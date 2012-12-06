#!/usr/bin/env lua

strutil = require('datautil.string')
F = require('datautil.functional')
parse = require('everlooping.pquriparse').parse

uris = [[
postgresql://postgres@localhost:5432/postgres
postgresql://postgres@localhost/postgres
postgresql://localhost:5432/postgres
postgresql://localhost/postgres
postgresql://postgres@localhost:5432/
postgresql://postgres@localhost/
postgresql://localhost:5432/
postgresql://localhost:5432
postgresql://localhost/postgres
postgresql://localhost/
postgresql://localhost
postgresql:///
postgresql://
postgresql://%6Cocalhost/
postgresql://localhost/postgres?user=postgres
postgresql://localhost/postgres?user=postgres&port=5432
postgresql://localhost/postgres?user=postgres&port=5432
postgresql://localhost:5432?user=postgres
postgresql://localhost?user=postgres
postgresql://localhost?uzer=
postgresql://localhost?
postgresql://[::1]:5432/postgres
postgresql://[::1]/postgres
postgresql://[::1]/
postgresql://[::1]
postgres://

postgres://postgres:@localhost/testdb
]]

F.each(strutil.split(uris), function(i)
  print('>>', i, '>>>', parse(i))
end)
