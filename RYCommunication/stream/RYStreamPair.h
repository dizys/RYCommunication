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

/**
 *  \~chinese
 *
 *  连接失败错误码
 *
 *  \~english
 *
 *  Connect fail error code
 *
 */
typedef NS_ENUM(NSInteger, RYStreamPairConnectErrorCode) {
    
    RYStreamPairConnectErrorCodeTimeout,///< \~chinese 连接超时，超时时间10秒 \~english timeout
    
    RYStreamPairConnectErrorCodeEmptyStreamObject,///< \~chinese 使用空 流对象进行连接 \~english empty stream object
    
    RYStreamPairConnectErrorCodeAuthTimeout,///< \~chinese 授权超时 \~english auth timeout
    
    RYStreamPairConnectErrorCodeAuthFail,/////< \~chinese 授权失败 \~english auth fail
};

/**
 *  \~chinese
 *
 *  输入输出流封装类
 *
 *  \~english
 *
 *  A class wrap NSInputStream and NSOutputStream
 *
 */
@interface RYStreamPair : NSObject <RYAccessory, RYDataWriteImmutablyProtocol>

@property (nonatomic, strong, nullable) NSInputStream *input;///< \~chinese 输入流 \~english input stream

@property (nonatomic, strong, nullable) NSOutputStream *output;///< \~chinese 输出流 \~english output stream

@property (nonatomic, assign, readonly) BOOL connected;///< \~chinese 是否连接 \~english is connected

/**
 *  \~chinese
 *
 *  关闭输入输出流
 *
 *  \~english
 *
 *  close input and output stream
 *
 */
- (void)closeStream;

@end

NS_ASSUME_NONNULL_END
