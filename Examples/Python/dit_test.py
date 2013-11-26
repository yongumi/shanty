__author__ = 'schwa'

import SocketServer
import struct
import json
import socket
#import bencode
import threading
import logging
import time
import zlib


FORMAT = '%(name)s@%(relativeCreated)d:%(message)s'
logging.basicConfig(format=FORMAT, level=logging.DEBUG)
server_logger = logging.getLogger('SERVER')
client_logger = logging.getLogger('CLIENT')
#server_logger.warning('Protocol problem')
#client_logger.warning('Protocol problem')

#control_data_SIZE = 32
#DATA_SIZE = 32

HEADER_FORMAT = '!HHL'
HEADER_SIZE = struct.calcsize(HEADER_FORMAT)

class ClosedError(EOFError):
    pass

CMD = 'cmd'
MSGID = 'msgid'

########################################################################################################################

class Message(object):
    def __init__(self, control_data = None, metadata = None, data = None):
        self.control_data = control_data if control_data else {}
        self.metadata = metadata
        self.data = data if data else ''

    @staticmethod
    def encode(obj):
        return json.dumps(obj)
#        return zlib.compress(json.dumps(obj))

    @staticmethod
    def decode(s):
        return json.loads(s)
#        return json.loads(zlib.decompress(s))

    def buffer(self):
        control_data_data = self.encode(self.control_data)
        metadata_data = self.encode(self.metadata) if self.metadata else ''
        data = self.data if self.data else ''
        format = HEADER_FORMAT + '%ss%ss%ss' % (len(control_data_data), len(metadata_data), len(data))
        message_data = struct.pack(format, len(control_data_data), len(metadata_data), len(data), control_data_data, metadata_data, data)
        #print len(message_data), message_data.encode('string-escape')
        return message_data

    @classmethod
    def from_stream(cls, s):
        header_data = s.recv(HEADER_SIZE)
        if not header_data:
            raise ClosedError()
        control_data_size, metadata_size, data_size = struct.unpack(HEADER_FORMAT, header_data)
        control_data_data = s.recv(control_data_size)
        if len(control_data_data) != control_data_size:
            raise EOFError()
        control_data = Message.decode(control_data_data)

        if metadata_size > 0:
            metadata_data = s.recv(metadata_size)
            if len(metadata_data) != metadata_size:
                raise EOFError()
            metadata = Message.decode(metadata_data)
        else:
            metadata = None

        data = s.recv(data_size)
        if len(data) != data_size:
            raise Exception('data size mismatch')

        return Message(control_data, metadata, data)

    def __repr__(self):
        return 'Message(%s, %s, %s)' % (self.control_data, self.metadata, self.data)

########################################################################################################################

class Peer(object):
    def __init__(self, stream):
        self.stream = stream
        self.last_incoming_message_id = None
        self.next_outgoing_message_id = 0

    def send(self, message):
        control_data = dict(message.control_data)
        control_data[MSGID] = self.next_outgoing_message_id
        self.next_outgoing_message_id += 1
        message.control_data[MSGID] = self.next_outgoing_message_id
        self.stream.sendall(message.buffer())

    def recv(self):
        message = Message.from_stream(self.stream)
        return message

    def handle_message(self, message):
        print '####', message
        incoming_message_id = message.control_data[MSGID]
        if self.last_incoming_message_id and incoming_message_id != self.last_incoming_message_id + 1:
            raise Exception("Incoming message ids dont match.")
        self.last_incoming_message_id = incoming_message_id

        cmd = message.control_data[CMD]
        if cmd == 'ECHO':
            self.handle_echo(message)
        elif cmd == 'PING':
            self.handle_ping(message)
        elif cmd == 'HELLO':
            self.handle_hello(message)

    def send_ping(self):
        self.send(Message({ CMD: 'PING' }))

    def handle_ping(self, message):
        self.send(Message({ CMD: 'PONG', 'in-response-to': message.control_data[MSGID] }))

    def send_echo(self, metadata = None, data = None):
        self.send(Message(control_data = { CMD: 'PING' }, metadata = metadata, data = data))

    def handle_echo(self, message):
        self.send(Message({ CMD: 'ECHO_RESPONSE', 'in-response-to': message.control_data[MSGID] }, message.metadata, message.data))

    def send_hello(self):
        self.send(Message({ CMD: 'HELLO' }))

    def handle_hello(self, message):
        self.send(Message({ CMD: 'HELLO_RESPONSE', 'in-response-to': message.control_data[MSGID] }, message.metadata, message.data))


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

HOST, PORT = "localhost", 6667

def client():
    client_logger.info(threading.current_thread())
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((HOST, PORT))

    peer = Peer(sock)
    peer.send_hello()
    try:
        while True:
            peer.send_ping()
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

if __name__ == "__main__":
    server()
