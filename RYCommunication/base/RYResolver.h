//
//  RYNotHandlingResolver.h
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "base.h"
#import "RYResolver.h"

NS_ASSUME_NONNULL_BEGIN

@interface RYCommonResolverModel : NSObject

@property (nonatomic, assign) BOOL isDiscardable;

@property (nonatomic, strong) NSData *data;

@property (nonatomic, assign) NSInteger cost;

@property (nonatomic, strong) NSData *rawData;

@end

@interface RYDataRouterBlock : NSObject

@property (nonatomic, assign) NSInteger minDataLength;

@property (nonatomic, copy) RYCommonResolverModel * _Nullable (^ handleBlock)(NSData *);

@end

@interface RYDataRouter : NSObject

- (void)registerHandle:(NSData *)key block:(RYDataRouterBlock *)block;

- (RYDataRouterBlock * _Nullable)handle:(NSData *)key;

@end

@interface RYNotHandlingResolver : NSObject <RYDataResolver>

@end

@interface RYCommonResolver : NSObject <RYDataResolver>

@property (nonatomic, strong) RYDataRouter *router;

@property (nonatomic, copy) void (^ _Nullable handleFailBlock)(NSData *);

- (void)registerHandle;

@end

NS_ASSUME_NONNULL_END
