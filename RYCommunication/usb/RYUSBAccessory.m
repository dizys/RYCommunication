//
//  RYUSB.m
//  USBExample
//
//  Created by ldc on 2019/11/21.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "RYUSBAccessory.h"
#import "RYThread.h"
#import <IOKit/usb/IOUSBLib.h>
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

RYUSBPredicateKey RYUSBVendorIdKey = @"vendorId";

RYUSBPredicateKey RYUSBProductIdKey = @"productId";

NSErrorDomain RYUSBConnectErrorDomain = @"h.usb.connect.error.domain";

@class RYUSB;
@class RYUSBAccessory;

@interface RYUSBPipe : NSObject

@property (nonatomic, assign) UInt8 direction;

@property (nonatomic, assign) UInt8 number;

@property (nonatomic, assign) UInt8 transferType;

@property (nonatomic, assign) UInt16 maxPacketSize;

@property (nonatomic, assign) UInt8 interval;

@property (nonatomic, assign) int ref;

@property (nonatomic, assign) BOOL outDirection;

@property (nonatomic, assign) BOOL inDirection;

@end

@implementation RYUSBPipe

- (NSString *)directionDescription {
    
    NSString *desc = @"????";
    switch (self.direction) {
        case kUSBOut:
            desc = @"out";
            break;
        case kUSBIn:
            desc = @"in";
            break;
        case kUSBNone:
            desc = @"none";
            break;
        case kUSBAnyDirn:
            desc = @"any";
            break;
        default:
            break;
    }
    return desc;
}

- (NSString *)transferTypeDescription {
    
    NSString *desc = @"????";
    switch (self.transferType) {
        case kUSBControl:
            desc = @"control";
            break;
        case kUSBIsoc:
            desc = @"isoc";
            break;
        case kUSBBulk:
            desc = @"bulk";
            break;
        case kUSBInterrupt:
            desc = @"interrupt";
            break;
        case kUSBAnyType:
            desc = @"any";
            break;
        default:
            break;
    }
    return desc;
}

- (BOOL)inDirection {
    
    return self.direction == kUSBIn;
}

- (BOOL)outDirection {
    
    return self.direction == kUSBOut;
}

@end

@interface RYUSBAccessory () <RYDataWriteImmutablyProtocol>

@property (nonatomic, assign) IOUSBDeviceInterface **interface;

@property (nonatomic, assign) io_service_t service;

@property (nonatomic, assign) IOUSBInterfaceInterface **interfaceinterface;

@property (nonatomic, strong) RYUSBPipe *writePipe;

@property (nonatomic, strong) RYUSBPipe *readPipe;

@property (nonatomic, assign) void *buffer;

@property (nonatomic, strong) NSMutableArray<RYUSBPipe *> *pipes;

@property (nonatomic, strong) NSMutableData *writeData;

@property (nonatomic, assign) BOOL opened;

@property (nonatomic, assign) CFRunLoopSourceRef source;

@property (nonatomic, copy) void (^ openSuccessBlock)(void);

@property (nonatomic, copy) void (^ openFailBlock)(NSError *);

@property (nonatomic, assign) uint64_t totalUnitCount;

@property (nonatomic, strong) void (^ progressBlock)(NSProgress *);

@property (nonatomic, strong) NSTimer *authTimer;

@property (nonatomic, assign) BOOL isConnected;

- (instancetype)initWith:(NSString *)name interface:(IOUSBDeviceInterface **)interface service:(io_service_t)service;

- (void)p_readData;

- (void)p_close;

- (void)connectSuccessAction;

- (void)connectFailAction:(RYUSBConnectErrorCode)code;

@end

#define ReadBufferLength 128

