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
        self.timeout = 10;
    }
    return self;
}

@end
