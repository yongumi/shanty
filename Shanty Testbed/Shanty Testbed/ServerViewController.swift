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
    var useLoopback : Bool
    var domain : String?
    var type : String?
    var name : String?
    var host : String?
    var port : NSNumber?

    var server : STYServer!

    @IBOutlet var startButton : NSButton?
    @IBOutlet var stopButton : NSButton?

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        self.useLoopback = true
        self.type = "_styexample._tcp"

        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    required init(coder: NSCoder!) {
        self.useLoopback = true
        self.type = "_styexample._tcp"

        super.init(coder:coder)
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
//            println(error)
//            println(self.server.actualAddress)
            }
    }

    @IBAction func stop(sender:AnyObject?) {
        self.server.stopListening(nil)
        self.server = nil
    }

    func server(inServer: STYServer!, peerWillConnect inPeer: STYMessagingPeer!) {
        inPeer.tap = {
            (peer, message, error) in

            dispatch_async(dispatch_get_main_queue()) {
                messagesViewController.addMessage(message)
            }

            return true
        }
    }

//    - (void)server:(STYServer *)inServer peerWillConnect:(STYMessagingPeer *)inPeer;


}
