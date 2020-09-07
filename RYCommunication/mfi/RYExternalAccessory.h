//
//  RYExternalAccessory.h
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import "RYStreamPair.h"

NS_ASSUME_NONNULL_BEGIN

@interface RYExternalAccessory : RYStreamPair <EAAccessoryDelegate>

@property (nonatomic, strong, nullable) EASession *session;

@property (nonatomic, strong) EAAccessory *accessory;

/**
 初始化MCSession对象
 
 @param accessory 系统外设对象
 @param protocolString 设备协议
 @return 对象
 */
- (instancetype)initWithAccessory:(EAAccessory *)accessory forProtocol:(NSString *)protocolString;

@end

NS_ASSUME_NONNULL_END
