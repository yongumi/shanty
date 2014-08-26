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

    var browserViewController : STYPeerBrowserViewController!
    @IBOutlet var hostingView : NSView!
    var type : String! {
        didSet {
            self.browserViewController.netServiceType = type
        }
    }

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        self.type = "_styexample._tcp"
        self.browserViewController = STYPeerBrowserViewController()
        self.browserViewController.netServiceType = self.type

        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
        self.title = "Client"

        self.browserViewController.delegate = self
    }

    required init(coder: NSCoder!) {
        self.type = "_styexample._tcp"
        self.browserViewController = STYPeerBrowserViewController()
        self.browserViewController.netServiceType = self.type

        super.init(coder:coder)
        self.title = "Client"

        self.browserViewController.delegate = self
    }

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

    // MARK: Delegate methods

    func peerBrowser(inBrowserViewController: STYPeerBrowserViewController!, willConnectToPeer inPeer: STYPeer!) {
        inPeer.transport.tap = {
            (peer, message, error) in

            dispatch_async(dispatch_get_main_queue()) {
                messagesViewController.addMessage(peer, message:message)
            }

            return true
        }
    }
    
    func peerBrowser(inBrowserViewController: STYPeerBrowserViewController!, didCreatePeer inPeer: STYPeer!) {
        peersViewController.addPeer(inPeer)
    }

}
