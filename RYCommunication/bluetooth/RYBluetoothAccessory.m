//
//  RYBluetooth.m
//  Bluetooth
//
//  Created by ldc on 2019/11/26.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "RYBluetoothAccessory.h"
#import <IOBluetooth/IOBluetooth.h>
#import "RYResolver.h"

#define NeedLog 0
//#define TransferRateObserver 0


#ifndef NeedLog
#define NSLog(format, ...)
#endif

#ifdef TransferRateObserver
    static CFAbsoluteTime start;
    static UInt32 totalData = 0;
#endif

NSErrorDomain RYBluetoothConnectErrorDomain = @"h.bluetooth.connect.error.domain";

@interface RYBluetoothAccessory ()<IOBluetoothDeviceAsyncCallbacks, IOBluetoothRFCOMMChannelDelegate, RYDataWriteImmutablyProtocol>

@property (nonatomic, strong) IOBluetoothDevice *device;

@property (nonatomic, strong) IOBluetoothSDPServiceRecord *record;

@property (nonatomic, assign) BluetoothRFCOMMChannelID rfcomId;

@property (nonatomic, strong) IOBluetoothRFCOMMChannel *rfcom;

@property (nonatomic, assign) BOOL isConnected;

@property (nonatomic, copy) void (^ openSuccessBlock)(void);

@property (nonatomic, copy) void (^ openFailBlock)(NSError *);

@property (nonatomic, copy) void (^ progressBlock)(NSProgress *);

@property (nonatomic, assign) uint64_t totalUnitCount;

@property (nonatomic, strong) NSMutableData *writeData;

@property (nonatomic, assign) uint16_t bytesWritten;

@property (nonatomic, strong) NSTimer *authTimer;

- (instancetype)initWith:(IOBluetoothDevice *)device;

@end

@implementation RYBluetoothAccessory
@synthesize name;
@synthesize closedBlock;
@synthesize resolver;
@synthesize auth = _auth;

- (instancetype)initWith:(IOBluetoothDevice *)device {
    
    self = [super init];
    if (self) {
        self.device = device;
        self.writeData = [NSMutableData new];
        self.resolver = [[RYNotHandlingResolver alloc] init];
        self.auth = [[RYAuthorization alloc] init];
    }
    return self;
}

- (void)setAuth:(RYAuthorization *)auth {
    
    if (self.isConnected) {
        return;
    }
    _auth = auth;
}

- (void)connect:(void (^)(void))successBlock fail:(void (^)(NSError * _Nonnull))failBlock {
    
    if (self.isConnected) {
        NSError *e = [NSError errorWithDomain:RYBluetoothConnectErrorDomain code:RYBluetoothConnectErrorCodeDidConnect userInfo:nil];
        failBlock(e);
        return;
    }
    self.openSuccessBlock = successBlock;
    self.openFailBlock = failBlock;
    [self.device openConnection:self];
}

- (void)disconnect {
    
    self.isConnected = false;
    if (self.writeData.length > 0) {
        self.writeData = [NSMutableData new];
    }
    self.progressBlock = nil;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (self.rfcom.isOpen) {
            [self.rfcom closeChannel];
        }
        self.rfcom = nil;
        self.record = nil;
        if (self.device.isConnected) {
            [self.device closeConnection];
        }
    });
}

- (void)write:(NSData *)data progress:(void (^)(NSProgress * _Nonnull))block {
    
    self.progressBlock = block;
    NSData *temp = data;
    if (self.auth.dataEncryptBlock) {
        temp = self.auth.dataEncryptBlock(self.auth, data);
    }
    [self writeDataImmutably:temp];
}

- (void)writeDataImmutably:(NSData *)data {
    
    if (!self.rfcom.isOpen) {
        return;
    }
    BOOL isSending = self.writeData.length > 0;
#ifdef TransferRateObserver
    start = isSending ? start : CFAbsoluteTimeGetCurrent();
    totalData = isSending ? totalData + (uint32_t)data.length : (uint32_t)data.length;
#endif
    [self.writeData appendData:data];
    if (self.progressBlock) {
        if (isSending) {
            self.totalUnitCount += data.length;
        }else {
            self.totalUnitCount = data.length;
        }
    }
    if (!isSending) {
        [self p_sendNextPacket];
    }
}

- (void)stopWrite {}

- (void)p_sendNextPacket {
    
    _bytesWritten = MIN(self.rfcom.getMTU, self.writeData.length);
//    NSLog(@"将要写入数据: %u --- MTU: %u", _bytesWritten, self.rfcom.getMTU);
    [self.rfcom writeAsync:(void *)self.writeData.bytes length:_bytesWritten refcon:&_bytesWritten];
}

