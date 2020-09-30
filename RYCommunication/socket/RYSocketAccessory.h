//
//  RYSocketAccessory.h
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RYStreamPair.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  \~chinese
 *
 *  Socket设备
 *
 *  \~english
 *
 *  Socket accessory
 *
 */
@interface RYSocketAccessory : RYStreamPair

///< \~chinese ip \~english ip
@property (nonatomic, copy) NSString *ip;

///< \~chinese port \~english port
@property (nonatomic, assign) NSInteger port;

/**
 *  \~chinese
 *
 *  创建socket设备对象
 *
 *  @param ip ip
 *  @param port port
 *
 *  \~english
 *
 *  Create socket accessory object
 *
 *  @param ip ip
 *  @param port port
 *
 */
- (instancetype)initWith:(NSString *)ip port:(NSInteger)port;

@end

NS_ASSUME_NONNULL_END
