from __future__ import print_function
from __future__ import absolute_import
#from __future__ import unicode_literals

__author__ = 'schwa'
__all__ = ['MessageBuilder', 'Message', 'MessageCoder', 'MessageHandler']

import struct
import json
import six

from shanty.main import *

########################################################################################################################

HEADER_FORMAT = '!HHL'
HEADER_SIZE = struct.calcsize(HEADER_FORMAT) # currently 8

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
            if isinstance(condition, six.string_types):
                if message.control_data[CTL_CMD] == condition:
                    return handler
            elif condition(message):
                return handler
        return None

########################################################################################################################

# TODO work better with MessageCoder
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
