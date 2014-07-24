//
//  AppDelegate.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 7/22/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

import Shanty

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    var publisher : STYServicePublisher!

    var server : STYServer!

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
//        Shanty.STYSetLoggingEnabled(true)
//        self.publisher = Shanty.STYServicePublisher(port:1234)
//        self.publisher.netServiceType = "_test._tcp"
//        self.publisher.localhostOnly = true
//        self.publisher.netServiceSubtypes = ["_foo"]
//        self.publisher.startPublishing() { error in println(error) }
  
        
        let address = STYAddress(loopbackAddress: 0)
        self.server = STYServer(listeningAddress:address, netServiceDomain:nil, type:"_test._tcp", name:nil)
        self.server.startListening() { error in println(error) }
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
    }

}

