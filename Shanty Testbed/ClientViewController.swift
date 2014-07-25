//
//  ClientViewController.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 7/25/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

import Shanty

class ClientViewController: NSViewController {

    @IBOutlet var hostingView : NSView!
    var type : String! {
        didSet {
            self.browserViewController.netServiceType = type
        }
    }
    var browserViewController : STYPeerBrowserViewController!

    init(coder: NSCoder?) {

        self.browserViewController = STYPeerBrowserViewController()
        self.browserViewController.netServiceType = "_http._tcp"

        super.init(coder: coder)
    }

    override func awakeFromNib() {
        self.hostingView.addSubview(self.browserViewController.view())
    }
    
}
