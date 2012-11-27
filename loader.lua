#!/usr/bin/env luajit

ngx = require('ngx')

ngx.var = {
  MOOCHINE_APP_PATH = '/home/lilydjwg/src/moochine-demo',
  MOOCHINE_APP_NAME = 'test',
  REQUEST_URI = '/hello?name=abcdef',
  request_method = 'GET',
}

ngx.req = {
  get_headers = function()
    return {}
  end,
  get_uri_args = function()
    return {
      name = 'abcdef',
    }
  end,
}

assert(loadfile(arg[1]))()

print('Headers:')
for k, v in pairs(ngx.header) do
  print(k .. ': ' .. v)
end
