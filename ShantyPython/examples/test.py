__author__ = 'schwa'

import asyncio
import shanty

b = shanty.Browser.browse_one('_io-schwa-prefstest._tcp.')
print b

loop = asyncio.get_event_loop()
c = shanty.Client(b.host, b.port)
loop.run_until_complete(c.open())

print('Connected')
c.protocol.sendMessage(shanty.Message(command='dbg.settings'))

loop.run_forever()
