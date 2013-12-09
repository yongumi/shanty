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

#import zlib
#import bencode
import snappy # pip install --user python-snappy

#__all__ = ['Client', 'Message', 'Peer', 'MessageCoder']

########################################################################################################################

FORMAT = '%(name)-6s | %(threadName)-10s | %(levelname)s | %(relativeCreated)5.0d | %(message)s'
logging.basicConfig(format=FORMAT, level=logging.DEBUG)
root_logger = logging.getLogger('')
server_logger = logging.getLogger('server')
client_logger = logging.getLogger('client')

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
            raise ClosedError()
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
    def __init__(self, mode, socket):
        self.mode = mode
        self.socket = socket
        self.last_incoming_message_id = None
        self.next_outgoing_message_id = 0
        self.handlers = []
        self.messageCoder = MessageCoder()
        self.logger = client_logger
        self.buffer = IOBuffer()

    def close(self):
        self.logger.debug('Closing peer socket %s', self.socket)
        self.socket.close()
        self.buffer = None

    def send(self, message):
        control_data = dict(message.control_data)
        control_data[MSGID] = self.next_outgoing_message_id
        self.next_outgoing_message_id += 1
        message.control_data = control_data
        self.logger.debug('Sending: %s', message)
        data = self.messageCoder.flatten_message(message)
        try:
            self.socket.sendall(data)
        except socket.error, e:
            if e.args[0] == errno.EBADF:
                self.logger.error('Bad file descriptor, probably in select.')
            else:
                raise

    def recv(self):
        try:
            read_buffer = self.socket.recv(4096)
        except socket.error, e:
            print e.args
            # ECONNRESET
            if e.args[0] == errno.EBADF:
                self.logger.error('Bad file descriptor, probably in select.')
            else:
                raise
        if read_buffer:
            #self.logger.debug('READ: %d' % len(read_buffer))
            self.buffer.append(read_buffer)
            #self.logger.debug(self.buffer)
            message = self.messageCoder.message_from_stream(self.buffer)
            self.logger.debug('Received: %s', message)
            self.handle_message(message)
            return True
        else:
            return False

    def handle_message(self, message):
        incoming_message_id = message.control_data[MSGID]
        next_incoming_msgid = self.last_incoming_message_id + 1 if self.last_incoming_message_id else 1
        if self.last_incoming_message_id and incoming_message_id != next_incoming_msgid:
            error = "Incoming message ids dont match (got %d expected %d)" % (incoming_message_id, next_incoming_msgid)
            self.logger.error(error)
#            raise Exception(error)
        self.last_incoming_message_id = incoming_message_id

        handler = None
        for handlers in [self.system_handlers, self.handlers]:
            handler = self.find_handler(handlers, message)
            if handler:
                break

        if handler:
            handler(self, message)
        else:
            self.logger.warning('No handler for %s' % message)

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
                #self.logger.debug('HANDLE HELLO')
                peer.send(Message({ CMD: 'HELLO_RESPONSE', 'in-response-to': message.control_data[MSGID] }, message.metadata, message.data))

            def print_message(peer, message):
                self.logger.info('%s' % message)

            def nop(peer, message):
                pass

            self._system_handlers = [
                ('PING', handle_ping),
                ('ECHO', handle_echo),
                ('HELLO', handle_hello),
                ('HELLO_RESPONSE', nop),
                ]
        return self._system_handlers

########################################################################################################################

class Client(object):
    def __init__(self, host, port):
        self.logger = client_logger

        self.host = host
        self.port = port
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((self.host, self.port))
        self.peer = Peer('CLIENT', self.socket)
        self.peer.logger = self.logger
        self.peer.send(Message(command = 'HELLO'))
        self.peer.recv()

    def __del__(self):
        self.peer.close()


########################################################################################################################

class MyTCPHandler(SocketServer.BaseRequestHandler):

    def setup(self):
        self.logger = server_logger
        self.peer = Peer('SERVER', self.request)
        self.peer.logger = self.logger
        self.server.peers.append(self.peer)

    def handle(self):
        try:
            request_socket = self.peer.socket
            request_socket.setblocking(False)

            while self.server.running:
                readers, writers, errors = select.select([request_socket], [], [request_socket], 600)
#                self.logger.debug('%s %s %s', readers, writers, errors)
                if request_socket in readers:
                    self.peer.recv()
                elif request_socket in errors:
                    self.logger.error('Socket error!')
                else:
                    break
        except select.error, e:
            self.logger.debug('Running? %s' % self.server.running)
            if e.args[0] == errno.EBADF:
                self.logger.debug('Bad file descriptor, probably in select.')
            else:
                raise

    def finish(self):
        #self.logger.debug('Handler finish.')
        del self.server.peers[self.server.peers.index(self.peer)]

class Server(SocketServer.ThreadingMixIn, SocketServer.TCPServer):
    allow_reuse_address = True

    def __init__(self, dnssd_type, dnssd_name, host = '', port = 0):
        self.logger = server_logger
        self.logger.debug('type:%s name:%s host:%s port:%s' % (dnssd_type, dnssd_name, host, port))
        self.dnssd_type = dnssd_type
        self.dnssd_name = dnssd_name
        SocketServer.TCPServer.__init__(self, (host, port), MyTCPHandler)
        self.peers = []

    def server_bind(self):
        SocketServer.TCPServer.server_bind(self)
        name, port = self.socket.getsockname()
        self.logger.debug('Server bound: %s %s', name, port)
        self.advertiser = bonjour.Advertiser(type = self.dnssd_type, name = self.dnssd_name, port = port)
        self.advertiser.start()

    def serve_forever(self, poll_interval=0.5):
        #self.logger.debug('Serving.')
        self.running = True
        try:
           SocketServer.TCPServer.serve_forever(self, poll_interval)
        finally:
            self.running = False
        server_logger.debug("serve_forever completed")

    def shutdown(self):
        SocketServer.TCPServer.shutdown(self)
        for peer in self.peers:
            peer.close()
        self.advertiser.stop()

########################################################################################################################

#HOST, PORT = "localhost", 6667

#def client():
#    client_logger.info(threading.current_thread())
#    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#    sock.connect((HOST, PORT))
#
#    peer = Peer(sock)
#    peer.send(Message(command = 'HELLO'))
#    try:
#        while True:
#            peer.send(Message(command = 'PING'))
#            message = peer.recv()
#            if message:
#                print 'CLIENT', message
#            time.sleep(0.1)
#    except ClosedError:
#        client_logger.warn('Closed')
#    finally:
#        sock.close()

#def server():
#    server = Server(HOST, PORT)
#    if False:
#        threading.Thread(target = client).start()
#    server.serve_forever()

#def test():
#    server()
