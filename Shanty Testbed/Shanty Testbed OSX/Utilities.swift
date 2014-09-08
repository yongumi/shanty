//
//  Utilities.swift
//  Shanty Testbed
//
//  Created by Jonathan Wight on 8/11/14.
//  Copyright (c) 2014 schwa. All rights reserved.
//

import Foundation

class BlockValueTransformer: NSValueTransformer {

    typealias Block = (AnyObject?) -> (AnyObject?)
    let block: Block

    class func register(name:String, block:Block) -> BlockValueTransformer {
        let transformer = BlockValueTransformer(block:block)
        self.setValueTransformer(transformer, forName:name)
        return transformer
    }

    init(block:Block) {
        self.block = block
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        return self.block(value)
    }
}
