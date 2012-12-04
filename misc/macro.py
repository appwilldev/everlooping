#!/usr/bin/env python3
# vim:fileencoding=utf-8

import sys
from myutils import safe_overwrite

def loadmacro(macrofile):
  ret = []
  with open(macrofile) as f:
    for l in f:
      ret.append(l.rstrip().split(None, 1))
  return ret

def replaceline(macros, line):
  for src, dest in macros:
    line = line.replace(src, dest)
  return line

def replaceFile(macro, file):
  lines = open(file).readlines()
  safe_overwrite(file, [replaceline(macro, l) for l in lines], method='writelines')

def main():
  macros = loadmacro('macro.txt')
  for f in sys.argv[1:]:
    replaceFile(macros, f)

if __name__ == '__main__':
  main()
