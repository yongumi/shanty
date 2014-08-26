from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

__author__ = 'schwa'

import trollius as asyncio
import sys

from shanty.shanty_asyncio import *

#################

loop = asyncio.get_event_loop()
loop.call_later(120, sys.exit)

server = Server('127.0.0.1', 8888)
server.open(loop)

try:
    loop.run_forever()
finally:
    server.close()
    loop.close()
