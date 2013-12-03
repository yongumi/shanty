__author__ = 'schwa'

import Foundation
import PyObjCTools.AppHelper

class Publisher(Foundation.NSObject):

    def initWithDomain_type_name_port_(self, domain, type, name, port):
        self.domain = domain
        self.type = type
        self.name = name
        self.port = port
        self.publishingSucceededHandler = None
        self.publishingFailedHandler = None
        return self

    def publish(self):
        self.service = Foundation.NSNetService.alloc().initWithDomain_type_name_port_(self.domain, self.type, self.name, self.port)
        self.service._.delegate = self
        self.service.publishWithOptions_(0)

    def netServiceDidPublish_(self, sender):
        print 'Did'
        if self.publishingSucceededHandler:
            self.publishingSucceededHandler()

    def netService_didNotPublish_(self, sender, errorDict):
        print 'Did Not'
        if self.publishingFailedHandler:
            self.publishingFailedHandler()

def run():
    PyObjCTools.AppHelper.runConsoleEventLoop()

def cancel():
    PyObjCTools.AppHelper.stopEventLoop()

def blocking(domain, type, name, port):
    e = None
    def finished(*args, **kwargs):
        cancel()
    def failed(*args, **kwargs):
        print 'Failed'
        e = Exception('Failed to publish')
        cancel()
    p = Publisher.alloc().initWithDomain_type_name_port_(domain, type, name, port)
    p.publishingFinishedHandler = finished
    p.publishingFailedHandler = failed
    p.publish()
    run()
    #print e
    #if e:
    #    raise e
    print 'Done'

def test():
    blocking('local.', '_test._tcp.', 'My test', 12345)
    print 'Done'

test()
