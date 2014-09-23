//
//  ViewController.swift
//  Shanty Testbed iOS
//
//  Created by Jonathan Wight on 9/5/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import UIKit

import Shanty

class ServerViewController: UIViewController, STYListenerDelegate {

    var server : STYListener!
                            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        STYSetLoggingEnabled(true)
        self.view.backgroundColor = UIColor(hue:1.0, saturation:1.0, brightness:0.5, alpha:1.0)
        self.serve(nil)
    }

    @IBAction func serve(sender:AnyObject?) {
    
        let type = "_styexample._tcp"
    
        self.server = STYListener(listeningAddress:STYAddress(anyAddress:0), netServiceDomain:nil, type:type, name:nil)
        self.server.delegate = self
        self.server.publishOnLocalhostOnly = false
        self.server.startListening() {
            error in
            if error != nil {
                println(error)
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.view.backgroundColor = UIColor(hue: 0.333, saturation:1.0, brightness:0.5, alpha:1.0)
            }
        }
    }
}

