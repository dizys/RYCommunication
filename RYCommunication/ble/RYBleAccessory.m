//
//  RYBleAccessory.m
//  BleKit
//
//  Created by ldc on 2019/3/25.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "RYBleAccessory.h"
#import "RYCentralManager.h"
#import "RYResolver.h"

@interface RYBleAccessory ()<CBPeripheralDelegate>

@property (nonatomic, weak, readonly) RYCentralManager *manager;

@property (nonatomic, copy) void(^successBlock)(void);

@property (nonatomic, copy) void(^failureBlock)(NSError *);

@property (nonatomic, assign, readwrite) BOOL connected;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) id<RYBleServiceProtocol> currentService;

@end

@implementation RYBleAccessory
@synthesize resolver;
@synthesize closedBlock;
@synthesize auth;
@synthesize name;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral rssi:(NSNumber *)rssi advertisement:(NSDictionary<NSString *,id> *)advertisementData {
    
    self = [super init];
    if (self) {
        self.peripheral = peripheral;
        self.rssi = rssi;
        self.advertisementData = advertisementData;
        self.resolver = [[RYNotHandlingResolver alloc] init];
        self.services = @[[[FF00BleService alloc] init]];
    }
    return self;
}

- (NSString *)name {
    
    return self.peripheral.name == nil ? @"" : self.peripheral.name;
}

- (void)setServices:(NSArray<id<RYBleServiceProtocol>> *)services {
    
    _services = services;
    [self configureServiceBlock];
}

- (void)configureServiceBlock {
    
    __weak typeof(self) weakSelf = self;
    for (id<RYBleServiceProtocol> service in self.services) {
        service.peripheral = self.peripheral;
        service.configureFail = ^(NSError * _Nonnull error) {
            [weakSelf didConnectFail:error];
        };
        service.configureSuccess = ^{
            [weakSelf.timer invalidate];
            weakSelf.timer = nil;
            weakSelf.connected = true;
            if (weakSelf.successBlock) {
                weakSelf.successBlock();
            }
            weakSelf.successBlock = nil;
            weakSelf.failureBlock = nil;
        };
        service.resolver.resolvedBlock = ^(id  _Nonnull result) {
            NSData *data = (NSData *)result;
            [weakSelf.resolver readInput:data];
        };
    }
}

- (void)didConnectFail:(NSError *)error {
    
    if (self.timer.isValid) {
        [self.timer invalidate];
    }
    self.timer = nil;
    [self disconnect];
    if (self.failureBlock && error) {
        self.failureBlock(error);
    }
    self.failureBlock = nil;
    self.successBlock = nil;
}

- (void)connect:(void (^)(void))successBlock fail:(void (^)(NSError * _Nonnull))failBlock {
    
    if (self.connected) {
        successBlock();
        return;
    }
    self.connected = false;
    self.successBlock = successBlock;
    self.failureBlock = failBlock;
    [self.manager registCentralManagerDelegate:self];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(connectTimeout) userInfo:nil repeats:false];
    });
    [self.manager connectPeripheral:self.peripheral options:nil];
}

- (void)disconnect {
    
    [self.manager unregistCentralManagerDelegate:self];
    if (self.peripheral.state == CBPeripheralStateConnected || self.peripheral.state == CBPeripheralStateConnecting) {
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
    self.connected = false;
    [self.currentService clear];
    self.currentService = nil;
}

- (void)connectTimeout {
    
    NSError *error = [NSError errorWithDomain:RYBleConnectErrorDomain code:RYBleConnectErrorCodeTimeout userInfo:nil];
    [self didConnectFail:error];
}

- (void)write:(NSData *)data progress:(void (^)(NSProgress * _Nonnull))block {
    
    [self.currentService write:data progress:block];
}

- (void)stopWrite { [NSException raise:@"未实现" format:@""]; }

#pragma mark ##--CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            if (self.connected) {
                [self disconnect];
                if (self.closedBlock) {
                    self.closedBlock(nil);
                }
            }
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if (self.closedBlock) {
        self.closedBlock(error);
    }
    [self disconnect];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSError *temp = [NSError errorWithDomain:RYBleConnectErrorDomain code:RYBleConnectErrorCodeSystemError userInfo:error.userInfo];
    [self didConnectFail:temp];
}

#pragma mark --
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if (peripheral.services.count == 0) {
        NSError *temp = [NSError errorWithDomain:RYBleConnectErrorDomain code:RYBleConnectErrorCodeServiceNotFound userInfo:nil];
        [self didConnectFail:temp];
        return;
    }
    id<RYBleServiceProtocol> pickedBleService;
    CBService *pickedCBService;
    for (id<RYBleServiceProtocol> service in self.services) {
        for (CBService *cbService in peripheral.services) {
            if ([cbService.UUID isEqual:service.uuid]) {
                pickedCBService = cbService;
                pickedBleService = service;
                break;
            }
        }
    }
    if (pickedCBService && pickedCBService) {
        self.currentService = pickedBleService;
        [peripheral discoverCharacteristics:nil forService:pickedCBService];
    }else {
        NSError *temp = [NSError errorWithDomain:RYBleConnectErrorDomain code:RYBleConnectErrorCodeServiceNotFound userInfo:nil];
        [self didConnectFail:temp];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if ([self.currentService respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]) {
        [self.currentService peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    if ([self.currentService respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]) {
        [self.currentService peripheral:peripheral didUpdateNotificationStateForCharacteristic:characteristic error:error];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if ([self.currentService respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]) {
        [self.currentService peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:error];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    if ([self.currentService respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]) {
        [self.currentService peripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
    }
}

- (RYCentralManager *)manager {
    
    return [RYCentralManager share];
}

@end
