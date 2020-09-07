//
//  RYStreamPair.h
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "base.h"

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN NSErrorDomain RYStreamPairConnectErrorDomain;
typedef NS_ENUM(NSInteger, RYStreamPairConnectErrorCode) {
    //连接超时，超时时间10秒
    RYStreamPairConnectErrorCodeTimeout,
    //使用空 流对象进行连接
    RYStreamPairConnectErrorCodeEmptyStreamObject,
};

@interface RYStreamPair : NSObject <RYAccessory>

@property (nonatomic, strong, nullable) NSInputStream *input;

@property (nonatomic, strong, nullable) NSOutputStream *output;

@property (nonatomic, assign, readonly) BOOL connected;

- (void)closeStream;

@end

NS_ASSUME_NONNULL_END
