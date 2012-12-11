#!/usr/bin/env luajit

function assertEqual(a, b, msg)
  if a ~= b then
    error('expected ' .. tostring(b) .. ', but got ' .. tostring(a))
  end
end

pcre = require('everlooping.pcre')

assertEqual(pcre.match('test', 'e\\w+')[0], 'est')
assertEqual(pcre.match('test', 'e(\\w+)')[0], 'est')
assertEqual(pcre.match('test', 'E(\\w+)'), nil)
assertEqual(pcre.match('test', 'E(\\w+)', 'i')[0], 'est')
assertEqual(pcre.sub('test', 't', 'T'), 'Test')
assertEqual(pcre.gsub('test', 't', 'T'), 'TesT')
assertEqual(pcre.gsub('test this that hello abc', '\\bt(\\w)\\w+', 'T$1$0'), 'Tetest Ththis Ththat hello abc')
