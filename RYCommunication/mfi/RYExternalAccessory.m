//
//  RYExternalAccessory.m
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "RYExternalAccessory.h"
#import "RYResolver.h"

@implementation RYExternalAccessory

- (NSInputStream *)input {
    
    return self.session.inputStream;
}

- (NSOutputStream *)output {
    
    return self.session.outputStream;
}

- (NSString *)name {
    
    return self.session.accessory.name == nil ? @"" : self.session.accessory.name;
}

- (instancetype)initWithAccessory:(EAAccessory *)accessory forProtocol:(NSString *)protocolString {
    
    self = [self init];
    self.accessory = accessory;
    self.session = [[EASession alloc] initWithAccessory:accessory forProtocol:protocolString];
    self.resolver = [[RYNotHandlingResolver alloc] init];
    return self;
}

- (void)connect:(void (^)(void))successBlock fail:(void (^)(NSError * _Nonnull))failBlock {
    
    [super connect:^{
        self.accessory.delegate = self;
        successBlock();
    } fail:failBlock];
}

- (void)disconnect {
    
    [super disconnect];
    self.accessory.delegate = nil;
}

- (void)closeStream {
    
    [super closeStream];
    self.session = nil;
}

- (void)accessoryDidDisconnect:(EAAccessory *)accessory {
    
    [self disconnect];
    if (self.closedBlock) {
        self.closedBlock(nil);
    }
}

@end
