//
//  RYUDPBrowser.h
//  RYCommunication iOS
//
//  Created by ldc on 2020/10/10.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RYUDPPort <NSObject>

@property (nonatomic, copy) NSString *ip;

@property (nonatomic, strong) NSData *advertisementData;

@end

@interface RYUDPPortAccessory : NSObject <RYUDPPort>

@end

@interface RYUDPBrowser : NSObject

@property (nonatomic, strong, readonly) NSArray<id<RYUDPPort>> * _Nonnull ports;

@property (nonatomic, copy) void (^ _Nullable discovePortBlock)(id<RYUDPPort>);

@property (nonatomic, copy) void (^ _Nullable searchTimeoutBlock)(void);

@property (nonatomic, copy) BOOL (^ _Nullable filterBlock)(NSData *);

@property (nonatomic, copy) id<RYUDPPort> (^ _Nullable portGenerateBlock)(NSData *, NSString *);

- (instancetype)initWithPort:(uint16_t)port;

- (void)startSearch:(NSTimeInterval)timeout;

- (void)stopSearch;

- (void)broadcast;

@end

NS_ASSUME_NONNULL_END
