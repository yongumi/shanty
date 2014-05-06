#!/usr/bin/env python

from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'

import asyncio

from shanty.shanty_asyncio import *

#################

loop = asyncio.get_event_loop()
s = Server('127.0.0.1', 8888)
s.open(loop)
print('serving on {}'.format(s.server.sockets[0].getsockname()))

c = Client('127.0.0.1', 8888)
c.open(loop)

try:
    loop.run_forever()
finally:
    s.close()

    loop.close()
