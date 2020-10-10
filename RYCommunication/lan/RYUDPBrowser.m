//
//  RYUDPBrowser.m
//  RYCommunication iOS
//
//  Created by ldc on 2020/10/10.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "RYUDPBrowser.h"
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import <arpa/inet.h>

@implementation RYUDPPortAccessory
@synthesize ip;
@synthesize advertisementData;

@end

@interface RYUDPBrowser ()<GCDAsyncUdpSocketDelegate>

@property (nonatomic, strong) NSMutableArray<id<RYUDPPort>> * _Nonnull printers;

@property (nonatomic, strong) GCDAsyncUdpSocket *socket;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, assign) BOOL isSearching;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) uint16_t port;

@end

@implementation RYUDPBrowser

- (instancetype)initWithPort:(uint16_t)port
{
    self = [super init];
    if (self) {
        self.port = port;
        self.printers = [[NSMutableArray alloc] init];
        self.queue = dispatch_queue_create("ry.udp.discover.queue", DISPATCH_QUEUE_SERIAL);
        [self createAndBindSocket];
    }
    return self;
}

- (void)createAndBindSocket {
    
    self.socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.socket setIPv6Enabled:false];
    NSError *error = nil;
    [self.socket enableBroadcast:true error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    [self.socket bindToPort:self.port error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
}

- (void)startSearch:(NSTimeInterval)timeout { 
    
    if (self.isSearching) {
        return;
    }
    NSLog(@"\nUDP开始搜索: ");
    self.isSearching = YES;
    if (self.socket.isClosed) {
        [self createAndBindSocket];
    }
    NSError *error;
    [self.socket beginReceiving:&error];
    if (error) {
        NSLog(@"监听socket监听数据接收失败: domain: %@, code: %ld -> %@", error.domain, (long)error.code, error.localizedDescription);
    }
    if (timeout > 0) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(searchTimeout) userInfo:nil repeats:false];
    }
}

- (void)broadcast {
    
    NSData *data = [NSData dataWithBytes:"\x0d\x0a" length:2];
    [self.socket sendData:data toHost:@"255.255.255.255" port:self.port withTimeout:2 tag:0];
}

- (void)searchTimeout {
    
    if (self.searchTimeoutBlock) {
        self.searchTimeoutBlock();
    }
    [self stopSearch];
}

- (void)stopSearch { 
    
    [self.timer invalidate];
    self.timer = nil;
    self.searchTimeoutBlock = nil;
    self.discovePortBlock = nil;
#if NeedLog
    [[HLog shared] write:[NSString stringWithFormat:@"结束搜索\n"]];
#endif
    [self.socket pauseReceiving];
    [self.socket close];
    [self.printers removeAllObjects];
    self.isSearching = NO;
}

- (NSArray<id<RYUDPPort>> *)ports {
    
    return self.printers;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    
    if (!self.isSearching) {
        return;
    }
    struct sockaddr_in *socket_address = (struct sockaddr_in *)address.bytes;
    char* ip_c = inet_ntoa(socket_address->sin_addr);
    NSString *ip = [[NSString alloc] initWithCString:ip_c encoding:NSUTF8StringEncoding];
    if ([ip isEqualToString:@"0.0.0.0"]) {
        return;
    }
    if (self.filterBlock) {
        if (!self.filterBlock(data)) {
            return;
        }
    }
    
    NSUInteger index = [self.printers indexOfObjectPassingTest:^BOOL(id<RYUDPPort>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.ip == ip) {
            return true;
        }else {
            return false;
        }
    }];
    if (index != NSNotFound) {
        return;
    }
    
    id<RYUDPPort> port;
    if (self.portGenerateBlock) {
        port = self.portGenerateBlock(data, ip);
    }else {
        port = [[RYUDPPortAccessory alloc] init];
        port.ip = ip;
        port.advertisementData = data;
    }
    
    [self.printers addObject:port];
    if (self.discovePortBlock) {
        self.discovePortBlock(port);
    }
}

@end
