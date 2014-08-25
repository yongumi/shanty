from dns_sd cimport *

# import select

cdef void DNSServiceBrowseCallback(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *serviceName, const char *regtype, const char *replyDomain, void *context):
    print 'Callback!!!', flags, interfaceIndex, errorCode, serviceName, regtype, replyDomain

    browser = <Browser>context
    if flags & kDNSServiceFlagsAdd:
        service = Service()
        service.name= serviceName
        service.type = regtype
        service.domain = replyDomain
        browser._callback(service, moreComing=bool(flags & kDNSServiceFlagsMoreComing))

class BonjourException(Exception):
    def __init__(self, code):
        self.code = code

class Service:
    def __init__(self):
        self.name = None
        self.type = None
        self.domain = None
    def __repr__(self):
        return 'Service(%s, %s, %s)' % (self.domain, self.type, self.name)

cdef class Browser:

    cdef const char *type
    cdef const char *domain
    cdef DNSServiceRef c_service

    def __init__(self, type, domain = None):
        assert(type)
        self.type = Nullify(type)
        self.domain = Nullify(domain)

    def browse(self):
#        cdef DNSServiceRef c_service
        result = DNSServiceBrowse(&self.c_service, 0, kDNSServiceInterfaceIndexAny, self.type, self.domain, DNSServiceBrowseCallback, <void *>self)
        if result != 0:
            raise BonjourException(result)

#        fd = DNSServiceRefSockFD(c_service)

        # print 'selecting'
        # print select.select([fd], [], [], 10)
        # print 'selected'
        result = DNSServiceProcessResult(self.c_service)

    def _callback(self, service, moreComing):
        print service


cdef class Registrar:

    cdef DNSServiceRef c_service
    cdef public char *regtype

    def __init__(self):
        # self.regtype = None
        # # self.name = None
        # self.domain = None
        # self.host = None
        # self.port = None
        # self.txtRecord = None
        pass

    def register(self, flags = 0, interfaceIndex = 0):

        cdef DNSServiceRef c_service = NULL

        # theError = DNSServiceRegister(&c_service, 0, 0, NULL, Nullify(self.regtype), Nullify(self.domain), Nullify(self.host), self.port, 0, Nullify(self.txtRecord), NULL, NULL)
        # self.c_service = c_service

    def __dealloc__(self):
        if self.c_service:
            DNSServiceRefDeallocate(self.c_service)
            self.c_service = NULL

cdef char *Nullify(s):
    cdef char *c_string
    if s:
        c_string = s
    else:
        c_string = NULL
    return c_string