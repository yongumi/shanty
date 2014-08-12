//
//  ServerViewController.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 7/24/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

import Shanty

class ServerViewController: NSViewController, STYServerDelegate {
    var useLoopback : Bool = true
    var domain : String?
    var type : String = "_styexample._tcp"
    var name : String?
    var host : String?
    var port : NSNumber?
    var code : String = STYServer.randomCode()

    dynamic var server : STYServer!

    @IBOutlet var startButton : NSButton?
    @IBOutlet var stopButton : NSButton?

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
        self._setup()
    }
    
    required init(coder: NSCoder!) {
        super.init(coder:coder)
        self._setup()
    }

    internal func _setup() {
        self.title = "Server"
    }

    @IBAction func serve(sender:AnyObject?) {
        var port_ : UInt32 = 0
        if self.port != nil {
            port_ = UInt32(self.port!.unsignedIntegerValue)
        }

        self.server = STYServer(listeningAddress:STYAddress(anyAddress: port_), netServiceDomain:self.domain, type:self.type, name:self.name)
        self.server.delegate = self
        self.server.publishOnLocalhostOnly = self.useLoopback
        self.server.startListening() {
            error in
        }
    }

    @IBAction func stop(sender:AnyObject?) {
        self.server.stopListening(nil)
        self.server = nil
    }

    func server(inServer: STYServer!, peerWillConnect inPeer: STYPeer!) {
        inPeer.tap = {
            (peer, message, error) in

            dispatch_async(dispatch_get_main_queue()) {
                messagesViewController.addMessage(inPeer, message:message)
            }

            return true
        }
    }

    func server(inServer: STYServer!, didCreatePeer inPeer: STYPeer!) {
        peersViewController.addPeer(inPeer)
    }
}
