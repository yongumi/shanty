"""stylog.

Usage:
  stylog <message>
  stylog (-h | --help)
  stylog --version

Options:
  -h --help     Show this screen.
  --version     Show version.
"""

__author__ = 'schwa'

import docopt
import os
import sys

from twisted.internet import reactor
from twisted.internet.endpoints import TCP4ClientEndpoint

from shanty import *

def send(arguments):

    # command = arguments['--command']
    # metdata= json.loads(arguments['--metadata']) if arguments['--metadata'] else None
    # data = arguments['--data']
    # if arguments['--datafile']:
    #     data = file(arguments['--datafile']).read()

    message = Message(command = 'log', metadata = None, data = arguments['<message>'])

    def did_connect(protocol):
        message.control_data['close'] = True
        protocol.sendMessage(message)
        reactor.callLater(1, reactor.stop)

    type = '_io-schwa-stylog._tcp' # arguments['--dnssd-type']
    name, host, port = stybonjour.browse_one(type = type)

    factory = ShantyClientFactory()

    endpoint = TCP4ClientEndpoint(reactor, host, port)
    d = endpoint.connect(factory)
    d.addCallback(did_connect)

    reactor.run()


def main(argv = None):
    arguments = docopt.docopt(__doc__, argv = argv, version='shanty 0.1d1')
    send(arguments)

if __name__ == "__main__":
#    argv = ['serve', '--dnssd-type=_shanty._tcp', '--dnssd-name=Shanty_test']
#     print sys.argv
#    sys.argv = [sys.argv[0], 'Hello world']
    shanty()
