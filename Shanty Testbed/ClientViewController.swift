//
//  ClientViewController.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 7/25/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

import Shanty

class ClientViewController: NSViewController, STYPeerBrowserViewControllerDelegate {

    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        self.type = "_styexample._tcp"
        self.browserViewController = STYPeerBrowserViewController()
        self.browserViewController.netServiceType = self.type

        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)

        self.browserViewController.delegate = self
    }

    @IBOutlet var hostingView : NSView!
    var type : String! {
        didSet {
            self.browserViewController.netServiceType = type
        }
    }
    var browserViewController : STYPeerBrowserViewController!

    override func awakeFromNib() {
    
        let hostedView = self.browserViewController.view
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        self.hostingView.addSubview(hostedView)
        
        let views : [NSObject : AnyObject] = [
            "view": hostedView,
            "host": self.hostingView,
            ]
        
        self.hostingView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[view]-(0)-|", options:NSLayoutFormatOptions(0), metrics:nil, views:views))
        self.hostingView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[view]-(0)-|", options:NSLayoutFormatOptions(0), metrics:nil, views:views))
    }
    
    func peerBrowser(inBrowserViewController: STYPeerBrowserViewController!, didConnectToPeer inPeer: STYMessagingPeer!) {
    }
    
    func peerBrowser(inBrowserViewController: STYPeerBrowserViewController!, didfailToConnect inError: NSError!) {
    }
    
    func peerBrowserDidCancel(inBrowserViewController: STYPeerBrowserViewController!) {
    }
    
}
