//
//  base.h
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#ifndef base_h
#define base_h

#import <Foundation/Foundation.h>
#import "RYAuthorization.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RYDataResolver <NSObject>

@property (nonatomic, copy ) void (^ _Nullable resolvedBlock)(id result);

- (void)readInput:(NSData *)data;

@end

@protocol RYAccessory <NSObject>

@property (nonatomic, strong) RYAuthorization *auth;

@property (nonatomic, strong) id<RYDataResolver> _Nullable resolver;

@property (nonatomic, copy) void (^ _Nullable closedBlock)(void);

- (void)connect:(void(^ _Nullable)(void))successBlock fail:(void(^ _Nullable)(NSError *))failBlock;

- (void)disconnect;

- (void)write:(NSData *)data progress:(void(^_Nullable)(NSProgress *))block;

- (void)stopWrite;

@end

NS_ASSUME_NONNULL_END

#endif /* base_h */
