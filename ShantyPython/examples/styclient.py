from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

__author__ = 'schwa'

import trollius as asyncio
import shanty
from shanty.shanty_asyncio import Client, ClientProtocol
import click

@click.command()
@click.argument('host', default='127.0.0.1')
@click.argument('port', default=8888)
def run(host, port):
    c = Client(host, port)
    c.open()
    try:
        loop = asyncio.get_event_loop()
        loop.run_forever()
    finally:
        c.close()
        loop.close()

if __name__ == '__main__':
    run()

#################

