#!/usr/bin/env python

__author__ = 'schwa'

import struct
import json
import logging
import datetime

from twisted.internet.protocol import Protocol, ClientFactory, Factory

#import zlib
#import bencode
import snappy # pip install --user python-snappy

#__all__ = ['Client', 'Message', 'Peer', 'MessageCoder']

# TODO Put bonjour in here.

########################################################################################################################

# TODO Use twisted logging with py logging framework
FORMAT = '%(name)-6s | %(threadName)-10s | %(levelname)-5s | %(relativeCreated)5.0d | %(message)s'
logging.basicConfig(format=FORMAT, level=logging.DEBUG)
root_logger = logging.getLogger('')
server_logger = logging.getLogger('server')
client_logger = logging.getLogger('client')
unknown_logger = logging.getLogger('unknown')

########################################################################################################################

CTL_CMD = 'cmd'
CTL_MSGID = 'msgid'
CTL_IN_REPLY_TO = 'in-reply-to'
CTL_MORE_COMING = 'more-coming'
CTL_CLOSE = 'close'

########################################################################################################################

CMD_HELLO = 'hello'
CMD_HELLO_REPLY = 'hello.reply'
CMD_PING = 'ping'
CMD_PING_REPLY = 'ping.reply'
CMD_ECHO = 'echo'
CMD_ECHO_REPLY = 'echo.reply'

########################################################################################################################

HEADER_FORMAT = '!HHL'
HEADER_SIZE = struct.calcsize(HEADER_FORMAT) # currently 8

########################################################################################################################

class ClosedError(EOFError):
    pass

########################################################################################################################

# TODO work better with MessageCode
class MessageBuilder(object):
    def __init__(self):
        self.data = ''
        self.header = None
        self.coder = MessageCoder()
    def push_data(self, data):
        self.data += data
    def has_message(self):
        if len(self.data) <= HEADER_SIZE:
            return False
#        print len(self.data), HEADER_SIZE
        control_data_size, metadata_size, data_size = struct.unpack(HEADER_FORMAT, self.data[0:HEADER_SIZE])
        size_needed = HEADER_SIZE + control_data_size + metadata_size + data_size
        if len(self.data) < size_needed:
            return False
        return True

    def read(self, length):
        result = self.data[:length]
        self.data = self.data[length:]
        return result

    def pop_message(self):
        if len(self.data) < HEADER_SIZE:
            raise EOFError()
        data = self.read(HEADER_SIZE)
        control_data_size, metadata_size, data_size = struct.unpack(HEADER_FORMAT, data)

        control_data_data = self.read(control_data_size)
        if len(control_data_data) != control_data_size:
            raise EOFError()
        control_data = self.coder.decode(control_data_data)

        if metadata_size > 0:
            metadata_data = self.read(metadata_size)
            if len(metadata_data) != metadata_size:
                raise EOFError()
            metadata = self.coder.decode(metadata_data)
        else:
            metadata = None

        data = self.read(data_size)
        if len(data) != data_size:
            raise Exception('data size mismatch (expected %s got %s' % (data_size, len(data)))

        message = Message(control_data = control_data, metadata = metadata, data = data)
        return message

########################################################################################################################

class MessageCoder(object):

    def flatten_message(self, message):
        control_data_data = self.encode(message.control_data)
        metadata_data = self.encode(message.metadata) if message.metadata else ''
        data = message.data if message.data else ''
        format = HEADER_FORMAT + '%ss%ss%ss' % (len(control_data_data), len(metadata_data), len(data))
        flattened_message = struct.pack(format, len(control_data_data), len(metadata_data), len(data), control_data_data, metadata_data, data)
        return flattened_message

    def message_from_stream(self, s):
        header_data = s.read(HEADER_SIZE)
        if len(header_data) != HEADER_SIZE:
            s.append(header_data)
            return False
        control_data_size, metadata_size, data_size = struct.unpack(HEADER_FORMAT, header_data)
        control_data_data = s.read(control_data_size)
        if len(control_data_data) != control_data_size:
            raise EOFError()
        control_data = self.decode(control_data_data)

        if metadata_size > 0:
            metadata_data = s.read(metadata_size)
            if len(metadata_data) != metadata_size:
                raise EOFError()
            metadata = self.decode(metadata_data)
        else:
            metadata = None

        data = s.read(data_size)
        if len(data) != data_size:
            raise Exception('data size mismatch (expected %s got %s' % (data_size, len(data)))

        message = Message(control_data = control_data, metadata = metadata, data = data)
        return message

    def encode(self, obj):
        return json.dumps(obj)

    def decode(self, data):
        return json.loads(data)

    def compress(self, data):
        return data

    def decompress(self, data):
        return data

########################################################################################################################

class Message(object):
    def __init__(self, control_data = None, metadata = None, data = None, command = None, ):
        self.control_data = control_data if control_data else {}
        if command:
            if CTL_CMD in self.control_data:
                raise Exception('Command already set in data')
            self.control_data[CTL_CMD] = command
        self.metadata = metadata
        self.data = data if data else ''

    def __repr__(self):
        return 'Message(%s, %s, %s bytes \'%s\')' % (self.control_data, self.metadata, len(self.data), self.data if len(self.data) < 64 else self.data[:64])

########################################################################################################################

class MessageHandler(object):

    def __init__(self):
        self.handlers = []

    def add_handler(self, condition, handler):
        self.handlers.append((condition, handler))

    def find_handler(self, message):
        for condition, handler in self.handlers:
            if isinstance(condition, str):
                if message.control_data[CTL_CMD] == condition:
                    return handler
            elif condition(message):
                return handler
        return None

########################################################################################################################

def system_handler():
    def handle_ping(peer, message):
        peer.sendReply(Message(command = 'ping.reply'), message)

    def handle_echo(peer, message):
        data = message.data
        if message.metadata and 'reverse' in message.metadata and message.metadata['reverse']:
            data = data[::-1]
        peer.sendReply(Message(command = 'echo.reply', metadata = message.metadata, data = data), message)

    def handle_hello(peer, message):
        peer.sendReply(Message(command = 'hello.reply'), message)

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
            callback = self.replyCallbacks[in_reply_to]
            callback(peer, message)

        handler_function = self.handler.find_handler(message)

        if handler_function:
            handler_function(peer, message)

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
        print 'clientConnectionFailed', connector, reason

    def clientConnectionLost(self, connector, reason):
        print 'clientConnectionLost', connector, reason

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

#def clientConnectionLost(self, connector, reason):
#    pass

#def clientConnectionFailed(self, connector, reason):
#    pass

#def startedConnecting(self, connector):
#    print 'Started to connect.'

#def startFactory(self):
#    pass

#def stopFactory(self):
#    pass