- (void)connectFailAction:(RYBluetoothConnectErrorCode)code {
    
    [self disconnect];
    if (self.openFailBlock) {
        NSError *e = [NSError errorWithDomain:RYBluetoothConnectErrorDomain code:code userInfo:nil];
        self.openFailBlock(e);
    }
    self.openFailBlock = nil;
    self.openFailBlock = nil;
}

- (void)connectSuccessAction {
    
    self.isConnected = true;
    if (self.openSuccessBlock) {
        self.openSuccessBlock();
    }
    self.openSuccessBlock = nil;
    self.openFailBlock = nil;
}

- (void)authTimeoutAction {
    
    [self connectFailAction:RYBluetoothConnectErrorCodeAuthTimeout];
    self.authTimer = nil;
    self.auth.authKey = nil;
    self.auth.validatedBlock = nil;
}

- (NSString *)name {
    
    return self.device.name;
}

#pragma mark --IOBluetoothDeviceAsyncCallbacks

- (void)connectionComplete:(IOBluetoothDevice *)device status:(IOReturn)status {
    
    if (status == kIOReturnSuccess) {
        NSLog(@"%@ 基带连接成功", device.name);
        [device performSDPQuery:self];
    }else {
        NSLog(@"%@ 基带连接失败--%i", device.name, status);
        [self connectFailAction:RYBluetoothConnectErrorCodeOpenBaseband];
    }
}

- (void)sdpQueryComplete:(IOBluetoothDevice *)device status:(IOReturn)status {
    
    if (status == kIOReturnSuccess) {
        NSLog(@"%@ sdp请求成功", device.name);
        BluetoothRFCOMMChannelID channelId;
        BluetoothRFCOMMChannelID minchannelId = 0xff;
        for (IOBluetoothSDPServiceRecord *record in device.services) {
            if ([record matchesUUIDArray:@[[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16RFCOMM], [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort]]]) {
                IOReturn r = [record getRFCOMMChannelID:&channelId];
                if (r == kIOReturnSuccess) {
                    if (minchannelId >= channelId) {
                        minchannelId = channelId;
                        self.record = record;
                    }
                }
            }
        }
        if (self.record) {
            IOReturn result = [self.record getRFCOMMChannelID:&_rfcomId];
            if (result == kIOReturnSuccess) {
                NSLog(@"RFCOMMChannel获取成功");
                IOBluetoothRFCOMMChannel *rfcom;
                result = [self.device openRFCOMMChannelAsync:&rfcom withChannelID:self.rfcomId delegate:self];
                if (result == kIOReturnSuccess) {
                    self.rfcom = rfcom;
                }else {
                    NSLog(@"打开RFCOMMChannel通道失败--%i", result);
                    [self connectFailAction:RYBluetoothConnectErrorCodeOpenRFCOMMChannel];
                }
            }else {
                NSLog(@"RFCOMMChannel获取失败: %i", result);
                [self connectFailAction:RYBluetoothConnectErrorCodeGetRFCOMMChannel];
            }
        }else {
            NSLog(@"没有找到合适的服务");
            [self connectFailAction:RYBluetoothConnectErrorCodeSDPServiceNotFound];
        }
    }else {
        NSLog(@"%@ sdp请求失败--%i", device.name, status);
        [self connectFailAction:RYBluetoothConnectErrorCodeSDPQuery];
    }
}

- (void)remoteNameRequestComplete:(IOBluetoothDevice *)device status:(IOReturn)status { }

#pragma mark --IOBluetoothRFCOMMChannelDelegate

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength {
    
    if (dataLength > 0) {
        if (!self.isConnected) {
            if (self.auth) {
                NSData *temp = [NSData dataWithBytes:dataPointer length:dataLength];
                NSLog(@"授权验证相关数据: %@", temp);
                [self.auth readInput:temp];
            }
        }else {
            if (self.resolver) {
                NSData *temp = [NSData dataWithBytes:dataPointer length:dataLength];
                NSLog(@"%@", temp);
                [self.resolver readInput:temp];
            }
        }
    }
}

- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error {
    
    if (error == kIOReturnSuccess) {
        NSLog(@"%@ 通道打开成功", NSStringFromSelector(_cmd));
        if (!self.auth) {
            [self connectSuccessAction];
        }else {
            self.authTimer = [NSTimer scheduledTimerWithTimeInterval:self.auth.timeout target:self selector:@selector(authTimeoutAction) userInfo:nil repeats:false];
            [self.auth startChallenge];
            __weak typeof(self) weakSelf = self;
            self.auth.validatedBlock = ^(RYAuthorizationResult result) {
                switch (result) {
                    case RYAuthorizationResultAuthorized:
                        [weakSelf.authTimer invalidate];
                        weakSelf.authTimer = nil;
                        weakSelf.auth.validatedBlock = nil;
                        [weakSelf connectSuccessAction];
                        break;
                    case RYAuthorizationResultDenied:
                        [weakSelf.authTimer invalidate];
                        weakSelf.authTimer = nil;
                        weakSelf.auth.authKey = nil;
                        weakSelf.auth.validatedBlock = nil;
                        [weakSelf connectFailAction:RYBluetoothConnectErrorCodeAuthFail];
                        break;
                    default:
                        break;
                }
            };
        }
    }else {
        NSLog(@"%@ 通道打开失败", NSStringFromSelector(_cmd));
        [self connectFailAction:RYBluetoothConnectErrorCodeOpenRFCOMMChannel];
    }
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel {
    
    BOOL connected = self.isConnected;
    [self disconnect];
    if (connected) {
        if (self.closedBlock) {
            self.closedBlock(nil);
        }
    }
}

- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel refcon:(void*)refcon status:(IOReturn)error {
    
    if (error == kIOReturnSuccess) {
        uint16_t bytesWritten = *((uint16_t *)refcon);
        NSLog(@"成功写入数据: %u", bytesWritten);
        [self.writeData replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
        if (self.writeData.length == 0) {
            if (self.progressBlock) {
                NSProgress *progress = [NSProgress progressWithTotalUnitCount:self.totalUnitCount];
                progress.completedUnitCount = self.totalUnitCount;
                self.progressBlock(progress);
                self.progressBlock = nil;
            }
            NSLog(@"发送完成");
#ifdef TransferRateObserver
            CFAbsoluteTime current = CFAbsoluteTimeGetCurrent();
            CFAbsoluteTime space = current - start;
            NSLog(@"传输用时: %fs",space);
            NSLog(@"速率: %f kb", totalData/space/1000);
#endif
        }else {
            if (self.progressBlock) {
                NSProgress *progress = [NSProgress progressWithTotalUnitCount:self.totalUnitCount];
                progress.completedUnitCount = self.totalUnitCount - self.writeData.length;
                self.progressBlock(progress);
            }
            [self p_sendNextPacket];
        }
    }else {
        [self disconnect];
        if (self.closedBlock) {
            self.closedBlock(nil);
        }
    }
}

@end

@interface RYBluetoothBrowser ()<IOBluetoothDeviceInquiryDelegate>

@property (nonatomic, strong) IOBluetoothDeviceInquiry *inquiry;

@property (nonatomic, assign) BOOL isScanning;

@property (nonatomic, strong) NSMutableDictionary<IOBluetoothDevice *, RYBluetoothAccessory *> *map;

@property (nonatomic, copy) void (^ completeScanBlock)(void);

@end

@implementation RYBluetoothBrowser

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.inquiry = [IOBluetoothDeviceInquiry inquiryWithDelegate:self];
        self.inquiry.updateNewDeviceNames = false;
        self.inquiry.inquiryLength = 5;
        self.map = [NSMutableDictionary new];
    }
    return self;
}

- (void)startScan:(BOOL)clearFoundDevice complete:(void (^)(void))completeBlock {
    
    if (self.isScanning) {
        return;
    }
    self.completeScanBlock = completeBlock;
    self.isScanning = true;
    if (clearFoundDevice) {
        self.map = [NSMutableDictionary new];
        [self.inquiry clearFoundDevices];
    }
    [self.inquiry start];
}

- (void)stopScan:(BOOL)clearFoundDevice {
    
    if (!self.isScanning) {
        return;
    }
    self.isScanning = false;
    [self.inquiry stop];
    if (clearFoundDevice) {
        self.map = [NSMutableDictionary new];
        [self.inquiry clearFoundDevices];
    }
}

- (NSArray<RYBluetoothAccessory *> *)devices {
    
    return self.map.allValues;
}

#pragma mark --IOBluetoothDeviceInquiryDelegate

- (void)deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry *)sender device:(IOBluetoothDevice *)device {
    
    if (self.map[device]) {
        return;
    }
    RYBluetoothAccessory *temp = [[RYBluetoothAccessory alloc] initWith:device];
    self.map[device] = temp;
}

- (void)deviceInquiryComplete:(IOBluetoothDeviceInquiry *)sender error:(IOReturn)error aborted:(BOOL)aborted {
    
    if (aborted) {
        NSLog(@"主动结束搜索");
    }else {
        if (error == kIOReturnSuccess) {
            NSLog(@"正常结束搜索");
        }else {
            NSLog(@"异常结束搜索--%i", error);
        }
    }
    if (self.completeScanBlock) {
        self.completeScanBlock();
    }
    self.completeScanBlock = nil;
    self.isScanning = false;
}

@end
