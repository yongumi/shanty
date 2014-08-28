//
//  STYServerPeer.h
//  shanty
//
//  Created by Jonathan Wight on 8/28/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import <Shanty/Shanty.h>

@interface STYServerPeer : STYPeer

@property (readwrite, nonatomic, copy) NSString *secret;

@end
