#!/usr/bin/env python

__author__ = 'schwa'

import SocketServer
import struct
import json
import socket
import logging
import bonjour
import select
import errno
from twisted.internet.protocol import Protocol, ClientFactory, Factory
from sys import stdout
import datetime
import twbonjour
from twisted.internet.endpoints import TCP4ServerEndpoint
from twisted.internet import reactor
from twisted.internet.endpoints import TCP4ClientEndpoint

#import zlib
#import bencode
import snappy # pip install --user python-snappy

#__all__ = ['Client', 'Message', 'Peer', 'MessageCoder']

########################################################################################################################

FORMAT = '%(name)-6s | %(threadName)-10s | %(levelname)-5s | %(relativeCreated)5.0d | %(message)s'
logging.basicConfig(format=FORMAT, level=logging.DEBUG)
root_logger = logging.getLogger('')
server_logger = logging.getLogger('server')
client_logger = logging.getLogger('client')
unknown_logger = logging.getLogger('unknown')

########################################################################################################################

HEADER_FORMAT = '!HHL'
HEADER_SIZE = struct.calcsize(HEADER_FORMAT) # currently 8
CMD = 'cmd'
MSGID = 'msgid'

class ClosedError(EOFError):
    pass

########################################################################################################################

class IOBuffer(object):
    def __init__(self):
        self.buffer = ''
    def append(self, buffer):
        self.buffer += buffer
    def read(self, length):
        result = self.buffer[:length]
        self.buffer = self.buffer[length:]
        return result
    def __repr__(self):
        return 'IOBuffer(%d, [%s])' % (len(self.buffer), self.buffer)

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
            if CMD in self.control_data:
                raise Exception('Command already set in data')
            self.control_data[CMD] = command
        self.metadata = metadata
        self.data = data if data else ''

    def __repr__(self):
        return 'Message(%s, %s, %s)' % (self.control_data, self.metadata, self.data)

########################################################################################################################

class MessageHandler(object):

    def __init__(self):
        self.handlers = []

    def add_handler(self, condition, handler):
        self.handlers.append((condition, handler))

    def find_handler(self, message):
        for condition, handler in self.handlers:
            if isinstance(condition, str):
                if message.control_data[CMD] == condition:
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
        self.buffer = IOBuffer()
        self.handlers = []
        self.last_incoming_message_id = None
        self.next_outgoing_message_id = 0

    def connectionMade(self):
        if self.mode == 'CLIENT':
            self.sendHello()

    def dataReceived(self, data):
        self.buffer.append(data)
        while True:
            message = self.messageCoder.message_from_stream(self.buffer)
            if not message:
                break
            self.logger.debug('Received: %s', message)
            print 'XYZ'
            self.handle_message(self, message)

    def handle_message(self, peer, message):
        incoming_message_id = message.control_data[MSGID]
        next_incoming_msgid = self.last_incoming_message_id + 1 if self.last_incoming_message_id else 1
        if self.last_incoming_message_id and incoming_message_id != next_incoming_msgid:
            error = "Incoming message ids dont match (got %d expected %d)" % (incoming_message_id, next_incoming_msgid)
            self.logger.error(error)
#            raise Exception(error)
        self.last_incoming_message_id = incoming_message_id

        handler_function = self.handler.find_handler(message)

        if handler_function:
            handler_function(peer, message)
        else:
            self.logger.warning('No handler for %s' % message)


    def sendMessage(self, message):
        message = self.message_for_sending(message)
        self.logger.debug('Sending: %s', message)
        data = self.messageCoder.flatten_message(message)
        self.transport.write(data)

    def sendReply(self, message, in_reply_to):
        message.control_data['in-reply-to'] = in_reply_to.control_data[MSGID]
        self.sendMessage(message)

    def message_for_sending(self, message):
        control_data = dict(message.control_data)
        control_data[MSGID] = self.next_outgoing_message_id
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
    #def startedConnecting(self, connector):
    #    print 'Started to connect.'

    def __init__(self):
        self.handler = MessageHandler()
        self.handler.handlers = system_handler()

    def buildProtocol(self, addr):
        protocol = ShantyProtocol(mode = 'CLIENT')
        protocol.logger = client_logger
        protocol.handler = self.handler
        return protocol

########################################################################################################################

class ShantyServerFactory(Factory):

    def __init__(self):
        self.handler = MessageHandler()
        self.handler.handlers = system_handler()

    def buildProtocol(self, addr):
        #print 'Connected.'
        protocol = ShantyProtocol(mode = 'SERVER')
        protocol.logger = server_logger
        protocol.handler = self.handler
        return protocol

########################################################################################################################

def serve(type, name, domain = None, port = 0):
    endpoint = TCP4ServerEndpoint(reactor, 0)
    d = endpoint.listen(ShantyServerFactory())
    def my_endpoint(my_port):
        host, port = my_port.socket.getsockname()
        d = twbonjour.broadcast(reactor, type, port, name)
        #d.addCallback(client)
    d.addCallback(my_endpoint)
    reactor.run()

def client(type, name = None, domain = None, port = 0, message = None):
    def did_connect(protocol):
        protocol.sendMessage(message)
        reactor.callLater(2, reactor.stop)

    name, host, port = bonjour.browse_one(type = type)
    factory = ShantyClientFactory()
    endpoint = TCP4ClientEndpoint(reactor, host, port)
    d = endpoint.connect(factory)
    d.addCallback(did_connect)
    reactor.run()
