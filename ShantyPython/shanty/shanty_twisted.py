from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'
__all__ = ['ShantyServerFactory', 'ShantyClientFactory', 'ClosedError', 'ShantyProtocol']

import datetime
from twisted.internet.protocol import Factory, ClientFactory
from twisted.internet.protocol import Protocol

from shanty.messages import *
from shanty.handlers import *
from shanty.main import *

# TODO Put bonjour in here.

########################################################################################################################

class ClosedError(EOFError):
    pass

########################################################################################################################

class ShantyProtocol(Protocol):
    def __init__(self, mode):
        self.mode = mode
        self.messageCoder = MessageCoder()
        self.logger = unknown_logger
        self.handlers = []
        self.last_incoming_message_id = None
        self.next_outgoing_message_id = 0
        self.messageBuilder = MessageBuilder()
        self.replyCallbacks = dict()

    def connectionMade(self):
        if self.mode == 'CLIENT':
            self.sendHello()

    #def connectionLost(self, reason):
    #    pass

    def dataReceived(self, data):
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
            in_reply_to = message.control_data[CTL_IN_REPLY_TO]
            if in_reply_to in self.replyCallbacks:
                callback = self.replyCallbacks[in_reply_to]
                callback(peer, message)

        handler_function = self.handler.find_handler(message)

        if handler_function:
            handler_function(peer, message)
        else:
            self.logger.warning('No message handler for %s' % message)

    def sendMessage(self, message, reply_callback = None):
        message = self.message_for_sending(message)
        self.logger.debug('Sending: %s', message)
        data = self.messageCoder.flatten_message(message)
        self.transport.write(data)
        if reply_callback:
            self.replyCallbacks[message.control_data[CTL_MSGID]] = reply_callback

    def sendReply(self, message, in_reply_to):
        message.control_data[CTL_IN_REPLY_TO] = in_reply_to.control_data[CTL_MSGID]
        self.sendMessage(message)

    def message_for_sending(self, message):
        control_data = dict(message.control_data)
        control_data[CTL_MSGID] = self.next_outgoing_message_id
        self.next_outgoing_message_id += 1
        message.control_data = control_data
        return message

    def sendHello(self):
        m = {
            'host': {
                'address': self.transport.getHost().host,
                'port': self.transport.getHost().port,
                'time': datetime.datetime.now().isoformat(),
                },
            'peer': {
                'address': self.transport.getPeer().host,
                'port': self.transport.getPeer().port,
                }
            }
        self.sendMessage((Message(command = 'hello', metadata = m)))

########################################################################################################################

class ShantyServerFactory(Factory):
    def __init__(self):
        self.handler = MessageHandler()
        self.handler.handlers = system_handler()

    def buildProtocol(self, addr):
        protocol = ShantyProtocol(mode = 'SERVER')
        protocol.logger = server_logger
        protocol.handler = self.handler
        return protocol

########################################################################################################################

class ShantyClientFactory(ClientFactory):

    def __init__(self):
        self.handler = MessageHandler()
        self.handler.handlers = system_handler()

    def buildProtocol(self, addr):
        protocol = ShantyProtocol(mode = 'CLIENT')
        protocol.logger = client_logger
        protocol.handler = self.handler
        return protocol

    def clientConnectionFailed(self, connector, reason):
        print('clientConnectionFailed', connector, reason)

    def clientConnectionLost(self, connector, reason):
        print('clientConnectionLost', connector, reason)