void RYUSBPipeDidRead(void *refcon, IOReturn result, void *arg0) {
    
//    NSLog(@"%@--RYUSBPipeDidRead", [NSThread currentThread]);
    RYUSBAccessory *interface = (__bridge RYUSBAccessory *)refcon;
    if (!interface.opened) {
        return;
    }
    IOUSBInterfaceInterface **interfaceinterface = interface.interfaceinterface;
    UInt32 bytesRead = (UInt32)arg0;
    if (result != kIOReturnSuccess || interfaceinterface == NULL) {
        NSLog(@"error from async bulk read (%08x)\n", result);
        [interface p_close];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (interface.closedBlock) {
                interface.closedBlock(nil);
            }
        });
        return;
    }
    if (bytesRead == 0) {
        [interface performSelector:@selector(p_readData) withObject:nil afterDelay:0.06];
        return;
    }
    NSData *data = [NSData dataWithBytes:interface.buffer length:bytesRead];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (data.length > 0) {
            if (!interface.isConnected) {
                if (interface.auth) {
                    NSLog(@"授权验证相关数据: %@", data);
                    [interface.auth readInput:data];
                }
            }else {
                if (interface.resolver) {
                    NSLog(@"%@", data);
                    [interface.resolver readInput:data];
                }
            }
        }
    });
    (*interfaceinterface)->ReadPipeAsync(interfaceinterface, interface.readPipe.ref, interface.buffer, ReadBufferLength, RYUSBPipeDidRead, (__bridge void *)interface);
}

void RYUSBPipeDidWrite(void *refcon, IOReturn result, void *arg0) {
    
//    NSLog(@"%@--RYUSBPipeDidWrite", [NSThread currentThread]);
    RYUSBAccessory *interface = (__bridge RYUSBAccessory *)refcon;
    if (!interface.opened) {
        return;
    }
    UInt32 bytesWritten = (UInt32)arg0;
    IOUSBInterfaceInterface **interfaceinterface = interface.interfaceinterface;
    if (result != kIOReturnSuccess || interfaceinterface == NULL) {
        NSLog(@"error from asynchronous bulk write (%08x)\n", result);
        [interface p_close];
        dispatch_async(dispatch_get_main_queue(), ^{
            interface.progressBlock = nil;
            if (interface.closedBlock) {
                interface.closedBlock(nil);
            }
        });
        return;
    }
    if (interface.writeData.length <= bytesWritten) {
        //数据写完
        if (interface.progressBlock) {
            NSProgress *progress = [NSProgress progressWithTotalUnitCount:interface.totalUnitCount];
            progress.completedUnitCount = interface.totalUnitCount;
            dispatch_async(dispatch_get_main_queue(), ^{
                interface.progressBlock(progress);
                interface.progressBlock = nil;
            });
        }
#ifdef TransferRateObserver
        CFAbsoluteTime current = CFAbsoluteTimeGetCurrent();
        CFAbsoluteTime space = current - start;
        NSLog(@"传输用时: %fs",space);
        NSLog(@"速率: %f kb", totalData/space/1000);
#endif
        interface.writeData = [NSMutableData new];
    }else {
//        NSLog(@"写入: %u", bytesWritten);
        [interface.writeData replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
        if (interface.progressBlock) {
            NSProgress *progress = [NSProgress progressWithTotalUnitCount:interface.totalUnitCount];
            progress.completedUnitCount = interface.totalUnitCount - interface.writeData.length;
            dispatch_async(dispatch_get_main_queue(), ^{
                interface.progressBlock(progress);
            });
        }
        UInt32 writeLength = (UInt32)MIN(interface.writeData.length, interface.writePipe.maxPacketSize);
        (*interfaceinterface)->WritePipeAsync(interfaceinterface, interface.writePipe.ref, (void *)(interface.writeData.bytes), writeLength, RYUSBPipeDidWrite, (__bridge void *)interface);
    }
}

@implementation RYUSBAccessory
@synthesize resolver;
@synthesize closedBlock;
@synthesize name;
@synthesize auth = _auth;

- (instancetype)initWith:(NSString *)name interface:(IOUSBDeviceInterface **)interface service:(io_service_t)service {
    
    self = [super init];
    self.writeData = [NSMutableData new];
    self.buffer = calloc(ReadBufferLength, 1);
    self.name = name;
    self.interface = interface;
    self.service = service;
    self.resolver = [[RYNotHandlingResolver alloc] init];
    self.auth = [[RYAuthorization alloc] init];
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
        NSError *error = [NSError errorWithDomain:RYUSBConnectErrorDomain code:RYUSBConnectErrorCodeDidConnect userInfo:nil];
        failBlock(error);
        return;
    }
    self.openSuccessBlock = successBlock;
    self.openFailBlock = failBlock;
    [self performSelector:@selector(p_open) onThread:[RYThread thread] withObject:nil waitUntilDone:false];
}

