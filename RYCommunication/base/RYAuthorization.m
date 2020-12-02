//
//  RYAuthorization.m
//  RYCommunication
//
//  Created by ldc on 2020/9/8.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "RYAuthorization.h"

@implementation RYAuthorization

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timeout = 3;
    }
    return self;
}

- (void)startChallenge {
    
    if (self.validatedBlock) {
        self.validatedBlock(RYAuthorizationResultDenied);
    }
}

- (void)readInput:(NSData *)data {
    
}

@end
