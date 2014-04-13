#!/usr/bin/env python

from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'

from twisted.internet import reactor
from twisted.internet.endpoints import TCP4ClientEndpoint, TCP4ServerEndpoint

from shanty.shanty_twisted import *
from shanty.messages import *

def server(port = 0):
    server_endpoint = TCP4ServerEndpoint(reactor, port)
    d = server_endpoint.listen(ShantyServerFactory())
    def my_endpoint(my_port):
        host, port = my_port.socket.getsockname()
        client(port = port)
    d.addCallback(my_endpoint)

def client(port):

    message = Message(command = 'YO')

    def did_connect(protocol):
        #message.control_data['close'] = True
        protocol.sendMessage(message)

    factory = ShantyClientFactory()
    #factory.handler.add_handler('snapshot.reply', handle_snapshot)

    endpoint = TCP4ClientEndpoint(reactor, '', port)
    d = endpoint.connect(factory)
    d.addCallback(did_connect)

server()

reactor.run()
