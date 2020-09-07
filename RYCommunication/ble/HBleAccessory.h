//
//  HBleAccessory.h
//  BleKit
//
//  Created by ldc on 2019/3/25.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "base.h"
#import "HBleConst.h"
#import "HBleService.h"

NS_ASSUME_NONNULL_BEGIN

@interface HBleAccessory : NSObject <CBCentralManagerDelegate, RYAccessory>

@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) NSNumber *rssi;

@property (nonatomic, strong) NSDictionary<NSString *,id> *advertisementData;

@property (nonatomic, strong) NSArray<id<HBleServiceProtocol>> *services;

@property (nonatomic, assign, readonly) BOOL connected;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral rssi:(NSNumber *)rssi advertisement:(NSDictionary<NSString *,id> *)advertisementData;

@end

NS_ASSUME_NONNULL_END
