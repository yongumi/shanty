from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'

__all__ = ['ShantyProtocol', 'ServerProtocol', 'ClientProtocol', 'Server', 'Client', 'logger']

import datetime
import asyncio
from asyncio import From
import logging

from shanty.messages import *
from shanty.handlers import *

# TODO Put bonjour in here.

########################################################################################################################

FORMAT = '%(name)-15s | %(threadName)-10s | %(levelname)-7s | %(relativeCreated)5.0d | %(message)s'
logger = logging.getLogger('shanty')
_handler  = logging.StreamHandler()
_formatter = logging.Formatter(FORMAT)
_handler.setFormatter(_formatter)
logger.addHandler(_handler)
logger.setLevel(logging.DEBUG)

########################################################################################################################

class ShantyProtocol(asyncio.Protocol):
    def __init__(self):
        # TODO make this as light as possible.
        self.messageCoder = MessageCoder()
        self.last_incoming_message_id = None
        self.next_outgoing_message_id = 0
        self.messageBuilder = MessageBuilder()
        self.replyCallbacks = dict()
        # TODO Should handlers be in here or in server/client objects
        self.handlers = [ ]
        self.logger = logger

    def connection_made(self, transport):
        if not self.handlers:
            self.logger.warning('No handlers for protocol. This is probably not what you want')

        self.logger.debug('connection_made')
        self.transport = transport

    def connection_lost(self, exc):
        self.logger.debug('connection_lost')

    def data_received(self, data):
        self.messageBuilder.push_data(data)
        while self.messageBuilder.has_message():
            message = self.messageBuilder.pop_message()
            self.handle_message(self, message)

    def handle_message(self, peer, message):
        self.logger.debug('Routing message: %s' % message)

        incoming_message_id = message.control_data[CTL_MSGID]
        next_incoming_msgid = self.last_incoming_message_id + 1 if self.last_incoming_message_id else 1
        if self.last_incoming_message_id and incoming_message_id != next_incoming_msgid:
            error = 'Incoming message ids don\'t match (got %d expected %d)' % (
            incoming_message_id, next_incoming_msgid)
            logger.error(error)
            raise Exception(error)
        self.last_incoming_message_id = incoming_message_id

        if CTL_IN_REPLY_TO in message.control_data:
            if self.handle_reply(peer, message):
                return True

        for handler in self.handlers:
            handler_function = handler.find_handler(message)

            if handler_function:
                if handler_function(peer, message):
                    return True

        logger.warning('No message handler for %s' % message)
        return False

    def handle_reply(self, peer, message):
        in_reply_to = message.control_data[CTL_IN_REPLY_TO]
        if in_reply_to in self.replyCallbacks:
            callback = self.replyCallbacks[in_reply_to]
            callback(peer, message)
            del self.replyCallbacks[in_reply_to]
            return True
        else:
            return False

    # TODO make this callback mechanism more asyncio friendly
    def sendMessage(self, message, reply_callback=None):
        message = self._message_for_sending(message)
        if reply_callback:
            self.replyCallbacks[message.control_data[CTL_MSGID]] = reply_callback
        logger.debug('Sending: %s', message)
        data = self.messageCoder.flatten_message(message)
        self.transport.write(data)

    def sendReply(self, message, in_reply_to):
        message.control_data[CTL_IN_REPLY_TO] = in_reply_to.control_data[CTL_MSGID]
        self.sendMessage(message)

    def _message_for_sending(self, message):
        control_data = dict(message.control_data)
        control_data[CTL_MSGID] = self.next_outgoing_message_id
        self.next_outgoing_message_id += 1
        message.control_data = control_data
        return message

########################################################################################################################

server_handler = MessageHandler('server_side')

class ServerProtocol(ShantyProtocol):
    def __init__(self):
        super(ServerProtocol, self).__init__()
        self.handlers = [ server_handler ]

    # def connection_lost(self, exc):
    #     super(ServerProtocol, self).connection_lost(exc)

    @server_handler.handler('hello')
    def handle_hello(peer, message):
        peer.logger.debug('HELLO')
        peer.sendReply(Message(command='hello.reply'), message)
        return True

########################################################################################################################

client_handler = MessageHandler('client_side')

class ClientProtocol(ShantyProtocol):
    def __init__(self):
        super(ClientProtocol, self).__init__()
        self.handlers = [ client_handler ]

    def connection_made(self, transport):
        super(ClientProtocol, self).connection_made(transport)

        self.sendHello()

    def connection_lost(self, exc):
        super(ClientProtocol, self).connection_lost(exc)

    def sendHello(self):
        m = {
            'host': {
                'address': self.transport.get_extra_info('peername')[0],
                'port': self.transport.get_extra_info('peername')[1],
                'time': datetime.datetime.now().isoformat(),
            },
            'peer': {
                'address': self.transport.get_extra_info('sockname')[0],
                'port': self.transport.get_extra_info('sockname')[1],
            }
        }
        # TODO make this callback mechanism more asyncio friendly
        self.sendMessage((Message(command='hello', metadata=m)))

    @client_handler.handler('hello.reply')
    def handle_hello_reply(peer, message):
        peer.logger.debug('HELLO_REPLY')
        return True

########################################################################################################################

class Server(object):
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.handlers = []
        self.logger = logger.getChild('server')
        self._server = None

    @asyncio.coroutine
    def open(self, loop = None):

        def factory():
            self.logger.debug('Creating protocol')
            protocol = ServerProtocol()
#            protocol.handler.handlers += self.handlers
            protocol.logger = self.logger
            return protocol

        if not loop:
            loop = asyncio.get_event_loop()
        assert loop

        self.logger.debug('Creating server on %s %s', self.host, self.port)
        coro = loop.create_server(factory, self.host, self.port)
        self._server = yield From(coro)
        self.actual_host, self.actual_port = self._server.sockets[0].getsockname()

    def close(self):
        self._server.close()

########################################################################################################################

class Client(object):
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.logger = logger.getChild('server')
        self.handlers = []

    @asyncio.coroutine
    def open(self, loop = None):

        def factory():
            self.logger.debug('Creating protocol')
            protocol = ClientProtocol()
#            protocol.handler.handlers += self.handlers
            protocol.logger = self.logger
            return protocol

        if not loop:
            loop = asyncio.get_event_loop()
        assert loop

        self.logger.debug('Creating connection')
        coro = loop.create_connection(factory, self.host, self.port)
        self.transport, self.protocol = yield From(coro)
