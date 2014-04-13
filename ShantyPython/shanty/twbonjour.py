from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'
__all__ = 'broadcast'

import pybonjour
from twisted.internet.defer import Deferred
from twisted.internet.interfaces import IReadDescriptor
from zope import interface

class ServiceDescriptor(object):
    interface.implements(IReadDescriptor)

    def __init__(self, sdref):
        self.sdref = sdref

    def doRead(self):
        pybonjour.DNSServiceProcessResult(self.sdref)

    def fileno(self):
        return self.sdref.fileno()

    def logPrefix(self):
        return 'bonjour'

    def connectionLost(self, reason):
        self.sdref.close()

def broadcast(reactor, regtype, port, name=None):
    def _callback(sdref, flags, errorCode, name, regtype, domain):
        #print sdref, flags, errorCode, name, regtype, domain
        if errorCode == pybonjour.kDNSServiceErr_NoError:
            d.callback((sdref, name, regtype, domain))
        else:
            d.errback(errorCode)
    d = Deferred()
    sdref = pybonjour.DNSServiceRegister(name = name, regtype = regtype, port = port, callBack = _callback, domain = 'local.')
    reactor.addReader(ServiceDescriptor(sdref))
    return d

sdref = None
