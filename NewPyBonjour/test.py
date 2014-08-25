import cython

import pyximport; pyximport.install()

from DNSSD import *

import time

# service = Service()
# service.regtype = "Hello world"
# service.register()
# print service

browser = Browser("_http._tcp")
browser.browse()

time.sleep(5)
#
