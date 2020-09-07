//
//  HBleService.h
//  HYEditor
//
//  Created by ldc on 2019/12/18.
//  Copyright © 2019 swiftHY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "base.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HBleServiceProtocol <CBPeripheralDelegate, RYAccessory>

@property (nonatomic, strong) CBUUID *uuid;

@property (nonatomic, weak) CBPeripheral * _Nullable peripheral;

@property (nonatomic, copy) void (^ _Nullable configureSuccess)(void);

@property (nonatomic, copy) void (^ _Nullable configureFail)(NSError *);

- (void)clear;

@end

@interface HBleService : NSObject <HBleServiceProtocol>

@end

@interface CP4000lBleService : HBleService

@end

@interface FF00BleService : HBleService

@end

NS_ASSUME_NONNULL_END
