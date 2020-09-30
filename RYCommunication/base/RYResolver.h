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

/**
 *  \~chinese
 *
 *  通用数据解析模型
 *
 *  \~english
 *
 *  Common data resolve model
 *
 */
@interface RYCommonResolveModel : NSObject

///< \~chinese 是否丢弃 \~english discardable
@property (nonatomic, assign) BOOL isDiscardable;

///< \~chinese 数据内容 \~english content
@property (nonatomic, strong) NSData *data;

///< \~chinese 消耗的数据量 \~english data length costed
@property (nonatomic, assign) NSInteger cost;

///< \~chinese 源数据 \~english raw data
@property (nonatomic, strong) NSData *rawData;

@end

/**
 *  \~chinese
 *
 *  路由处理模块
 *
 *  \~english
 *
 *  Router block
 *
 */
@interface RYDataRouterBlock : NSObject

///< \~chinese 最小数据长度 \~english min data length
@property (nonatomic, assign) NSInteger minDataLength;

/**
 *  \~chinese
 *
 *  用于将数据生成指定模型的block
 *
 *  \~english
 *
 *  a block to generate resolve model from supplied data
 *
 */
@property (nonatomic, copy) RYCommonResolveModel * _Nullable (^ handleBlock)(NSData *);

@end

/**
 *  \~chinese
 *
 *  数据路由器
 *
 *  \~english
 *
 * Data router
 *
 */
@interface RYDataRouter : NSObject

/**
 *  \~chinese
 *
 *  注册操作
 *
 *  @param key key
 *  @param block 处理block
 *
 *  \~english
 *
 *  register opration
 *
 *  @param key key
 *  @param block process block
 *
 */
- (void)registerHandle:(NSData *)key block:(RYDataRouterBlock *)block;

/**
 *  \~chinese
 *
 *  获取操作block
 *
 *  \~english
 *
 *  Get process block
 *
 */
- (RYDataRouterBlock * _Nullable)handle:(NSData *)key;

@end

/**
 *  \~chinese
 *
 *  一个不进行任何处理的数据解析器
 *
 *  \~english
 *
 *  A resolver that do nothing
 *
 */
@interface RYNotHandlingResolver : NSObject <RYDataResolver>

@end

/**
 *  \~chinese
 *
 *  通用解析器
 *
 *  \~english
 *
 *  Common resolver
 *
 */
@interface RYCommonResolver : NSObject <RYDataResolver>

///< \~chinese 路由对象 \~english router
@property (nonatomic, strong) RYDataRouter *router;

///< \~chinese 处理失败回调 \~english called when handle fail
@property (nonatomic, copy) void (^ _Nullable handleFailBlock)(NSData *);

/**
 *  \~chinese
 *
 *  注册操作，子类重写
 *
 *  \~english
 *
 *  register handle, override by subclass
 *
 */
- (void)registerHandle;

@end

NS_ASSUME_NONNULL_END
