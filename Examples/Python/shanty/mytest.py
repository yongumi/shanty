import os
import shanty
from twisted.internet import reactor
from twisted.internet.endpoints import TCP4ServerEndpoint
import twbonjour
import bonjour
import sys
from twisted.internet.endpoints import TCP4ClientEndpoint

logger = shanty.root_logger

#defer.setDebugging(True)

type = '_shanty-test._tcp'
name = 'Shanty Test %d' % os.getpid()
logger.debug(name)

def client(argskwargs):
    def test(protocol):
        m = shanty.Message(command = 'echo', metadata = { 'reverse': 1 }, data = 'Hello World!!!')

        protocol.sendMessage(m)
    name, host, port = bonjour.browse_one(type = type)
#    logger.debug('%s %s %s' % (name, host, port))
    factory = shanty.ShantyClientFactory()
#    reactor.connectTCP(host, port, factory)
    point = TCP4ClientEndpoint(reactor, host, port)
    d = point.connect(factory)
    d.addCallback(test)


endpoint = TCP4ServerEndpoint(reactor, 0)
d = endpoint.listen(shanty.ShantyServerFactory())
def my_endpoint(*args, **kwargs):
    my_port = args[0]
    host, port = my_port.socket.getsockname()
    #logger.debug('%s %s' % (host, port))
    d = twbonjour.broadcast(reactor, type, port, name)
    d.addCallback(client)
d.addCallback(my_endpoint)


def die():
    reactor.stop()

#reactor.callLater(2, client)

reactor.callLater(10, die)

reactor.run()
