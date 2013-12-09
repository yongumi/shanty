import threading
import os
import time
import shanty
import bonjour
import signal
import sys

logger = shanty.root_logger

try:
    type = '_shanty-test._tcp'
    name = 'Shanty Test %d' % os.getpid()
    logger.debug(name)
    s = shanty.Server(type, name)
    threading.Thread(target = s.serve_forever).start()

    time.sleep(1)

    name, host, port = bonjour.browse_one(type = type)
    c = shanty.Client(host, port)
    c.peer.send(shanty.Message(command = 'ECHO', data = 'Hello world!'))
    del c
    time.sleep(5)

finally:
    logger.debug('Shutting down server')
    s.shutdown()
    logger.debug('Sleep (1 sec)')

    time.sleep(1)
    logger.debug('terminate')

#    os.kill(os.getpid(), signal.SIGTERM)
    sys.exit()

