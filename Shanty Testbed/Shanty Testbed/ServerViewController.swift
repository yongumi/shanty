//
//  ServerViewController.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 7/24/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

import Shanty

class ServerViewController: NSViewController, STYListenerDelegate {
    dynamic var domain : String?
    dynamic var type : String = "_styexample._tcp"
    dynamic var name : String?
    dynamic var host : String?
    dynamic var port : UInt16 = 0
    dynamic var code : String = STYListener.randomCode()
    dynamic var loopback : Bool = true

    dynamic var server : STYListener!

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
    
        var address = self.loopback ? STYAddress(loopbackAddress:port) : STYAddress(anyAddress:port)
    
    
        self.server = STYListener(listeningAddress:address, netServiceDomain:self.domain, type:self.type, name:self.name)
        self.server.delegate = self
        println("Using localhost? \(loopback)")
        self.server.publishOnLocalhostOnly = self.loopback
        self.server.startListening() {
            error in
        }
    }

    @IBAction func stop(sender:AnyObject?) {
        self.server.stopListening(nil)
        self.server = nil
    }

    func listener(inListener: STYListener!, peerWillConnect inPeer: STYPeer!) {
        inPeer.transport.tap = {
            (peer, message, error) in

            dispatch_async(dispatch_get_main_queue()) {
                messagesViewController.addMessage(inPeer, message:message)
            }

            return true
        }
    }

    func listener(inListener: STYListener!, didCreatePeer inPeer: STYPeer!) {
        peersViewController.addPeer(inPeer)
    }
}
