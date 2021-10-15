//
//  RYSocketAccessory.m
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "RYSocketAccessory.h"

@implementation RYSocketAccessory

- (instancetype)initWith:(NSString *)ip port:(NSInteger)port
{
    self = [super init];
    if (self) {
        self.ip = ip;
        self.port = port;
    }
    return self;
}

- (void)connect:(void (^)(void))successBlock fail:(void (^)(NSError * _Nonnull))failBlock {
    
    switch (self.status) {
        case RYStreamPairConnectStatusConnected:
            successBlock();
            return;
        default:
            break;
    }
    NSInputStream *input;
    NSOutputStream *output;
    self.input = nil;
    self.output = nil;
    [NSStream getStreamsToHostWithName:self.ip port:self.port inputStream:&input outputStream:&output];
    self.input = input;
    self.output = output;
    [super connect:successBlock fail:failBlock];
}

@end
