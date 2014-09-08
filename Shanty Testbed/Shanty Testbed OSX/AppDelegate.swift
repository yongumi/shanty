//
//  AppDelegate.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 7/22/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa
import Shanty

class AppDelegate: NSObject, NSApplicationDelegate {
        
    var mainWindowController : MainWindowController!

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        STYSetLoggingEnabled(true)
        self.mainWindowController = MainWindowController(windowNibName: "MainWindowController")
        self.mainWindowController.window.makeKeyAndOrderFront(nil)
    

//        self.serverViewController = ServerViewController(nibName:"ServerViewController", bundle:nil)
//        GlobalWindowManager_shareInstance.addViewController(self.serverViewController)
//
//        self.clientViewController = ClientViewController(nibName:"ClientViewController", bundle:nil)
//        GlobalWindowManager_shareInstance.addViewController(self.clientViewController)
//
//        self.messagesViewController = MessagesViewController(nibName:"MessagesViewController", bundle:nil)
//        GlobalWindowManager_shareInstance.addViewController(self.messagesViewController)


    }

    func applicationWillTerminate(aNotification: NSNotification?) {
    }

}

