//
//  STYAddress.h
//  Shanty Examples
//
//  Created by Jonathan Wight on 12/11/13.
//  Copyright (c) 2013 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STYAddress : NSObject <NSCopying>

@property (readonly, nonatomic, copy) NSData *data;

- (id)initWithData:(NSData *)inData;

@end
