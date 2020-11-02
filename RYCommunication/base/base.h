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

/**
 *  \~chinese
 *
 *  数据解析器
 *
 *  \~english
 *
 *  Data resolver
 *
 */
@protocol RYDataResolver <NSObject>

///< \~chinese 解析成功回调 \~english called when resolve succss
@property (nonatomic, copy ) void (^ _Nullable resolvedBlock)(id result);

/**
 *  \~chinese
 *
 *  读取外设输入数据
 *
 * @param data 输入数据
 *
 *  \~english
 *
 *  read input data for accessory
 *
 *  @param data input data
 *
 */
- (void)readInput:(NSData *)data;

@end

/**
 *  \~chinese
 *
 *  外部设备协议
 *
 *  \~english
 *
 *  External accessory protocol
 *
 */
@protocol RYAccessory <NSObject>

///< \~chinese 名称 \~english name
@property (nonatomic, copy) NSString *name;

///< \~chinese 授权验证对象 \~english authorize object
@property (nonatomic, strong) RYAuthorization * _Nullable auth;

///< \~chinese 数据解析器 \~english data resolver
@property (nonatomic, strong) id<RYDataResolver> _Nullable resolver;

///< \~chinese 连接关闭回调 \~english called when connect is closed
@property (nonatomic, copy) void (^ _Nullable closedBlock)(NSError * _Nullable);

/**
 *  \~chinese
 *
 *  连接
 *
 *  @param successBlock 连接成功回调
 *  @param failBlock 连接失败回调
 *
 *  \~english
 *
 *  connect
 *
 *  @param successBlock called when connect success
 *  @param failBlock called when connect fail
 *
 */
- (void)connect:(void(^ _Nullable)(void))successBlock fail:(void(^ _Nullable)(NSError *))failBlock;

/**
 *  \~chinese
 *
 *  断开连接
 *
 *  \~english
 *
 *  disconnnect
 *
 */
- (void)disconnect;

/**
 *  \~chinese
 *
 *  写入数据
 *
 *  @param data 要写入的数据
 *  @param block 写入进度回调
 *
 *  \~english
 *
 *  write data
 *
 *  @param data data will write
 *  @param block called when write process has updated
 *
 */
- (void)write:(NSData *)data progress:(void(^_Nullable)(NSProgress *))block;

/**
 *  \~chinese
 *
 *  停止写入
 *
 *  \~english
 *
 *  stop write
 *
 */
- (void)stopWrite;

@end

NS_ASSUME_NONNULL_END

#endif /* base_h */
