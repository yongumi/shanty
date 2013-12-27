"""shanty.

Usage:
  shanty send --dnssd-type=<type> [--dump] --command=<command> [--metadata=<metadata>] [--data=<data>]
  shanty serve --dnssd-type=<type> --dnssd-name=<name> [--port=<port>]
  shanty (-h | --help)
  shanty --version

Options:
  -h --help     Show this screen.
  --version     Show version.
"""

__author__ = 'schwa'

import docopt
import os

from twisted.internet import reactor
from twisted.internet.endpoints import TCP4ServerEndpoint
from twisted.internet.endpoints import TCP4ClientEndpoint

import bonjour
from shanty import *

#from docopt_cmd import cmd

#class Tool(object):
#    def send(self):
#        pass

def send(arguments):

    command = arguments['--command']
    metdata= json.loads(arguments['--metadata'])
    data = arguments['--data']

    message = Message(command = command, metadata = metdata, data = data)

    def did_connect(protocol):
        #message.control_data['close'] = True
        protocol.sendMessage(message)
        if not arguments['--dump']:
            reactor.callLater(1, reactor.stop)

    def handle_snapshot(peer, message):
        print 'Snapshot received'

        if message.data:
            path = os.path.join('/Users/schwa/Desktop/images', '%s.png' % message.control_data['msgid'])
            open(path, 'w').write(message.data)

        if not message.control_data['more-coming']:
            reactor.stop()

    type = arguments['--dnssd-type']
    name, host, port = bonjour.browse_one(type = type)

    print name, host, port


    factory = ShantyClientFactory()
    factory.handler.add_handler('snapshot.reply', handle_snapshot)

    endpoint = TCP4ClientEndpoint(reactor, host, port)
    d = endpoint.connect(factory)
    d.addCallback(did_connect)

    reactor.run()

def serve(arguments):
    type = arguments['--dnssd-type']
    name = arguments['--dnssd-name']
    port = int(arguments['--port'] if arguments['--port'] else 0)
    domain = ''

    endpoint = TCP4ServerEndpoint(reactor, 0)
    d = endpoint.listen(ShantyServerFactory())
    def my_endpoint(my_port):
        host, port = my_port.socket.getsockname()
        d = twbonjour.broadcast(reactor, type, port, name)
        #d.addCallback(client)
    d.addCallback(my_endpoint)
    reactor.run()


def main(argv = None):
    arguments = docopt.docopt(__doc__, argv = argv, version='shanty 0.1d1')
    #print arguments

    if arguments['send']:
        send(arguments)
    elif arguments['serve']:
        serve(arguments)

if __name__ == "__main__":
#    argv = ['serve', '--dnssd-type=_shanty._tcp', '--dnssd-name=Shanty_test']
#    argv = ['send', '--dnssd-type=_stydebugtool._tcp', '--dump', 'snapshots']

    main()
