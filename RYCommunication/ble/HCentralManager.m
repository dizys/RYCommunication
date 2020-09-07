//
//  HCentralManager.m
//  BleKit
//
//  Created by ldc on 2019/3/25.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "HCentralManager.h"
#import "HCentralMessageRepeater.h"

@implementation HBleScanOption

@end

@interface HCentralManager () <CBCentralManagerDelegate>

@property (nonatomic, assign) BOOL scanning;

@property (nonatomic, strong) CBCentralManager *manager;

@property (nonatomic, readwrite, strong) NSMutableArray<HBleAccessory *> *p_printers;

@property (nonatomic, readwrite, assign) BOOL isBlePowerOn;

@property (nonatomic, strong) HCentralMessageRepeater *repeater;

@property (nonatomic, strong) HBleScanOption *option;

@end

@implementation HCentralManager

+ (instancetype)share {
    
    static HCentralManager *share;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[HCentralManager alloc] init];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //关于CBCentralManagerOptionShowPowerAlertKey,当设置为YES时，只有蓝牙完全关闭时才会触发弹框。
        //当蓝牙只是从控制中心关闭时(控制中心关闭只会断开与配件的连接，但苹果一些要使用蓝牙的服务依然可以使用蓝牙),是不会触发这个弹框的
        self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.p_printers = [NSMutableArray new];
        self.scanning = false;
        self.repeater = [[HCentralMessageRepeater alloc] init];
    }
    return self;
}

- (NSArray<HBleAccessory *> *)printers {
    
    return self.p_printers;
}

- (BOOL)isBlePowerOn {
    
    return self.manager.state == CBCentralManagerStatePoweredOn;
}

- (void)startScan:(HBleScanOption *)option {
    
    if (self.scanning) {
        return;
    }
    self.option = option;
    [self private_startScan];
}

- (void)private_startScan {
    
    if (self.manager.state != CBCentralManagerStatePoweredOn) {
        self.scanning = true;
        return;
    }
    [self.p_printers removeAllObjects];
    [self.manager scanForPeripheralsWithServices:self.option.serviceUUIDs options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    self.scanning = true;
}

- (void)stopScan {
    
    self.scanning = false;
    [self.p_printers removeAllObjects];
    self.option = nil;
    if (self.manager.state != CBCentralManagerStatePoweredOn) {
        return;
    }
    [self.manager stopScan];
}

- (void)registCentralManagerDelegate:(HBleAccessory *)delegate {
    
    [self.repeater registTarget:delegate];
}

- (void)unregistCentralManagerDelegate:(HBleAccessory *)delegate {
    
    [self.repeater unregistTarget:delegate];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary<NSString *,id> *)options {
    
    [self.manager connectPeripheral:peripheral options:options];
}

- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral {
    
    [self.manager cancelPeripheralConnection:peripheral];
}

#pragma mark --CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
        case CBCentralManagerStateResetting:
        case CBCentralManagerStateUnsupported:
        case CBCentralManagerStateUnauthorized:
            break;
        case CBCentralManagerStatePoweredOff:
            [self.p_printers removeAllObjects];
            if (self.powerOffBlock) {
                self.powerOffBlock();
            }
            break;
        case CBCentralManagerStatePoweredOn:
            if (self.scanning) {
                [self private_startScan];
            }
            break;//蓝牙打开，开始扫描。
        default:                                break;
    }
    [self.repeater centralManagerDidUpdateState:central];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(nonnull CBPeripheral *)peripheral advertisementData:(nonnull NSDictionary<NSString *,id> *)advertisementData RSSI:(nonnull NSNumber *)RSSI {
    
    [self.repeater centralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    if (peripheral.name == nil) {
        return;
    }
    if (self.option.printerFilter) {
        BOOL available = self.option.printerFilter(peripheral, RSSI, advertisementData);
        if (!available) {
            return;
        }
    }
    NSInteger index = [self.printers indexOfObjectPassingTest:^BOOL(HBleAccessory * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.peripheral isEqual:peripheral];
    }];
    if (index == NSNotFound) {
        HBleAccessory *temp = [[HBleAccessory alloc] initWithPeripheral:peripheral rssi:RSSI advertisement:advertisementData];
        [self.p_printers addObject:temp];
        if (self.discoverBlock) {
            self.discoverBlock(temp);
        }
    }else {
        self.printers[index].advertisementData = advertisementData;
        self.printers[index].rssi = RSSI;
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    [self.repeater centralManager:central didConnectPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [self.repeater centralManager:central didDisconnectPeripheral:peripheral error:error];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [self.repeater centralManager:central didFailToConnectPeripheral:peripheral error:error];
}

@end
