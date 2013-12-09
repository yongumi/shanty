#!/usr/bin/env python

__author__ = 'schwa'

import pybonjour
import select

class Advertiser(object):
    def __init__(self, name, type, port):
        self.name    = name
        self.regtype = type
        self.port    = port
        self.registered = False

    def register_callback(self, sdRef, flags, errorCode, name, regtype, domain):
        if errorCode == pybonjour.kDNSServiceErr_NoError:
            #print 'Registered service:'
            #print '  name    =', name
            #print '  regtype =', regtype
            #print '  domain  =', domain
            self.registered = True

    def start(self):
        self.sdRef = pybonjour.DNSServiceRegister(name = self.name, regtype = self.regtype, port = self.port, callBack = self.register_callback)
        while not self.registered:
            ready = select.select([self.sdRef], [], [])
            if self.sdRef in ready[0]:
                pybonjour.DNSServiceProcessResult(self.sdRef)

    def stop(self):
        self.sdRef.close()
        self.registered = False



class BonjourBrowser(object):

    def __init__(self, type, domain = None, timeout = None):
        self.domain = domain if domain else ''
        self.type  = type
        self.timeout  = timeout if timeout else 5
        self.resolved = []

    def resolve_callback(self, sdRef, flags, interfaceIndex, errorCode, fullname, hosttarget, port, txtRecord):
        if errorCode == pybonjour.kDNSServiceErr_NoError:
            #print 'Resolved service:'
            #print '  fullname   =', fullname
            #print '  hosttarget =', hosttarget
            #print '  port       =', port
            #print '  txtRecorod =', txtRecord
            self.resolved.append((fullname, hosttarget, port))

    def browse_callback(self, sdRef, flags, interfaceIndex, errorCode, serviceName, regtype, replyDomain):
        if errorCode != pybonjour.kDNSServiceErr_NoError:
            return
        if not (flags & pybonjour.kDNSServiceFlagsAdd):
            #print 'Service removed'
            return

        #print 'Service added; resolving'

        resolve_sdRef = pybonjour.DNSServiceResolve(0, interfaceIndex, serviceName, regtype, replyDomain, self.resolve_callback)
        try:
            while not self.resolved:
                ready = select.select([resolve_sdRef], [], [], self.timeout)
                if resolve_sdRef not in ready[0]:
                    #print 'Resolve timed out'
                    break
                pybonjour.DNSServiceProcessResult(resolve_sdRef)
            else:
#                self.resolved.pop()
                pass
        finally:
            resolve_sdRef.close()

    def browse(self):
        browse_sdRef = pybonjour.DNSServiceBrowse(domain = self.domain, regtype = self.type, callBack = self.browse_callback)
        try:
            while not self.resolved:
                ready = select.select([browse_sdRef], [], [])
                if browse_sdRef in ready[0]:
                    pybonjour.DNSServiceProcessResult(browse_sdRef)
        finally:
            browse_sdRef.close()
        return self.resolved

def browse_one(type, domain = None, timeout = None):
    browser = BonjourBrowser(type = type, domain = domain, timeout = timeout)
    return browser.browse()[0]
