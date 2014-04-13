#!/usr/bin/env python

from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'

import asyncio

from shanty.shanty_asyncio import *
from shanty.messages import *
from shanty.main import *
from shanty.handlers import *

def server(loop, port = 0):
    def factory():
        p = ShantyProtocol(mode = MODE_SERVER)
        p.logger = server_logger
        p.handler = MessageHandler()
        p.handler.handlers = system_handler()
        return p

    loop = asyncio.get_event_loop()
    coro = loop.create_server(factory, '127.0.0.1', 8888)
    s = loop.run_until_complete(coro)
    print(s)
    print('serving on {}'.format(s.sockets[0].getsockname()))
    return s

#################

def client(loop):
    def factory():
        p = ShantyProtocol(mode = MODE_CLIENT)
        p.logger = client_logger
        p.handler = MessageHandler()
        p.handler.handlers = system_handler()
        return p
    coro = loop.create_connection(factory, '127.0.0.1', 8888)
    loop.run_until_complete(coro)

#################

loop = asyncio.get_event_loop()
s = server(loop)
client(loop)
try:
    loop.run_forever()
except KeyboardInterrupt:
    print("exit")
finally:
    s.close()
    loop.close()


# def client(port):
#
#     message = Message(command = 'YO')
#
#     def did_connect(protocol):
#         #message.control_data['close'] = True
#         protocol.sendMessage(message)
#
#     factory = ShantyClientFactory()
#     #factory.handler.add_handler('snapshot.reply', handle_snapshot)
#
#     endpoint = TCP4ClientEndpoint(reactor, '', port)
#     d = endpoint.connect(factory)
#     d.addCallback(did_connect)

server(loop)

