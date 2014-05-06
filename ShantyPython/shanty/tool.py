__author__ = 'schwa'

import click
import asyncio
import shanty

# @click.command()
# @click.option('--count', default=1, help='number of greetings')
# @click.option('--name', prompt='Your name',
#               help='the person to greet', required=True)
# def main(count, name):
#     for x in range(count):
#         click.echo('Hello %s!' % name)
#
# if __name__ == '__main__':
#     main()

b = shanty.Browser.browse_one('_io-schwa-prefstest._tcp.')
print b

loop = asyncio.get_event_loop()
c = shanty.Client(b.host, b.port)
loop.run_until_complete(c.open())

print('Connected')
c.protocol.sendMessage(shanty.Message(command='dbg.settings'))

loop.run_forever()
