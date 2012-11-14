#!/usr/bin/env python3
# vim:fileencoding=utf-8

import socket

s = socket.socket()
s.bind(('', 8000))
s.listen(2)

s2 = socket.socket()
s2.bind(('', 8001))
s2.listen(2)

try:
  while True:
    input('Press Enter to start accepting> ')
    sa, _ = s.accept()
    s2a, _ = s2.accept()

    input('Press Enter to start communication> ')
    print(sa.recv(1024))
    sa.send(b'Hello!\n' * 10)
    print(s2a.recv(1024))
    s2a.send(b'Hello!\n' * 10)
except KeyboardInterrupt:
  print()
