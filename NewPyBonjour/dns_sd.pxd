
cdef extern from "dns_sd.h":
    ctypedef unsigned int uint32_t
    ctypedef unsigned short uint16_t

    ctypedef int DNSServiceErrorType
    ctypedef void *DNSServiceRef
    ctypedef int DNSServiceFlags
    ctypedef void *DNSServiceRegisterReply
    ctypedef void *DNSServiceBrowseReply

    cdef int kDNSServiceFlagsMoreComing = 0x1
    cdef int kDNSServiceFlagsAdd = 0x2
    cdef int kDNSServiceFlagsDefault = 0x4
    cdef int kDNSServiceFlagsNoAutoRename = 0x8
    cdef int kDNSServiceFlagsShared = 0x10
    cdef int kDNSServiceFlagsUnique = 0x20
    cdef int kDNSServiceFlagsBrowseDomains = 0x40
    cdef int kDNSServiceFlagsRegistrationDomains = 0x80
    cdef int kDNSServiceFlagsLongLivedQuery = 0x100
    cdef int kDNSServiceFlagsAllowRemoteQuery = 0x200
    cdef int kDNSServiceFlagsForceMulticast = 0x400
    cdef int kDNSServiceFlagsForce = 0x800 # This flag is deprecated.
    cdef int kDNSServiceFlagsKnownUnique = 0x800
    cdef int kDNSServiceFlagsReturnIntermediates = 0x1000
    cdef int kDNSServiceFlagsNonBrowsable = 0x2000
    cdef int kDNSServiceFlagsShareConnection = 0x4000
    cdef int kDNSServiceFlagsSuppressUnusable = 0x8000
    cdef int kDNSServiceFlagsTimeout = 0x10000
    cdef int kDNSServiceFlagsIncludeP2P = 0x20000
    cdef int kDNSServiceFlagsWakeOnResolve = 0x40000
    cdef int kDNSServiceFlagsBackgroundTrafficClass = 0x80000
    cdef int kDNSServiceFlagsIncludeAWDL = 0x100000
    cdef int kDNSServiceFlagsValidate = 0x200000
    cdef int kDNSServiceFlagsSecure = 0x200010
    cdef int kDNSServiceFlagsInsecure = 0x200020
    cdef int kDNSServiceFlagsBogus = 0x200040
    cdef int kDNSServiceFlagsIndeterminate = 0x200080
    cdef int kDNSServiceFlagsUnicastResponse = 0x400000
    cdef int kDNSServiceFlagsValidateOptional = 0x800000
    cdef int kDNSServiceFlagsWakeOnlyService = 0x1000000
    cdef int kDNSServiceFlagsThresholdOne = 0x2000000
    cdef int kDNSServiceFlagsThresholdFinder = 0x4000000
    cdef int kDNSServiceFlagsThresholdReached = kDNSServiceFlagsThresholdOne
    cdef int kDNSServiceFlagsDenyCellular = 0x8000000
    cdef int kDNSServiceFlagsServiceIndex = 0x10000000
    cdef int kDNSServiceFlagsDenyExpensive = 0x20000000

    cdef int kDNSServiceInterfaceIndexAny = 0
    cdef int kDNSServiceInterfaceIndexLocalOnly = -1
    cdef int kDNSServiceInterfaceIndexUnicast = -2
    cdef int kDNSServiceInterfaceIndexP2P = -3

    ctypedef void (*DNSServiceBrowseReply)(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *serviceName, const char *regtype, const char *replyDomain, void *context)

    DNSServiceErrorType DNSServiceProcessResult(DNSServiceRef sdRef)

    int DNSServiceRefSockFD(DNSServiceRef sdRef)

    DNSServiceErrorType DNSServiceRegister(DNSServiceRef *sdRef, DNSServiceFlags flags, uint32_t interfaceIndex,
        const char *name, const char *regtype, const char *domain,const char *host,  uint16_t port, uint16_t txtLen,
        const void *txtRecord, DNSServiceRegisterReply callBack, void *context)
    void DNSServiceRefDeallocate(DNSServiceRef sdRef)

    DNSServiceErrorType DNSServiceBrowse(DNSServiceRef *sdRef, DNSServiceFlags flags, uint32_t interfaceIndex,
        const char *regtype, const char *domain, DNSServiceBrowseReply callBack, void *context)
