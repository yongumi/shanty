from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'
__all__ = ['example_handler']

from shanty.messages import *

########################################################################################################################

example_handler = MessageHandler('example')

@example_handler.handler('ping')
def ping(peer, message):
    peer.logger.debug('ping')
    peer.sendReply(Message(command='ping.reply'), message)
    return True

@example_handler.handler('echo')
def echo(peer, message):
    data = message.data
    if message.metadata and 'reverse' in message.metadata and message.metadata['reverse']:
        data = data[::-1]
    peer.sendReply(Message(command='echo.reply', metadata=message.metadata, data=data), message)
    return True