- (void)disconnect {
    
    [self performSelector:@selector(p_close) onThread:[RYThread thread] withObject:nil waitUntilDone:false];
}

- (void)write:(NSData *)data progress:(void (^)(NSProgress * _Nonnull))block {
    
    self.progressBlock = block;
    NSData *temp = data;
    if (self.auth.dataEncryptBlock) {
        temp = self.auth.dataEncryptBlock(self.auth, data);
    }
    [self performSelector:@selector(writeDataImmutably:) onThread:[RYThread thread] withObject:temp waitUntilDone:false];
}

- (void)stopWrite {}

#pragma mark --私有

- (void)connectFailAction:(RYUSBConnectErrorCode)code {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.openFailBlock) {
            NSError *e = [NSError errorWithDomain:RYUSBConnectErrorDomain code:code userInfo:nil];
            self.openFailBlock(e);
        }
        self.openSuccessBlock = nil;
        self.openFailBlock = nil;
    });
}

- (void)connectSuccessAction {
    
    self.isConnected = true;
    self.opened = true;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.openSuccessBlock) {
            self.openSuccessBlock();
        }
        self.openSuccessBlock = nil;
        self.openFailBlock = nil;
    });
}

- (void)authTimeoutAction {
    
    [self p_close];
    [self connectFailAction:RYUSBConnectErrorCodeAuthTimeout];
    self.authTimer = nil;
    self.auth.authKey = nil;
    self.auth.validatedBlock = nil;
}

