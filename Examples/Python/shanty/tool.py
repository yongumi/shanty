"""shanty.

Usage:
  shanty send --dnssd-type=<type> <command> [<data>]
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

class Tool(object):
    def send(self):
        pass

def main(argv = None):
    arguments = docopt.docopt(__doc__, argv = argv, version='shanty 0.1d1')

    if arguments['send']:
#        name, host, port = bonjour.browse_one(type = arguments['--dnssd-type'])
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
    argv = ['send', '--dnssd-type=_schwa._tcp', 'echo', 'Hello world']

    main(argv)
