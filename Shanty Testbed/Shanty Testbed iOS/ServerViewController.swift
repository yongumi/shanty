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
        
        self.serve(nil)
    }

    @IBAction func serve(sender:AnyObject?) {
    
        let type = "_styexample._tcp"
    
        self.server = STYListener(listeningAddress:STYAddress(loopbackAddress:0), netServiceDomain:nil, type:type, name:nil)
        self.server.delegate = self
        self.server.publishOnLocalhostOnly = true
        self.server.startListening() {
            error in
        }
    }


}

