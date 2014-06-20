__author__ = 'schwa'

import sys
import shlex
import logging

import click
import trollius as asyncio

import shanty

from utilities import *

logger = shanty.logger.getChild('tool')

########################################################################################################################

@click.group()
def main(*args, **kwargs):
    if args:
        click.echo(args)
    if kwargs:
        click.echo(kwargs)

@click.command()
@click.option('--host', type=click.STRING, default = '')
@click.option('--port', type=click.INT, default = 0, help = 'Port to serve on, 0 for random port')
@click.option('--type', type=REGEX(pattern = '^_[A-Za-z-]+\._(tcp|udp)\.$'), help = 'DNS-SD type (of form _XXX._tcp.')
@click.option('--name', type=click.STRING, help = 'DNS-SD name')
@click.option('--alive', type=click.INT, default = 0, help = 'Number of seconds to keep server running')
def serve(host, port, name, type, alive):

    # FORMAT = '%(name)-15s | %(threadName)-10s | %(levelname)-7s | %(relativeCreated)5.0d | %(message)s'
    # logging.basicConfig(format = FORMAT, level = logging.DEBUG)

    loop = asyncio.get_event_loop()
    server = shanty.Server(host, port)
    loop.run_until_complete(server.open())

    logger.debug('Listening on %s:%s' % (server.actual_host, server.actual_port))

    if not type and name:
        # TODO convert name into type
        type = '_%s._tcp.' % (name)
    if type and not name:
        # TODO convert type into name
        name = 'Untitled %s' % type
    if type and name:
        advertiser = shanty.Advertiser(name, type, server.actual_port)
        advertiser.start()
        logger.debug('Advertising service called \'%s\' of type \'%s\'' % (name, type))

    if alive > 0:
        def die():
            logger.debug('Dying after alive time')
            sys.exit(0)
        logger.debug('Scheduling server to die after %d seconds' % (alive))
        loop.call_later(alive, die)

    loop.run_forever()

    logger.debug('Exited loop')

main.add_command(serve)

########################################################################################################################

@click.command()
@click.option('--type', type=REGEX(pattern = '^_[A-Za-z-]+\._(tcp|udp)\.$'), help = 'DNS-SD type (of form _XXX._tcp.')
@click.option('--name')
@click.option('--host')
@click.option('--port')
@click.option('--first-service', '--first', is_flag=True)
@click.option('--command')
def message(type, name, host, port, first, command):

    if first:
        logger.debug('Looking for service')
        service = shanty.Browser.browse_one(type)
        host = service.host
        port = service.port

    logger.debug('Found service: %s' % (str(service)))

    loop = asyncio.get_event_loop()
    client = shanty.Client(host, port)
    loop.run_until_complete(client.open())

    if command:
        logger.debug('Connected. Sending command: %s', command)
        client.protocol.sendMessage(shanty.Message(command=command))

    loop.run_forever()
    logger.debug('Exited loop')

main.add_command(message)

########################################################################################################################

if __name__ == '__main__':

    #sys.argv = sys.argv[:1] + shlex.split('message --type=_test._tcp. --first --command=yo')
    sys.argv = sys.argv[:1] + shlex.split('serve --name=test')
    main()

