from __future__ import print_function
from __future__ import absolute_import
from __future__ import unicode_literals

__author__ = 'schwa'
__all__ = ['Advertiser', 'Browser', 'Service']

import pybonjour
import select
import logging
import time

########################################################################################################################

FORMAT = '%(name)-15s | %(threadName)-10s | %(levelname)-7s | %(relativeCreated)5.0d | %(message)s'
logger = logging.getLogger('bonjour')
_handler  = logging.StreamHandler()
_formatter = logging.Formatter(FORMAT)
_handler.setFormatter(_formatter)
logger.addHandler(_handler)
#logger.setLevel(logging.DEBUG)

########################################################################################################################

class TimeoutError(Exception): pass

class Advertiser(object):
    def __init__(self, name, type, port):
        self.name = name
        self.regtype = type
        self.port = port
        self.registered = False

    def register_callback(self, sdRef, flags, errorCode, name, regtype, domain):
        if errorCode == pybonjour.kDNSServiceErr_NoError:
            self.registered = True

    def start(self):
        self.sdRef = pybonjour.DNSServiceRegister(name=self.name, regtype=self.regtype, port=self.port,
                                                  callBack=self.register_callback)
        while not self.registered:
            ready = select.select([self.sdRef], [], [])
            if self.sdRef in ready[0]:
                pybonjour.DNSServiceProcessResult(self.sdRef)

    def stop(self):
        self.sdRef.close()
        self.registered = False

########################################################################################################################

class Service(object):
    def __init__(self, domain = None, type = None, name = None, host = None, port = None):
        self.domain = domain
        self.type = type
        self.name = name
        self.host = host
        self.port = port
        self.resolved = False

    def resolve(self, interfaceIndex = 0, timeout = None):

        def callback(sdRef, flags, interfaceIndex, errorCode, fullname, hosttarget, port, txtRecord):
            if errorCode == pybonjour.kDNSServiceErr_NoError:
                self.resolved = True
                self.host = hosttarget
                self.port = port
                self.fullname = fullname
                self.TXTRecord = txtRecord
                logger.debug('Service resolved: %s' % self)
            else:
                raise Exception('Failed to resolve (%s)' % (errorCode))

        logger.debug('Resolving service: %s' % self)
        sdref = pybonjour.DNSServiceResolve(0, interfaceIndex, self.name, self.type, self.domain, callback)
        try:
            while not self.resolved:
                logger.debug('Resolve select.')
                rlist, wlist, xlist = select.select([sdref], [], [], timeout)
                logger.debug('Resolve select returned.')
                if sdref not in rlist:
                    break
                pybonjour.DNSServiceProcessResult(sdref)
            else:
                pass
        finally:
            sdref.close()

    def __repr__(self):
        return 'Service(domain: \'{domain}\', type: \'{type}\', name: \'{name}\', host: \'{host}\', port: {port})'.format(**self.__dict__)

########################################################################################################################

class Browser(object):
    def __init__(self, type, domain=None):
        assert type

        self.domain = domain if domain else ''
        self.type = type

    def browse(self, timeout = 0, timeout_throws = True):

        self._found = False
        self._lastService = None
        self._interfaceIndex = None

        def callback(sdRef, flags, interfaceIndex, errorCode, serviceName, regtype, replyDomain):
            if errorCode != pybonjour.kDNSServiceErr_NoError:
                raise Exception('Failed to browse (%s)' % (errorCode))
            if not (flags & pybonjour.kDNSServiceFlagsAdd):
                return
            self._interfaceIndex = interfaceIndex
            self._lastService = Service(type = self.type, name = serviceName, domain = replyDomain)
            self._found = True

        logger.debug('Browsing for services in domain \'%s\' of type \'%s\'' % (self.domain, self.type))
        sdref = pybonjour.DNSServiceBrowse(domain=self.domain, regtype=self.type, callBack=callback)
        start_time = time.time()
        try:
            while not self._found:
                logger.debug('Browse select')
                rlist, wlist, xlist = select.select([sdref], [], [], timeout)
                logger.debug('Browse select returned')
                if sdref in rlist:
                    pybonjour.DNSServiceProcessResult(sdref)
                if not self._found and timeout and time.time() - start_time > timeout:
                    logger.debug('No services found and timeout occured.')
                    if timeout_throws:
                        raise TimeoutError()
                    else:
                        return None
        finally:
            sdref.close()

        self._lastService.resolve(self._interfaceIndex)

        return self._lastService

    @staticmethod
    def browse_one(type, domain=None, timeout=None):
        browser = Browser(type=type, domain=domain)
        service = browser.browse(timeout=timeout, timeout_throws = False)
        return service

