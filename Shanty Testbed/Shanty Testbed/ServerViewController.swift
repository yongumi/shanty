//
//  ServerViewController.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 7/24/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

import Shanty

class ServerViewController: NSViewController {
    var useLoopback : Bool
    var domain : String?
    var type : String?
    var name : String?
    var host : String?
    var port : NSNumber?

    var server : STYServer!

    init(coder: NSCoder?) {
        self.useLoopback = true

        super.init(coder: coder)
    }

    @IBAction func connect(sender:AnyObject?) {
        //        Shanty.STYSetLoggingEnabled(true)
        //        self.publisher = Shanty.STYServicePublisher(port:1234)
        //        self.publisher.netServiceType = "_test._tcp"
        //        self.publisher.localhostOnly = true
        //        self.publisher.netServiceSubtypes = ["_foo"]
        //        self.publisher.startPublishing() { error in println(error) }

        var port_ : UInt32 = 0
        if self.port != nil {
            port_ = UInt32(self.port!.unsignedIntegerValue())
        }

        let address = self.useLoopback ? STYAddress(loopbackAddress: port_) : STYAddress(anyAddress: port_)
        println(address)
        self.server = STYServer(listeningAddress:address, netServiceDomain:self.domain, type:self.type, name:self.name)
        self.server.startListening() { error in println(error) }
    }
}
