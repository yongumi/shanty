"""shanty.

Usage:
  shanty --dnssd-type=<type> send <command> [<data>]
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
from shanty import (Client, Message)

class Tool(object):
    def send(self):
        pass

def main(argv = None):
    arguments = docopt.docopt(__doc__, argv = argv, version='shanty 0.1d1')
#    print(arguments)

    name, host, port = bonjour.browse_one(type = arguments['--dnssd-type'])
    c = Client(host, port)
    c.peer.send(Message(command = arguments['<command>'], data = arguments['<data>']))

if __name__ == "__main__":
    main()
