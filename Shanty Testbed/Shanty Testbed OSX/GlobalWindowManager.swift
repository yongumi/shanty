//
//  GlobalWindowManager.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 8/18/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Cocoa

class GlobalWindowManager : NSResponder {

    var windowControllers : [NSWindowController] = []

    override init() {
        super.init()
        
        NSApplication.sharedApplication().nextResponder = self
    }

    required init?(coder: NSCoder) {
        super.init(coder:coder)
    }
    
    func addViewController(viewController:NSViewController) {
        let window = NSWindow(contentViewController:viewController)
        if viewController.title != nil {
            window.title = viewController.title
        }
        let windowController = NSWindowController(window: window)
        self.addWindowController(windowController)
    }

    func addWindowController(windowController:NSWindowController) {
        self.windowControllers.append(windowController)
        windowController.window!.makeKeyAndOrderFront(self)
        self._updateWindowMenu()
    }

    func _updateWindowMenu() {
        let windowMenu = NSApplication.sharedApplication().windowsMenu
        let menuItemIndex = windowMenu!.indexOfItemWithTitle("Bring All to Front")
        for (index, windowController) in enumerate(self.windowControllers) {
            let title = "Show \(windowController.window?.title)"
            if windowMenu!.indexOfItemWithTitle(title) == -1 {
                let key = "\(index + 1)"
                let newItem = NSMenuItem(title:title, action:"test", keyEquivalent:key)
                windowMenu!.insertItem(newItem, atIndex: menuItemIndex)
            }
        }
    }
}

let GlobalWindowManager_shareInstance = GlobalWindowManager()

//        println(NSApplication.sharedApplication().mainMenu.itemWithTitle("Window").submenu)
