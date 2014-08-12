//
//  SendMessageViewController.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 8/21/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

import Shanty

class SendMessageViewController: NSViewController {

    var peer : STYPeer!
    dynamic var command : String = ""

    override var representedObject: AnyObject! { didSet { self.peer = representedObject as STYPeer } }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    @IBAction func OK(sender:AnyObject?) {
        println(self.command)
        let message = STYMessage(controlData:[kSTYCommandKey : self.command], metadata: nil, data: nil)
        self.peer.sendMessage(message, completion:nil)
        self.dismissController(self)
    }

}
