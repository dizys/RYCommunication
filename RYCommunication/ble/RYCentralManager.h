//
//  RYCentralManager.h
//  BleKit
//
//  Created by ldc on 2019/3/25.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "RYBleAccessory.h"

NS_ASSUME_NONNULL_BEGIN

@interface RYBleScanOption : NSObject

@property (nonatomic, strong) NSArray<CBUUID *> * _Nullable serviceUUIDs;

@property (nonatomic, copy) BOOL (^ _Nullable printerFilter)(CBPeripheral *, NSNumber *, NSDictionary<NSString *,id> *);

@end

@interface RYCentralManager : NSObject

+ (instancetype)share;

@property (nonatomic, readonly, strong) NSArray<RYBleAccessory *> *printers;

@property (nonatomic, copy) void(^ _Nullable powerOffBlock)(void);

@property (nonatomic, copy) void(^ _Nullable discoverBlock)(RYBleAccessory *device);

@property (nonatomic,readonly, assign) BOOL isBlePowerOn;

- (void)startScan:(RYBleScanOption * _Nullable)option;

- (void)stopScan;

- (void)registCentralManagerDelegate:(RYBleAccessory *)delegate;

- (void)unregistCentralManagerDelegate:(RYBleAccessory *)delegate;

- (void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *, id> *)options;

- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral;

@end

NS_ASSUME_NONNULL_END
