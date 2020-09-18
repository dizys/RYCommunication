//
//  RYDataRouter.h
//  RYCommunication
//
//  Created by ldc on 2020/9/10.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>

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

NS_ASSUME_NONNULL_END
