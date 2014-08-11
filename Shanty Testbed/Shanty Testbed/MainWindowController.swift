//
//  MainWindowController.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 7/29/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    @IBOutlet var tabView : NSTabView?

    var serverViewController : ServerViewController?
    var clientViewController : ClientViewController?
    var messagesViewController : MessagesViewController?

    override func windowDidLoad() {
        super.windowDidLoad()

        self.serverViewController = ServerViewController(nibName:"ServerViewController", bundle:nil)
        let serverItem = NSTabViewItem(identifier: "Server")
        serverItem.label = "Server"
        serverItem.view = self.serverViewController!.view
        self.tabView!.addTabViewItem(serverItem)
   
        self.clientViewController = ClientViewController(nibName:"ClientViewController", bundle:nil)
        let clientItem = NSTabViewItem(identifier: "Client")
        clientItem.label = "Client"
        clientItem.view = self.clientViewController!.view
        self.tabView!.addTabViewItem(clientItem)

        self.messagesViewController = MessagesViewController(nibName:"MessagesViewController", bundle:nil)
        let messagesItem = NSTabViewItem(identifier: "Messages")
        messagesItem.label = "Messages"
        messagesItem.view = self.messagesViewController!.view
        self.tabView!.addTabViewItem(messagesItem)

    }

}