- (void)p_open {
    
    IOUSBFindInterfaceRequest request;
    request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting = kIOUSBFindInterfaceDontCare;
    
    io_iterator_t iterator;
    IOReturn kr;
    IOCFPlugInInterface **plugInInterface = NULL;
    SInt32 score;
    HRESULT result;
    UInt8                       endpointNum;
    
    kr = (*_interface)->CreateInterfaceIterator(_interface, &request, &iterator);
    io_service_t service;
    while ((service = IOIteratorNext(iterator))) {
        kr = IOCreatePlugInInterfaceForService(service, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);
        kr = IOObjectRelease(service);
        if ((kr != kIOReturnSuccess) || !plugInInterface)
        {
            NSLog(@"Unable to create a plug-in (%08x)\n", kr);
            [self connectFailAction:RYUSBConnectErrorCodeCreatePlugInInterface];
            return;
        }
        result = (*plugInInterface)->QueryInterface(plugInInterface,
                           CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                           (LPVOID *) &_interfaceinterface);
        (*plugInInterface)->Release(plugInInterface);
        if (result || !_interfaceinterface) {
            NSLog(@"Couldn’t create a device interface for the interface(%08x)\n", (int) result);
            [self connectFailAction:RYUSBConnectErrorCodeQueryInterface];
            return;
        }
        kr = (*_interfaceinterface)->USBInterfaceOpen(_interfaceinterface);
        if (kr != kIOReturnSuccess)
        {
            NSLog(@"Unable to open interface (%08x)\n", kr);
            (*_interfaceinterface)->Release(_interfaceinterface);
            [self connectFailAction:RYUSBConnectErrorCodeInterfaceOpen];
            return;
        }
        kr = (*_interfaceinterface)->GetNumEndpoints(_interfaceinterface, &endpointNum);
        if (kr != kIOReturnSuccess)
        {
            NSLog(@"Unable to get number of endpoints (%08x)\n", kr);
            [self p_close];
            [self connectFailAction:RYUSBConnectErrorCodeGetNumEndpoints];
            return;
        }
        self.pipes = [NSMutableArray new];
        for (int i = 1; i <= endpointNum; i++) {
            IOReturn        kr2;
            UInt8           direction;
            UInt8           number;
            UInt8           transferType;
            UInt16          maxPacketSize;
            UInt8           interval;
            RYUSBPipe *pipe = [RYUSBPipe new];
            kr2 = (*_interfaceinterface)->GetPipeProperties(_interfaceinterface, i, &direction, &number, &transferType, &maxPacketSize, &interval);
            if (kr2 != kIOReturnSuccess) {
                NSLog(@"Unable to get properties of pipe %d (%08x)\n", i, kr2);
                break;
            }
            pipe.direction = direction;
            pipe.number = number;
            pipe.transferType = transferType;
            pipe.maxPacketSize = maxPacketSize;
            pipe.interval = interval;
            pipe.ref = i;
            [self.pipes addObject:pipe];
        }
        
        NSInteger index = [self.pipes indexOfObjectPassingTest:^BOOL(RYUSBPipe * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return obj.outDirection;
        }];
        if (index == NSNotFound) {
            NSLog(@"out direction pipe not found.");
            [self p_close];
            [self connectFailAction:RYUSBConnectErrorCodeOutPipeNotFound];
            return;
        }
        self.writePipe = self.pipes[index];
        
        index = [self.pipes indexOfObjectPassingTest:^BOOL(RYUSBPipe * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return obj.inDirection;
        }];
        if (index == NSNotFound) {
            NSLog(@"in direction pipe not found.");
            [self p_close];
            [self connectFailAction:RYUSBConnectErrorCodeInPipeNotFound];
            return;
        }
        self.readPipe = self.pipes[index];
        
        CFRunLoopSourceRef source;
        kr = (*_interfaceinterface)->CreateInterfaceAsyncEventSource(_interfaceinterface, &source);
        if (kr != kIOReturnSuccess)
        {
            NSLog(@"Unable to create asynchronous event source(%08x)\n", kr);
            [self p_close];
            [self connectFailAction:RYUSBConnectErrorCodeCreateAsyncEventSource];
            return;
        }
        self.source = source;
        CFRunLoopAddSource(CFRunLoopGetCurrent(), self.source, kCFRunLoopDefaultMode);
        kr = (*_interfaceinterface)->ReadPipeAsync(_interfaceinterface, self.readPipe.ref, self.buffer, ReadBufferLength, RYUSBPipeDidRead, (__bridge void *)self);
        if (kr != kIOReturnSuccess)
        {
            NSLog(@"Unable to perform asynchronous bulk write (%08x)\n", kr);
            [self p_close];
            [self connectFailAction:RYUSBConnectErrorCodeBeginReadPipe];
            return;
        }
        self.opened = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.auth) {
                [self connectSuccessAction];
            }else {
                self.authTimer = [NSTimer scheduledTimerWithTimeInterval:self.auth.timeout target:self selector:@selector(authTimeoutAction) userInfo:nil repeats:false];
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
                            [weakSelf connectFailAction:RYUSBConnectErrorCodeAuthFail];
                            break;
                        default:
                            break;
                    }
                };
            }
        });
        return;
    }
    [self connectFailAction:RYUSBConnectErrorCodeInterfaceinterfaceServiceNotFound];
}

- (void)p_close {
    
    if (!self.opened) {
        return;
    }
    self.isConnected = false;
    self.progressBlock = nil;
    self.writeData = [NSMutableData new];
    self.opened = false;
    if (_interfaceinterface) {
        (*_interfaceinterface)->USBInterfaceClose(_interfaceinterface);
        (*_interfaceinterface)->Release(_interfaceinterface);
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), self.source, kCFRunLoopDefaultMode);
    }
    _interfaceinterface = NULL;
}

- (void)writeDataImmutably:(NSData *)data {
    
    if (!self.opened) {
        return;
    }
    BOOL sending = false;
    if (self.writeData.length > 0) {
        sending = true;
    }
    [self.writeData appendData:data];
#ifdef TransferRateObserver
    start = CFAbsoluteTimeGetCurrent();
    totalData = (UInt32)self.writeData.length;
#endif
    if (self.progressBlock) {
        if (sending) {
            self.totalUnitCount += data.length;
        }else {
            self.totalUnitCount = data.length;
        }
    }
    if (!sending) {
        UInt32 writeLength = (UInt32)MIN(self.writeData.length, self.writePipe.maxPacketSize);
        IOReturn r = (*_interfaceinterface)->WritePipeAsync(_interfaceinterface, self.writePipe.ref, (void *)self.writeData.bytes, writeLength, RYUSBPipeDidWrite, (__bridge void *)self);
        if (r != kIOReturnSuccess) {
            NSLog(@"write fail %i", r);
            [self p_close];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressBlock = nil;
                if (self.closedBlock) {
                    self.closedBlock(nil);
                }
            });
        }
    }
}

