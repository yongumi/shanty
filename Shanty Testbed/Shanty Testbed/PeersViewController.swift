//
//  PeersViewController.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 8/21/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

import Shanty

class PeersViewController: NSViewController {

    dynamic var peers : [STYPeer] = []

    @IBOutlet var tableView : NSTableView!

    override class func load() {
        BlockValueTransformer.register("PeerModeValueTransformer") {
            value in
            if let value = value as? NSNumber {
                let direction: STYMessengerMode = STYMessengerMode.fromRaw(value.integerValue)!
                switch direction {
                    case .Undefined:
                        return "Undefined"
                    case .Client:
                        return "Client"
                    case .Server:
                        return "Server"
                }
            } else {
                return nil
            }
        }

        BlockValueTransformer.register("PeerStateValueTransformer") {
            value in
            if let value = value as? NSNumber {
                let direction: STYPeerState = STYPeerState.fromRaw(value.integerValue)!
                switch direction {
                    case .Undefined:
                        return "Undefined"
                    case .Opening:
                        return "Opening"
                    case .Handshaking:
                        return "Handshaking"
                    case .Ready:
                        return "Ready"
                    case .Closing:
                        return "Closing"
                    case .Closed:
                        return "Closed"
                    case .Error:
                        return "Error"
                }
            } else {
                return nil
            }
        }
    }

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = "Peers"
        peersViewController = self
    }

    required init(coder: NSCoder!) {
        super.init(coder:coder)
        self.title = "Peers"
        peersViewController = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func addPeer(peer:STYPeer) {
        self.peers.append(peer)
    }
    
    @IBAction func closePeer(sender:NSMenuItem!) {
        let peer = self.peers[self.tableView.selectedRow]
        peer.close(nil)
    }

    override func prepareForSegue(segue: NSStoryboardSegue!, sender: AnyObject!) {
        let peer = self.peers[self.tableView.selectedRow]
        let destinationController = segue.destinationController as SendMessageViewController
        destinationController.representedObject = peer
    }

}

var peersViewController : PeersViewController!
