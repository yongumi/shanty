#!/usr/bin/env python

__author__ = 'schwa'

import SocketServer
import struct
import json
import socket
import threading
import logging
import time

#import zlib
#import bencode
import snappy # pip install --user python-snappy

__all__ = ['Client', 'Message', 'Peer', 'MessageCoder']

########################################################################################################################

logging.basicConfig(format=FORMAT, level=logging.DEBUG)
server_logger = logging.getLogger('SERVER')
client_logger = logging.getLogger('CLIENT')
#server_logger.warning('Protocol problem')
#client_logger.warning('Protocol problem')

HEADER_FORMAT = '!HHL'
HEADER_SIZE = struct.calcsize(HEADER_FORMAT) # currently 8
FORMAT = '%(name)s@%(relativeCreated)d:%(message)s'
#control_data_SIZE = 32
#DATA_SIZE = 32
CMD = 'cmd'
MSGID = 'msgid'

class ClosedError(EOFError):
    pass

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
        header_data = s.recv(HEADER_SIZE)
        if not header_data:
            raise ClosedError()
        control_data_size, metadata_size, data_size = struct.unpack(HEADER_FORMAT, header_data)
        control_data_data = s.recv(control_data_size)
        if len(control_data_data) != control_data_size:
            raise EOFError()
        control_data = self.decode(control_data_data)

        if metadata_size > 0:
            metadata_data = s.recv(metadata_size)
            if len(metadata_data) != metadata_size:
                raise EOFError()
            metadata = self.decode(metadata_data)
        else:
            metadata = None

        data = s.recv(data_size)
        if len(data) != data_size:
            raise Exception('data size mismatch')

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

class Peer(object):
    def __init__(self, stream):
        self.stream = stream
        self.last_incoming_message_id = None
        self.next_outgoing_message_id = 0
        self.handlers = []
        self.messageCoder = MessageCoder()

    def send(self, message):
        control_data = dict(message.control_data)
        control_data[MSGID] = self.next_outgoing_message_id
        self.next_outgoing_message_id += 1
        message.control_data[MSGID] = self.next_outgoing_message_id
        data = self.messageCoder.flatten_message(message)
        self.stream.sendall(data)

    def recv(self):
        message = self.messageCoder.message_from_stream(self.stream)
        self.handle_message(message)
        return message

    def handle_message(self, message):
        incoming_message_id = message.control_data[MSGID]
        if self.last_incoming_message_id and incoming_message_id != self.last_incoming_message_id + 1:
            raise Exception("Incoming message ids dont match.")
        self.last_incoming_message_id = incoming_message_id

        handled = False
        for handlers in [self.system_handlers, self.handlers]:
            handler = self.find_handler(handlers, message)
            if handler:
                handler(self, message)
                handled = True
                break

        if not handled:
            print 'No handler for:', message

    def add_handler(self, condition, handler):
        self.handlers.append((condition, handler))

    def find_handler(self, handlers, message):
        for condition, handler in handlers:
            if isinstance(condition, str):
                if message.control_data[CMD] == condition:
                    return handler
            elif condition(message):
                return handler
        return None

    @property
    def system_handlers(self):
        if not hasattr(self, '_system_handlers'):
            def handle_ping(peer, message):
                peer.send(Message({ CMD: 'PONG', 'in-response-to': message.control_data[MSGID] }))

            def handle_echo(peer, message):
                peer.send(Message({ CMD: 'ECHO_RESPONSE', 'in-response-to': message.control_data[MSGID] }, message.metadata, message.data))

            def handle_hello(peer, message):
                peer.send(Message({ CMD: 'HELLO_RESPONSE', 'in-response-to': message.control_data[MSGID] }, message.metadata, message.data))

            def print_message(peer, message):
                print message

            self._system_handlers = [
                ('PING', handle_ping),
                ('ECHO', handle_echo),
                ('HELLO', handle_hello),
                ('WELCOME', print_message),
            ]
        return self._system_handlers

########################################################################################################################

class MyServer(SocketServer.ThreadingMixIn, SocketServer.TCPServer):
    allow_reuse_address = True

    def serve_forever(self, poll_interval=0.5):
        server_logger.info(threading.current_thread())
        self.running = True
        try:
            #super(MyServer, self).serve_forever(poll_interval)
            SocketServer.TCPServer.serve_forever(self, poll_interval)
        finally:
            self.running = False
            server_logger.error("DONE")

########################################################################################################################

class MyTCPHandler(SocketServer.BaseRequestHandler):

    def handle(self):
        peer = Peer(self.request)

        server_logger.info('Opening handler')
        server_logger.info(threading.current_thread())
        try:
            while self.server.running:
                message = peer.recv()
                peer.handle_message(message)
        finally:
            server_logger.info('Closing handler')

    def handle_message(self, control_data, data):
        self.server.shutdown()

########################################################################################################################

class Client(object):
    def __init__(self, host, port):
        self.host = host
        self.port = port
        client_logger.info(threading.current_thread())
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((self.host, self.port))
        self.peer = Peer(self.socket)
        self.peer.send(Message(command = 'HELLO'))
        self.peer.recv()


########################################################################################################################

HOST, PORT = "localhost", 6667

def client():
    client_logger.info(threading.current_thread())
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((HOST, PORT))

    peer = Peer(sock)
    peer.send(Message(command = 'HELLO'))
    try:
        while True:
            peer.send(Message(command = 'PING'))
            message = peer.recv()
            if message:
                print 'CLIENT', message
            time.sleep(0.1)
    except ClosedError:
        client_logger.warn('Closed')
    finally:
        sock.close()

def server():
    server = MyServer((HOST, PORT), MyTCPHandler)
    if False:
        threading.Thread(target = client).start()
    server.serve_forever()

#def test():
#    server()
