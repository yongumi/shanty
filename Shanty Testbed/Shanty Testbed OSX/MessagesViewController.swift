//
//  MessagesViewController.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 7/31/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

import Shanty

class Record : NSObject {
    var peer : STYPeer?
    var message : STYMessage
    init(peer:STYPeer, message:STYMessage) {
        self.peer = peer
        self.message = message
        super.init()
    }
}

class MessagesViewController: NSViewController {

    dynamic var messages : [Record] = []
    dynamic var selectionIndexes : NSIndexSet?

    @IBOutlet var messagesArrayController : NSArrayController!
    @IBOutlet var selectedObjectController : NSObjectController!

    override class func load() {
        BlockValueTransformer.register("MessageDirectionValueTransformer") { 
            value in
            
            if let value = value as? NSNumber {
                let direction: STYMessageDirection = STYMessageDirection.fromRaw(value.integerValue)!
                switch direction {
                    case .Unknown:
                        return "Unknown"
                    case .Incoming:
                        return "Incoming"
                    case .Outgoing:
                        return "Outgoing"
                }
            } else {
                return nil
            }
        }
    }

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = "Messages"
        messagesViewController = self
    }

    required init(coder: NSCoder!) {
        super.init(coder:coder)
        self.title = "Messages"
        messagesViewController = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func addMessage(peer:STYPeer, message:STYMessage) {
        messages.append(Record(peer:peer, message:message))
    }
}

var messagesViewController : MessagesViewController!
