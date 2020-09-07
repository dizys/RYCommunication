//
//  RYCentralMessageRepeater.h
//  BleKit
//
//  Created by ldc on 2019/3/25.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "RYBleAccessory.h"

NS_ASSUME_NONNULL_BEGIN

@interface RYCentralMessageRepeater : NSObject <CBCentralManagerDelegate>

- (void)registTarget:(RYBleAccessory *)target;

- (void)unregistTarget:(RYBleAccessory *)target;

@end

NS_ASSUME_NONNULL_END
