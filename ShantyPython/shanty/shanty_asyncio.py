from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'
__all__ = ['ClosedError', 'ShantyProtocol', 'Server', 'Client']

import datetime
import asyncio

from shanty.messages import *
from shanty.handlers import *
from shanty.main import *

# TODO Put bonjour in here.

########################################################################################################################

class ClosedError(EOFError):
    pass

########################################################################################################################

class ShantyProtocol(asyncio.Protocol):
    def __init__(self):
        self.messageCoder = MessageCoder()
        self.logger = unknown_logger
        self.last_incoming_message_id = None
        self.next_outgoing_message_id = 0
        self.messageBuilder = MessageBuilder()
        self.replyCallbacks = dict()
        self.handler = MessageHandler()
        self.handler.handlers = system_handler()

    def connection_made(self, transport):
        self.transport = transport

    def connection_lost(self, exc):
       pass

    def data_received(self, data):
        self.messageBuilder.push_data(data)
        while self.messageBuilder.has_message():
            message = self.messageBuilder.pop_message()
            self.logger.debug('Received: %s', message)
            self.handle_message(self, message)

    def handle_message(self, peer, message):
        incoming_message_id = message.control_data[CTL_MSGID]
        next_incoming_msgid = self.last_incoming_message_id + 1 if self.last_incoming_message_id else 1
        if self.last_incoming_message_id and incoming_message_id != next_incoming_msgid:
            error = 'Incoming message ids don\'t match (got %d expected %d)' % (incoming_message_id, next_incoming_msgid)
            self.logger.error(error)
            raise Exception(error)
        self.last_incoming_message_id = incoming_message_id

        if CTL_IN_REPLY_TO in message.control_data:
            self.handle_reply(peer, message)
            return

        handler_function = self.handler.find_handler(message)

        if handler_function:
            handler_function(peer, message)
        else:
            self.logger.warning('No message handler for %s' % message)

    def handle_reply(self, peer, message):
        in_reply_to = message.control_data[CTL_IN_REPLY_TO]
        if in_reply_to in self.replyCallbacks:
            callback = self.replyCallbacks[in_reply_to]
            callback(peer, message)

    def sendMessage(self, message, reply_callback = None):
        message = self._message_for_sending(message)
        self.logger.debug('Sending: %s', message)
        data = self.messageCoder.flatten_message(message)
        self.transport.write(data)
        if reply_callback:
            self.replyCallbacks[message.control_data[CTL_MSGID]] = reply_callback

    def sendReply(self, message, in_reply_to):
        message.control_data[CTL_IN_REPLY_TO] = in_reply_to.control_data[CTL_MSGID]
        self.sendMessage(message)

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
        self.sendMessage((Message(command = 'hello', metadata = m)))

    def _message_for_sending(self, message):
        control_data = dict(message.control_data)
        control_data[CTL_MSGID] = self.next_outgoing_message_id
        self.next_outgoing_message_id += 1
        message.control_data = control_data
        return message

########################################################################################################################

class ServerProtocol(ShantyProtocol):
    def __init__(self):
        super(ServerProtocol, self).__init__()
        self.logger = server_logger
        print(self.handler.handlers)
        self.handler.handlers.insert(0, ('hello', self.handle_hello))

    def connection_lost(self, exc):
        print('CONNECTION LOST')
        print(asyncio.get_event_loop())

    def handle_hello(self, peer, message):
        print('HELLO!!!!')
        self.sendReply(Message(command = 'hello.reply'), message)
        print(asyncio.get_event_loop())
        asyncio.get_event_loop().close()



########################################################################################################################

class ClientProtocol(ShantyProtocol):
    def __init__(self):
        super(ClientProtocol, self).__init__()
        self.logger = client_logger

    def connection_made(self, transport):
        super(ClientProtocol, self).connection_made(transport)
        self.sendHello()

########################################################################################################################

class Server(object):
    def __init__(self, host, port):
        self.host = host
        self.port = port

    def open(self, loop):
        coro = loop.create_server(ServerProtocol, self.host, self.port)
        self.server = loop.run_until_complete(coro)
        print(self.server)

    def close(self):
        self.server.close()

class Client(object):
    def __init__(self, host, port):
        self.host = host
        self.port = port

    def open(self, loop):
        coro = loop.create_connection(ClientProtocol, self.host, self.port)
        self.transport, self.protocol = loop.run_until_complete(coro)
        print(self.transport)
        print(self.protocol)
