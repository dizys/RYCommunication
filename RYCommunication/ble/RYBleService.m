//
//  RYBleService.m
//  HYEditor
//
//  Created by ldc on 2019/12/18.
//  Copyright © 2019 swiftHY. All rights reserved.
//

#import "RYBleService.h"
#import "RYBleConst.h"
#import "RYNotHandlingResolver.h"

#define WiFiConfigServiceUUID @"1B7E8251-2877-41C3-B46E-CF057C562023"
// Characteristic UUIDs
#define WiFiSSIDUUID           @"ACA0EF7C-EEAA-48AD-9508-19A6CEF6B356"
#define WiFiSecurityUUID       @"CAC2ABA4-EDBB-4C4A-BBAF-0A84A5CD93A1"
#define WiFiPasswordUUID        @"40B7DE33-93E4-4C8B-A876-D833B415A6CE"
#define CommandUUID             @"42B8DF34-94E5-4D8C-A978-D9745546B7BF"

@implementation RYBleService
@synthesize uuid;
@synthesize peripheral;
@synthesize configureSuccess;
@synthesize configureFail;
@synthesize resolver;
@synthesize closedBlock;
@synthesize auth;

- (void)connect:(void (^)(void))successBlock fail:(void (^)(NSError * _Nonnull))failBlock {}

- (void)disconnect {}

- (void)write:(NSData *)data progress:(void (^)(NSProgress * _Nonnull))block {}

- (void)stopWrite { [NSException raise:@"未实现" format:@""]; }

- (void)clear {}

@end

#pragma mark --CP4000

@interface CP4000lBleService ()

@property (nonatomic, strong) CBCharacteristic *security_c;

@property (nonatomic, strong) CBCharacteristic *ssid_c;

@property (nonatomic, strong) CBCharacteristic *password_c;

@property (nonatomic, strong) CBCharacteristic *command_c;

@property (nonatomic, strong) NSMutableData *writeData;
//刚连接时读取特征和注册通知特征会接收到一大堆数据，这个一般是不想要的，暂时有写入数据才开始让应用层接收数据
@property (nonatomic, assign) BOOL canAcceptInput;

@end

