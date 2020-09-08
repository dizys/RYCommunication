//
//  RYAuthorization.h
//  RYCommunication
//
//  Created by ldc on 2020/9/8.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RYAuthorizationResult) {
    RYAuthorizationResultAuthorized,
    RYAuthorizationResultDenied,
    RYAuthorizationResultNotDetermined,
};

@protocol RYDataWriteImmutablyProtocol <NSObject>

- (void)writeDataImmutably:(NSData *)data;

@end

@interface RYAuthorization : NSObject

@property (nonatomic, strong, nullable) NSTimer *timer;

@property (nonatomic, assign) NSTimeInterval timeout;

@property (nonatomic, copy) RYAuthorizationResult (^ _Nullable validateBlock)(RYAuthorization *, NSData *);

@property (nonatomic, copy) void (^ _Nullable startChallengeBlock)(id<RYDataWriteImmutablyProtocol>, RYAuthorization *);

@property (nonatomic, copy) NSData *(^ _Nullable dataEncryptBlock)(RYAuthorization *, NSData *);

@property (nonatomic, strong) id _Nullable authKey;

@end

NS_ASSUME_NONNULL_END
