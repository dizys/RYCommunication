//
//  RYNotHandlingResolver.m
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "RYNotHandlingResolver.h"

@implementation RYNotHandlingResolver
@synthesize resolvedBlock;

- (void)readInput:(NSData *)data {
    
    if (self.resolvedBlock) {
        self.resolvedBlock(data);
    }
}

@end