@implementation CP4000lBleService

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.uuid = [CBUUID UUIDWithString:WiFiConfigServiceUUID];
        self.resolver = [[RYNotHandlingResolver alloc] init];
        self.writeData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)clear {
    
    self.security_c = nil;
    self.ssid_c = nil;
    self.password_c = nil;
    self.writeData = [[NSMutableData alloc] init];
    self.canAcceptInput = false;
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error {
    
    if (error) {
        if (self.configureFail) {
            NSError *temp = [NSError errorWithDomain:RYBleConnectErrorDomain code:RYBleConnectErrorCodeSystemError userInfo:@{@"error": error}];
            self.configureFail(temp);
        }
        return;
    }
    for (CBCharacteristic *c in service.characteristics) {
        NSString *uuid = c.UUID.UUIDString;
        if ([uuid isEqualToString:WiFiSSIDUUID]) {
            self.ssid_c = c;
        }else if ([uuid isEqualToString:WiFiPasswordUUID]) {
            self.password_c = c;
        }else if ([uuid isEqualToString:WiFiSecurityUUID]) {
            self.security_c = c;
        }else if ([uuid isEqualToString:CommandUUID]) {
            self.command_c = c;
        }
        if ((c.properties & CBCharacteristicPropertyNotify) == CBCharacteristicPropertyNotify) {
            [peripheral setNotifyValue:true forCharacteristic:c];
        }
        if ((c.properties & CBCharacteristicPropertyRead) == CBCharacteristicPropertyRead) {
            [peripheral readValueForCharacteristic:c];
        }
    }
    if ([service.UUID.UUIDString isEqualToString:WiFiConfigServiceUUID]) {
        if (self.ssid_c && self.password_c && self.security_c && self.command_c) {
            if (self.configureSuccess) {
                self.configureSuccess();
            }
        }else {
            if (self.configureFail) {
                NSError *temp = [NSError errorWithDomain:RYBleConnectErrorDomain code:RYBleConnectErrorCodeCharacteristicNotFound userInfo:nil];
                self.configureFail(temp);
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (!self.canAcceptInput) {
        return;
    }
    if (characteristic.value && characteristic.value.length > 0 && (characteristic.properties & CBCharacteristicPropertyNotify) != 0) {
        #if NeedLog
        if (error) {
            [[HLog shared] write:[NSString stringWithFormat:@"更新数据失败=> 特征: %@ domain: %@ code: %lu -> %@", [[characteristic UUID] UUIDString], error.domain, error.code, error.localizedDescription]];
            return;
        }else {
            [[HLog shared] write:[NSString stringWithFormat:@"更新数据=> 特征: %@", [[characteristic UUID] UUIDString]]];
        }
        #endif
        [self.resolver readInput:characteristic.value];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error) {
    #if NeedLog
        [[HLog shared] write:[NSString stringWithFormat:@"写入失败=> 特征: %@ domain: %@ code: %lu -> %@", [[characteristic UUID] UUIDString], error.domain, error.code, error.localizedDescription]];
    #endif
        return;
    }
    @synchronized (self) {
        Byte *bytes = (Byte *)self.writeData.bytes;
        Byte length = bytes[2];
        [self.writeData replaceBytesInRange:NSMakeRange(0, 3+length) withBytes:NULL length:0];
        [self private_write];
    }
}

- (void)write:(NSData *)data progress:(void (^)(NSProgress * _Nonnull))block {
    
    self.canAcceptInput = true;
    @synchronized (self) {
        BOOL sending = false;
        if (self.writeData.length != 0) {
            sending = true;
        }
        [self.writeData appendData:data];
        [self private_write];
    }
}

- (void)private_write {
    
    Byte *bytes = (Byte *)self.writeData.bytes;
    int position = 0;
    while (true) {
        //分包头 0
        if (bytes[position] == 0) {
            break;
        }
        position++;
    }
    if (position != 0) {
        [self.writeData replaceBytesInRange:NSMakeRange(0, position) withBytes:NULL length:0];
    }
    if (self.writeData.length < 3) {
        return;
    }
    bytes = (Byte *)self.writeData.bytes;
    //数据类型 0 Wi-Fi名称 1 Wi-Fi密码 2 加密方式
    Byte type = bytes[1];
    //数据长度
    Byte length = bytes[2];
    if (self.writeData.length < 3 + length) {
        return;
    }
    NSData *temp = [self.writeData subdataWithRange:NSMakeRange(3, length)];
    CBCharacteristic *write_c;
    switch (type) {
        case 0:
            write_c = self.ssid_c;
            break;
        case 1:
            write_c = self.password_c;
            break;
        case 2:
            write_c = self.security_c;
            break;
        case 3:
            write_c = self.command_c;
            break;
        default:
            break;
    }
    if (write_c) {
        #if NeedLog
        [[HLog shared] write:[NSString stringWithFormat:@"写入=> 特征: %@ 数据: %@", write_c.UUID.UUIDString, [temp oc_hexString]]];
        #endif
        [self.peripheral writeValue:temp forCharacteristic:write_c type:CBCharacteristicWriteWithResponse];
    }
}

@end

#pragma mark --FF00

typedef NS_OPTIONS(UInt8, FF00ServiceProcess) {
    FF00ServiceProcessLoadWriteCharacteristic = 1,
    FF00ServiceProcessLoadMTU = 1 << 1,
    FF00ServiceProcessLoadCredit = 1 << 2,
    FF00ServiceProcessLoadReadCharacteristic = 1 << 3,
    FF00ServiceProcessLoadOK = 0x0f,
};

@interface FF00BleService ()

@property (nonatomic, strong) NSMutableData *writeData;

@property (nonatomic, assign) Byte mtu;

@property (nonatomic, assign) Byte credit;

@property (nonatomic, strong) CBCharacteristic *write_c;

@property (nonatomic, assign) FF00ServiceProcess process;

@property (nonatomic, copy) void (^ progressBlock)(NSProgress *);

@property (nonatomic, assign) uint64_t totalBytes;

@property (nonatomic, assign) uint64_t remainBytes;

@end

@implementation FF00BleService

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.writeData = [[NSMutableData alloc] init];
        self.uuid = [CBUUID UUIDWithString:@"FF00"];
        self.resolver = [[RYNotHandlingResolver alloc] init];
    }
    return self;
}

- (void)clear {
    
    self.writeData = [[NSMutableData alloc] init];
    self.write_c = nil;
    self.process = 0;
}

- (void)write:(NSData *)data progress:(void (^)(NSProgress * _Nonnull))block {
    
    @synchronized (self) {
        self.progressBlock = block;
        BOOL sending = false;
        if (self.writeData.length > 0) {
            sending = true;
            self.totalBytes += data.length;
            self.remainBytes += data.length;
        }else {
            self.totalBytes = data.length;
            self.remainBytes = data.length;
        }
        [self.writeData appendData:data];
        if (!sending) {
            [self private_write];
        }
    }
}

- (void)private_write {
    
    while (self.credit > 0 && self.remainBytes > 0) {
        NSUInteger byteWritten = (NSUInteger)MIN(self.remainBytes, self.mtu);
        NSRange range = NSMakeRange(self.writeData.length - (NSUInteger)self.remainBytes, byteWritten);
        NSData *data = [self.writeData subdataWithRange:range];
        [self.peripheral writeValue:data forCharacteristic:self.write_c type:CBCharacteristicWriteWithoutResponse];
        self.credit--;
        self.remainBytes -= range.length;
    }
}

- (void)judgeConfigureResult {
    
    if (self.process == FF00ServiceProcessLoadOK) {
        if (self.configureSuccess) {
            self.configureSuccess();
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error {
    
    if (error) {
        if (self.configureFail) {
            NSError *temp = [NSError errorWithDomain:RYBleConnectErrorDomain code:RYBleConnectErrorCodeSystemError userInfo:@{@"error": error}];
            self.configureFail(temp);
        }
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSString *uuid = characteristic.UUID.UUIDString;
        if ([uuid isEqualToString:@"FF02"]) {
            self.write_c = characteristic;
            self.process |= FF00ServiceProcessLoadWriteCharacteristic;
        }
        if ((characteristic.properties & CBCharacteristicPropertyRead) != 0) {
            [self.peripheral readValueForCharacteristic:characteristic];
        }
        if ((characteristic.properties & CBCharacteristicPropertyNotify) != 0) {
            [self.peripheral setNotifyValue:true forCharacteristic:characteristic];
        }
    }
    [self judgeConfigureResult];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if ([characteristic.UUID.UUIDString isEqualToString:@"FF01"]) {
        self.process |= FF00ServiceProcessLoadReadCharacteristic;
        [self judgeConfigureResult];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    if ([characteristic.UUID.UUIDString isEqualToString:@"FF03"]) {
        
        unsigned char * measureData = (unsigned char *) [characteristic.value bytes];
        unsigned char field = * measureData;
        measureData++;
        if (self.process != FF00ServiceProcessLoadOK) {
            if(field == 2){
                unsigned char low = * measureData;
                measureData++;
                self.mtu = low + (* measureData << 8);
                self.process |= FF00ServiceProcessLoadMTU;
                [self judgeConfigureResult];
            }
            if (field == 1) {
                self.credit = *measureData;
                self.process |= FF00ServiceProcessLoadCredit;
                [self judgeConfigureResult];
            }
        }else {
            if (field == 1) {
                @synchronized (self) {
                    Byte c = *measureData;
                    uint64_t sended = MIN(c*self.mtu, self.writeData.length - self.remainBytes);
                    [self.writeData replaceBytesInRange:NSMakeRange(0, (NSUInteger)sended) withBytes:NULL length:0];
                    NSProgress *progress = [[NSProgress alloc] init];
                    progress.totalUnitCount = self.totalBytes;
                    progress.completedUnitCount = self.totalBytes - self.writeData.length;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.progressBlock) {
                            self.progressBlock(progress);
                        }
                        if (progress.totalUnitCount == progress.completedUnitCount) {
                            self.progressBlock = nil;
                        }
                    });
                    self.credit += *measureData;
                    [self private_write];
                }
            }
        }
    }else {
        if (characteristic.value && characteristic.value.length > 0) {
            [self.resolver readInput:characteristic.value];
        }
    }
}

@end