- (void)p_readData {
    
    if (_interfaceinterface) {
        (*_interfaceinterface)->ReadPipeAsync(_interfaceinterface, self.readPipe.ref, self.buffer, ReadBufferLength, RYUSBPipeDidRead, (__bridge void *)self);
    }
}

- (UInt16)vendorId {
    
    (*_interface)->GetDeviceVendor(_interface, &_vendorId);
    return _vendorId;
}

- (UInt16)productId {
    
    (*_interface)->GetDeviceProduct(_interface, &_productId);
    return _productId;
}

- (BOOL)isEqual:(id)object {
    
    if ([object isMemberOfClass:[self class]]) {
        return false;
    }
    return IOObjectIsEqualTo(self.service, ((RYUSBAccessory *)object).service);
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"name->%@  vendorId->%04x  productId->%04x", self.name, self.vendorId, self.productId];
}

- (void)dealloc {
    
    [self p_close];
    IOObjectRelease(self.service);
    free(self.buffer);
    (*_interface)->Release(_interface);
}

@end

void RYUSBAccessoryAdded(void *ref, io_iterator_t iterator) {

//    NSLog(@"%@--RYUSBAccessoryAdded", [NSThread currentThread]);
    IOReturn                    kr;
    IOUSBFindInterfaceRequest   request;
    IOCFPlugInInterface         **plugInInterface = NULL;
    HRESULT                     result;
    SInt32                      score;

    request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting = kIOUSBFindInterfaceDontCare;

    io_service_t service;
    IOUSBDeviceInterface **interface=NULL;
    RYUSBBrowser *usb = (__bridge RYUSBBrowser *)ref;

    while ((service = IOIteratorNext(iterator))) {

        kr = IOCreatePlugInInterfaceForService(service, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);
        io_name_t name;
        kr = IORegistryEntryGetName(service, name);
        if ((kr != kIOReturnSuccess)) {
            NSLog(@"Get Name Fail.");
            continue;
        }
        CFStringRef nameRef = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingUTF8);
        
        if ((kr != kIOReturnSuccess) || !plugInInterface)
        {
            NSLog(@"Unable to create a plug-in (%08x)\n", kr);
            continue;
        }

        result = (*plugInInterface)->QueryInterface(plugInInterface,
                    CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                    (LPVOID *) &interface);
        (*plugInInterface)->Release(plugInInterface);
        plugInInterface = NULL;

        if (result || !interface)
        {
            NSLog(@"Couldn’t create a device interface for the interface(%08x)\n", (int) result);
            continue;
        }
        UInt16 vendorId;
        (*interface)->GetDeviceVendor(interface, &vendorId);
        if (vendorId == 0x05ac) {
            (*interface)->Release(interface);
            interface = NULL;
            continue;
        }
        RYUSBAccessory *usb_interface = [[RYUSBAccessory alloc] initWith:(__bridge NSString *)nameRef interface:interface service:service];
        [usb.interfaces addObject:usb_interface];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (usb.interfaceAddBlock) {
                usb.interfaceAddBlock(usb_interface);
            }
        });
    }
}

void RYUSBAccessoryRemoved(void *ref, io_iterator_t iterator) {
    
    NSLog(@"%@--RYUSBAccessoryRemoved", [NSThread currentThread]);
    io_service_t service;
    RYUSBBrowser *usb = (__bridge RYUSBBrowser *)ref;

    while ((service = IOIteratorNext(iterator))) {
        NSInteger index = [usb.interfaces indexOfObjectPassingTest:^BOOL(RYUSBAccessory * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return IOObjectIsEqualTo(obj.service, service);
        }];
        if (index != NSNotFound) {
            RYUSBAccessory *interface = usb.interfaces[index];
            [usb.interfaces removeObject:interface];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (interface.opened && interface.closedBlock) {
                    interface.closedBlock(nil);
                }
                if (usb.interfaceRemoveBlock) {
                    usb.interfaceRemoveBlock(interface);
                }
            });
        }
        IOObjectRelease(service);
    }
}

