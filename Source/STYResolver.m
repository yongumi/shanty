//
//  STYResolver.m
//  STYNetBrowser
//
//  Created by Jonathan Wight on 11/4/14.
//  Copyright (c) 2014 schwa.io. All rights reserved.
//

#import "STYResolver.h"

#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>

#import "STYConstants.h"

@implementation STYResolver

- (id)init
    {
    if ((self = [super init]) != NULL)
        {
        _queue = dispatch_get_main_queue();
        }
    return self;
    }

- (void)resolveName:(NSString *)name handler:(void (^)(NSArray *addresses, NSError *error))handler
    {
    [self resolveName:name service:NULL handler:handler];
    }

- (void)resolveName:(NSString *)name service:(NSString *)service handler:(void (^)(NSArray *addresses, NSError *error))handler
    {
    dispatch_async(self.queue, ^{

        NSMutableSet *theAddresses = [NSMutableSet set];

        struct addrinfo hints = {
            .ai_flags = AI_CANONNAME | AI_V4MAPPED,
    //        .ai_protocol = IPPROTO_IPV4,
            .ai_family = PF_UNSPEC,
        };
        struct addrinfo *address = NULL;

        int result = getaddrinfo(name.UTF8String, service.UTF8String, &hints, &address);
        if (result == 0)
            {
            const struct addrinfo *current = address;
            while (current != NULL)
                {
                const size_t theLength = INET6_ADDRSTRLEN + 1;
                char buffer[theLength];
                
                const struct sockaddr_in *theAddress = (const struct sockaddr_in *)current->ai_addr;
                NSData *theData = [NSData dataWithBytes:theAddress length:theAddress->sin_len];
                [theAddresses addObject:theData];

                if (inet_ntop(current->ai_family, &theAddress->sin_addr, buffer, theLength) == NULL)
                    {
                    if (handler != NULL)
                        {
                        NSError *theError = [NSError errorWithDomain:kSTYErrorDomain code:kSTYErrorCode_Unknown userInfo:NULL];
                        handler(NULL, theError);
                        }
                    return;
                    }
                current = current->ai_next;
                }
            }
        
        freeaddrinfo(address);

        if (handler != NULL)
            {
            NSArray *theSortedAddresses = [theAddresses.allObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                // NOTE: In theory next line could post a problem if objects have the same prefix but are different lengths. This cannot happen because sockaddr_* structs have the length encoded at start of struct.
                return memcmp([obj1 bytes], [obj2 bytes], MIN([obj1 length], [obj2 length]));
            }];

            handler(theSortedAddresses, NULL);
            }
        });
    }
    
- (NSData *)_addressData:(NSData *)inAddressData withPort:(uint16_t)inPort
    {
    struct sockaddr_in theAddress;

    NSParameterAssert(inAddressData.length == sizeof(theAddress));

    memcpy(&theAddress, inAddressData.bytes, sizeof(theAddress));
    theAddress.sin_port = htons(inPort);

    NSData *theAddressData = [NSData dataWithBytes:&theAddress length:sizeof(theAddress)];
    return(theAddressData);
    }


@end
