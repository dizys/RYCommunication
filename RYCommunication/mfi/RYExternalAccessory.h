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

/**
 *  \~chinese
 *
 *  MFI设备
 *
 *  \~english
 *
 *  MFI accessory
 *
 */
@interface RYExternalAccessory : RYStreamPair <EAAccessoryDelegate>

@property (nonatomic, strong, nullable) EASession *session;///< \~chinese 会话 \~english session

@property (nonatomic, strong) EAAccessory *accessory;///< \~chinese MFI外设 \~english MFI accessory

/**
 *  \~chinese
 *
 *  创建MFI设备对象
 *  @param accessory 系统外设对象
 *  @param protocolString 设备协议
 *
 *  \~english
 *
 *  Create MFI RYExternalAccessory object
 *
 *  @param accessory EAAccessory
 *  @param protocolString MFI protocol
 *
 */
- (instancetype)initWithAccessory:(EAAccessory *)accessory forProtocol:(NSString *)protocolString;

@end

NS_ASSUME_NONNULL_END