@interface RYUSBBrowser ()

@property (nonatomic, assign) IONotificationPortRef notify;

@property (nonatomic, assign) io_iterator_t add_iterator;

@property (nonatomic, assign) io_iterator_t remove_interator;

@property (nonatomic, assign) BOOL methodResult;

@end

@implementation RYUSBBrowser

+ (instancetype)share {
    
    static dispatch_once_t onceToken;
    static RYUSBBrowser *browser;
    dispatch_once(&onceToken, ^{
        browser = [[self alloc] init];
    });
    return browser;
}

- (BOOL)scanInterfaces:(NSMutableDictionary<RYUSBPredicateKey, id> *) predicate {
    
    [self performSelector:@selector(p_scanInterfaces:) onThread:[RYThread thread] withObject:predicate waitUntilDone:true];
    return self.methodResult;
}

- (void)stopScanInterfaces {
    
    [self performSelector:@selector(p_stopScanInterfaces) onThread:[RYThread thread] withObject:nil waitUntilDone:true];
}

#pragma mark --私有

- (void)p_scanInterfaces:(NSMutableDictionary<RYUSBPredicateKey, id> *) predicate {
    
    CFMutableDictionaryRef dic = IOServiceMatching(kIOUSBDeviceClassName);
    if (dic == NULL) {
        fprintf(stdin, "IOServiceMatching returned NULL.\n");
        self.methodResult = false;
        return;
    }
    if (self.isScanning) {
        [NSException raise:@"" format:@"不能在扫描状态开启另一段扫描: %@", NSStringFromSelector(_cmd)];
    }
    self.isScanning = true;
    if (predicate) {
        id vendorId = predicate[RYUSBVendorIdKey];
        if ([vendorId isKindOfClass:[NSNumber class]]) {
            CFDictionarySetValue(dic,
            CFSTR(kUSBVendorID),
            (__bridge CFNumberRef)vendorId);
        }
        id productId = predicate[RYUSBProductIdKey];
        if ([vendorId isKindOfClass:[NSNumber class]]) {
            CFDictionarySetValue(dic,
            CFSTR(kUSBProductID),
            (__bridge CFNumberRef)productId);
        }
    }
    
    CFDictionaryRef _dic = CFDictionaryCreateCopy(kCFAllocatorDefault, dic);
    
    self.notify = IONotificationPortCreate(kIOMasterPortDefault);
    CFRunLoopSourceRef source = IONotificationPortGetRunLoopSource(self.notify);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
    IOServiceAddMatchingNotification(self.notify, kIOFirstMatchNotification, dic, RYUSBAccessoryAdded, (__bridge void *)self, &_add_iterator);
    RYUSBAccessoryAdded((__bridge void *)self, _add_iterator);
    
    IOServiceAddMatchingNotification(self.notify, kIOTerminatedNotification, _dic, RYUSBAccessoryRemoved, (__bridge void *)self, &_remove_interator);
    RYUSBAccessoryRemoved((__bridge void *)self, _remove_interator);
    self.methodResult = true;
}

- (void)p_stopScanInterfaces {
    
    if (self.isScanning) {
        [self.interfaces removeAllObjects];
        self.isScanning = false;
        IONotificationPortDestroy(self.notify);
        IOObjectRelease(self.add_iterator);
        IOObjectRelease(self.remove_interator);
    }
}

- (NSMutableArray<RYUSBAccessory *> *)interfaces {
    
    if (!_interfaces) {
        _interfaces = [NSMutableArray new];
    }
    return _interfaces;
}

- (void)dealloc {
    if (self.isScanning) {
        IONotificationPortDestroy(self.notify);
        IOObjectRelease(self.add_iterator);
        IOObjectRelease(self.remove_interator);
    }
}

@end
