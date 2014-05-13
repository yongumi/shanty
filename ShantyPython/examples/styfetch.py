"""styfetch.

Usage:
  styfetch
  styfetch (-h | --help)
  styfetch --version

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

import os

def fetch(arguments):

    def handle_dictionary(peer, message):
        name = message.metadata['Filename']
        d = os.path.split(name)[0]
        if not os.path.exists(d):
            os.makedirs(d)
        file(name, 'w').write(message.data)


    def handle_done(peer, message):
        print message.control_data
        print 'Done received'
        #reactor.callLater(1, reactor.stop)
        reactor.stop()

    def did_connect(protocol):
        message = Message(command = 'io.schwa.inspect-ui', metadata = None, data = None)
        protocol.sendMessage(message)

    type = '_io-schwa-inspect-ui._tcp' # arguments['--dnssd-type']
    name, host, port = stybonjour.browse_one(type = type)

    factory = ShantyClientFactory()
    factory.handler.add_handler('io.schwa.view-dictionary', handle_dictionary)
    factory.handler.add_handler('io.schwa.view-snapshot', handle_dictionary)
    factory.handler.add_handler('done', handle_done)

    endpoint = TCP4ClientEndpoint(reactor, host, port)
    d = endpoint.connect(factory)
    d.addCallback(did_connect)

    reactor.run()


def main(argv = None):
    arguments = docopt.docopt(__doc__, argv = argv, version='shanty 0.1d1')
    fetch(arguments)

if __name__ == "__main__":
#    argv = ['serve', '--dnssd-type=_shanty._tcp', '--dnssd-name=Shanty_test']
#     print sys.argv
#    sys.argv = [sys.argv[0], 'Hello world']
    shanty()
