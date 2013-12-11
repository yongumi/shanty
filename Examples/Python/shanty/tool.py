"""shanty.

Usage:
  shanty send --dnssd-type=<type> --dump <command> [<data>]
  shanty serve --dnssd-type=<type> --dnssd-name=<name> [--port=<port>]
  shanty (-h | --help)
  shanty --version

Options:
  -h --help     Show this screen.
  --version     Show version.
"""

__author__ = 'schwa'

import docopt
#from docopt_cmd import cmd
import bonjour
import shanty
from shanty import *
import os

class Tool(object):
    def send(self):
        pass

def main(argv = None):
    arguments = docopt.docopt(__doc__, argv = argv, version='shanty 0.1d1')
    print arguments

    if arguments['send']:
#        name, host, port = bonjour.browse_one(type = arguments['--dnssd-type'])

        if arguments['--dump'] == True:
    #        name, host, port = bonjour.browse_one(type = arguments['--dnssd-type'])
            type = arguments['--dnssd-type']
    #        shanty.client(type, message =

            message = Message(command = arguments['<command>'], data = arguments['<data>'])
            def did_connect(protocol):
                protocol.sendMessage(message)
                pass

            def handle_snapshot(peer, message):
                print 'Snapshot received'

                if message.data:
                    path = os.path.join('/Users/schwa/Desktop/images', '%s.png' % message.control_data['msgid'])
                    open(path, 'w').write(message.data)

                if not message.control_data['more-coming']:
                    #reactor.stop()
                    pass

            name, host, port = bonjour.browse_one(type = type)
            factory = ShantyClientFactory()
            factory.handler.add_handler('snapshot.reply',handle_snapshot )

            endpoint = TCP4ClientEndpoint(reactor, host, port)
            d = endpoint.connect(factory)
            d.addCallback(did_connect)
            reactor.run()
        else:
            type = arguments['--dnssd-type']
            shanty.client(type, message = Message(command = arguments['<command>'], data = arguments['<data>']))
    elif arguments['serve']:
        type = arguments['--dnssd-type']
        name = arguments['--dnssd-name']
        port = int(arguments['--port'] if arguments['--port'] else 0)
        domain = ''
        shanty.serve(type, name, domain, port)


if __name__ == "__main__":
#    argv = ['serve', '--dnssd-type=_shanty._tcp', '--dnssd-name=Shanty_test']
    argv = ['send', '--dnssd-type=_stydebugtool._tcp', '--dump', 'snapshots']

    main(argv)
