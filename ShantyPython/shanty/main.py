from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'

import logging

# TODO Use twisted logging with py logging framework
FORMAT = '%(name)-6s | %(threadName)-10s | %(levelname)-7s | %(relativeCreated)5.0d | %(message)s'
#logging.basicConfig(format=FORMAT, level=logging.DEBUG)
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

MODE_CLIENT = 'CLIENT'
MODE_SERVER = 'SERVER'

########################################################################################################################
