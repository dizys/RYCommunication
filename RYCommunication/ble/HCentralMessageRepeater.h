//
//  HCentralMessageRepeater.h
//  BleKit
//
//  Created by ldc on 2019/3/25.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "HBleAccessory.h"

NS_ASSUME_NONNULL_BEGIN

@interface HCentralMessageRepeater : NSObject <CBCentralManagerDelegate>

- (void)registTarget:(HBleAccessory *)target;

- (void)unregistTarget:(HBleAccessory *)target;

@end

NS_ASSUME_NONNULL_END
