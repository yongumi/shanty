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

    @IBOutlet var startButton : NSButton?
    @IBOutlet var stopButton : NSButton?

    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        self.useLoopback = true
        self.type = "_styexample._tcp"

        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }

    @IBAction func serve(sender:AnyObject?) {

        var port_ : UInt32 = 0
        if self.port != nil {
            port_ = UInt32(self.port!.unsignedIntegerValue)
        }

        self.server = STYServer(listeningAddress:STYAddress(anyAddress: port_), netServiceDomain:self.domain, type:self.type, name:self.name)
        self.server.publishOnLocalhostOnly = self.useLoopback
        self.server.startListening() {
            error in
//            println(error)
//            println(self.server.actualAddress)
            }
    }

    @IBAction func stop(sender:AnyObject?) {
        self.server.stopListening(nil)
        self.server = nil
    }
}
