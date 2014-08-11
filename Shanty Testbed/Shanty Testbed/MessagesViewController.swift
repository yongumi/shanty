//
//  MessagesViewController.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 7/31/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

import Shanty

class MessagesViewController: NSViewController {

    var messages : NSMutableArray = []
    var selectedIndexes : NSMutableIndexSet?

    @IBOutlet var messagesArrayController : NSArrayController?
    @IBOutlet var messageArrayController : NSObjectController?

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        messagesViewController = self
    }

    required init(coder: NSCoder!) {
        super.init(coder:coder)
        messagesViewController = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func addMessage(message:STYMessage) {
        self.willChangeValueForKey("messages")
        messages.addObject(message)
        self.didChangeValueForKey("messages")
    }
    
}

var messagesViewController : MessagesViewController!
