#!/usr/bin/env python2.6

import pylibmc
import sys
import uuid

progname = sys.argv[0].split('/')[-1]

if len(sys.argv) != 2:
    print >>sys.stderr, "usage: %s host:port" % progname
    sys.exit(1)

server = sys.argv[1]
mc = pylibmc.Client([server])

key = "nagios:%s" % (str(uuid.uuid1()),)
test_value = str(uuid.uuid1())

try:
    mc[key] = test_value
    set_value = mc[key]
    if set_value != test_value:
        print "CRITICAL: get %s should be %s, was %s" % \
              (key, test_value, set_value)
        sys.exit(2)
    del mc[key]
except pylibmc.Error as e:
    print "CRITICAL: pylibmc.Error (%d): %s" % (e.retcode, str(e))
    sys.exit(2)

print "OK: set/get/delete for key %s" % key
sys.exit(0)
