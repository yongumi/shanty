//
//  Utilities.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 8/11/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Foundation

class BlockValueTransformer: NSValueTransformer {

    let block : (AnyObject!) -> (AnyObject!)

    class func register(name:String, block:(AnyObject!) -> (AnyObject!)) {
        let transformer = BlockValueTransformer(block:block)
        self.setValueTransformer(transformer, forName:name)
    }

    init(block:(AnyObject!) -> (AnyObject!)) {
        self.block = block
    }
    
    override func transformedValue(value: AnyObject!) -> AnyObject! {
        return self.block(value)
    }
}
