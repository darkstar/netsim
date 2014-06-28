#!/usr/bin/python

import sys
import getopt

def usage():
  print 'Usage: inject -f <inputfile> -i <injectfile>'

def main(argv):
  diskfile = ''
  injectfile = ''
  fillchar = '#'

  try:
    opts, args = getopt.getopt(argv, "hf:i:c:", ["file=", "inject=", "fillchar="])
  except getopt.GetoptError:
    usage()
    sys.exit(2)

  for opt, arg in opts:
    if opt == '-h':
      usage()
      sys.exit()
    elif opt in ("-f", "--file"):
      diskfile = arg
    elif opt in ("-i", "--inject"):
      injectfile = arg
    elif opt in ("-c", "--fillchar"):
      fillchar = arg

  if diskfile == '' or injectfile == '':
    print "both -f and -i are required."
    sys.exit(1)
  if len(fillchar) > 1:
    print "fillchar must be exactly 1 byte"
    sys.exit(1)

  print 'Disk file is', diskfile
  print 'File to inject is', injectfile
  print 'Fill char is', fillchar

  searchbuffer = fillchar*1024

  with open(injectfile, "r") as replacementfile:
    replacement = replacementfile.read()

  if len(replacement) > 1024:
    print 'Error: replacement file cannot be larger than 1024 bytes'
    sys.exit(2)
  while len(replacement) < 1024:
    replacement = replacement + "#"

  if len(searchbuffer) != 1024:
    print 'Internal error: length is', len(searchbuffer), 'instad of 1024'
    sys.exit(2)

  with open(diskfile, "r+") as f:
    while True:
      pos = f.tell()
      chunk = f.read(1024)
      if chunk:
        # do something
        if len(chunk) == 1024:
          if chunk == searchbuffer:
            print 'Buffer found at position 0x' + format(pos,'08x')
            f.seek(pos)
            f.write(replacement)
      else:
        break

if __name__ == "__main__":
  main(sys.argv[1:])

