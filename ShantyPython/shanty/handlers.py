from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'
__all__ = ['system_handler']

from shanty.messages import *


def system_handler():
    def handle_ping(peer, message):
        peer.sendReply(Message(command='ping.reply'), message)

    def handle_echo(peer, message):
        data = message.data
        if message.metadata and 'reverse' in message.metadata and message.metadata['reverse']:
            data = data[::-1]
        peer.sendReply(Message(command='echo.reply', metadata=message.metadata, data=data), message)

    def handle_hello(peer, message):
        peer.sendReply(Message(command='hello.reply'), message)

    def print_message(peer, message):
        peer.logger.info('%s' % message)

    def nop(peer, message):
        pass

    handlers = [
        ('hello', handle_hello),
        ('hello.reply', print_message),
        ('ping', handle_ping),
        ('ping.reply', print_message),
        ('echo', handle_echo),
        ('echo.reply', print_message),
    ]

    return handlers
