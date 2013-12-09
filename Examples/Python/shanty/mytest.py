import os
import shanty
from twisted.internet import reactor
from twisted.internet.endpoints import TCP4ServerEndpoint
import twbonjour
import bonjour
import sys

logger = shanty.root_logger

#defer.setDebugging(True)

type = '_shanty-test._tcp'
name = 'Shanty Test %d' % os.getpid()
logger.debug(name)

endpoint = TCP4ServerEndpoint(reactor, 0)
address_deferred = endpoint.listen(shanty.ShantyServerFactory())
def my_endpoint(*args, **kwargs):
    my_port = args[0]
    host, port = my_port.socket.getsockname()
    logger.debug('%s %s' % (host, port))
    twbonjour.broadcast(reactor, type, port, name)
address_deferred.addCallback(my_endpoint)

def client():
    logger.debug('client!')
    name, host, port = bonjour.browse_one(type = type)
    logger.debug('%s %s %s' % (name, host, port))
    reactor.connectTCP(host, port, shanty.ShantyClientFactory())

def die():
    reactor.stop()


reactor.callLater(2, client)

reactor.callLater(10, die)

reactor.run()
