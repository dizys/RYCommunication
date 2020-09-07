//
//  RYStreamPair.m
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import "RYStreamPair.h"
#import "RYNotHandlingResolver.h"

NSErrorDomain RYStreamPairConnectErrorDomain = @"ry.stream.pair.connect";

typedef NS_ENUM(UInt8, RYStreamPairConnectFlag) {
    RYStreamPairConnectFlagInputStreaRYonnected     =   1,
    RYStreamPairConnectFlagOutputStreaRYonnected    =   2,
    RYStreamPairConnectFlagAllStreaRYonnected       =   3
};

@interface RYStreamPair()<NSStreamDelegate>

@property (nonatomic, assign) UInt64 writeDataLength;

@property (nonatomic, strong) NSMutableData *data;

@property (nonatomic, copy) void(^progressBlock)(NSProgress *);

@property (nonatomic, assign) BOOL paused;

@property (nonatomic, assign, readwrite) BOOL connected;

@property (nonatomic, copy) void(^successBlock)(void);

@property (nonatomic, copy) void(^failBlock)(NSError *);

@property (nonatomic, assign) RYStreamPairConnectFlag connectFlag;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation RYStreamPair
@synthesize resolver;
@synthesize closedBlock;

+ (void)threadEntry:(id) __unused object {
    
    @autoreleasepool {
        [NSThread currentThread].name = @"stream.pair.thread";
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runloop run];
    }
}

+ (NSThread *)thread {
    
    static dispatch_once_t onceToken;
    static NSThread *thread = nil;
    dispatch_once(&onceToken, ^{
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadEntry:) object:nil];
        [thread start];
    });
    return thread;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.connected = false;
        //使用懒加载时,如果子线程第一次调用get,会导致后面get方法不再被调用。。。。
        self.resolver = [[RYNotHandlingResolver alloc] init];
        self.data = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)connect:(void (^)(void))successBlock fail:(void (^)(NSError * _Nonnull))failBlock {
    
    if (self.connected) {
        if (successBlock) {
            successBlock();
        }
        return;
    }
    if (self.input && self.output) {
        self.successBlock = successBlock;
        self.failBlock = failBlock;
        [self performSelector:@selector(connectStreamPair) onThread:[[self class] thread] withObject:nil waitUntilDone:false];
    }else {
        if (failBlock) {
            NSError *error = [NSError errorWithDomain:RYStreamPairConnectErrorDomain code:RYStreamPairConnectErrorCodeEmptyStreamObject userInfo:@{@"message": @"Attempt to connect a RYStreamPair object without stream object"}];
            failBlock(error);
        }
    }
}

- (void)connectStreamPair {
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(connectTimeout) userInfo:nil repeats:false];
    self.connectFlag = 0;
    self.input.delegate = self;
    [self.input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.input open];
    self.output.delegate = self;
    [self.output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.output open];
}

- (void)disconnect {
    
    if (self.connected) {
        [self performSelector:@selector(closeStream) onThread:[[self class] thread] withObject:nil waitUntilDone:true];
    }
}

- (void)write:(NSData *)data progress:(void (^)(NSProgress * _Nonnull))block {
    
    self.paused = NO;
    if (self.data.length == 0) {
        self.writeDataLength = 0;
    }
    [self.data appendData:data];
    self.writeDataLength += data.length;
    self.progressBlock = block;
    [self performSelector:@selector(writeData) onThread:[[self class] thread] withObject:nil waitUntilDone:false];
}

- (void)stopWrite {
    
    [self performSelector:@selector(privateClearData) onThread:[[self class] thread] withObject:nil waitUntilDone:true];
}

- (void)privateClearData {
    
    self.progressBlock = nil;
    self.data = [NSMutableData data];
}

- (void)pauseWriteData {
    
    self.paused = YES;
}

- (void)resumeWriteData {
    
    self.paused = NO;
    [self performSelector:@selector(writeData) onThread:[[self class] thread] withObject:nil waitUntilDone:false];
}

- (void)streamDidDisconnect {
    
    if (self.closedBlock) {
        self.closedBlock();
    }
}

- (void)streamDidReadInputData:(NSData *)data {
    
    if (self.resolver && data && data.length > 0) {
        [self.resolver readInput:data];
    }
}

- (void)connectTimeout {
    
    NSLog(@"连接超时");
    [self closeStream];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.failBlock) {
            NSError *error = [NSError errorWithDomain:RYStreamPairConnectErrorDomain code:RYStreamPairConnectErrorCodeTimeout userInfo:@{@"message": @"connect a RYStreamPair object timeout"}];
            self.failBlock(error);
        }
        self.successBlock = nil;
        self.failBlock = nil;
    });
}

- (void)closeStream {
    
    self.input.delegate = nil;
    self.output.delegate = nil;
    [self.input removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.input close];
    [self.output removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.output close];
    self.data = [NSMutableData new];
    self.connected = false;
}

- (void)writeData {
    
    while (self.output.hasSpaceAvailable && self.data.length > 0 && !self.paused) {
        NSInteger bytesWritten = [self.output write:self.data.bytes maxLength:self.data.length];
        if (bytesWritten == -1) {
            NSLog(@"写入失败--%@--%@", self.output, self.output.streamError);
            return;
        }else if (bytesWritten > 0) {
            [self.data replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
            
            NSProgress *progress = [[NSProgress alloc] init];
            progress.totalUnitCount = self.writeDataLength;
            progress.completedUnitCount = self.writeDataLength - self.data.length;
            //            NSLog(@"发送进度:%lli-%lli", progress.completedUnitCount, progress.totalUnitCount);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.progressBlock) {
                    self.progressBlock(progress);
                }
                if (progress.totalUnitCount == progress.completedUnitCount) {
                    self.progressBlock = nil;
                }
            });
        }else {
            NSLog(@"写入失败: %li", (long)bytesWritten);
        }
    }
}

- (void)readData {
    
    NSMutableData *readData = [[NSMutableData alloc] init];
#define EAD_INPUT_BUFFER_SIZE 128
    uint8_t buf[EAD_INPUT_BUFFER_SIZE];
    while ([self.input hasBytesAvailable])
    {
        NSInteger bytesRead = [self.input read:buf maxLength:EAD_INPUT_BUFFER_SIZE];
        if (bytesRead == -1) {
            NSLog(@"读取数据失败");
            return;
        }
        [readData appendBytes:(void *)buf length:bytesRead];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self streamDidReadInputData:readData];
    });
}

#pragma mark --NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    
    //    NSLog(@"%@",[NSThread currentThread]);
    switch (eventCode) {
        case NSStreamEventNone:
            break;
        case NSStreamEventOpenCompleted:
            //NSLog(@"%@ open complete",aStream);
            [self whenStreamOpenComplete:aStream];
            break;
        case NSStreamEventHasBytesAvailable:
            [self readData];
            break;
        case NSStreamEventHasSpaceAvailable:
            [self writeData];
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"流错误: %@", aStream.streamError);
            [self whenStreamErrorOccured:aStream];
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"流断开: %@", aStream.streamError);
            [self whenStreamEndEncounterd:aStream];
            break;
        default:
            break;
    }
}

- (void)whenStreamEndEncounterd:(NSStream *)aStream {
    
    [self closeStream];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self streamDidDisconnect];
    });
}

- (void)whenStreamOpenComplete:(NSStream *)aStream {
    
    if (aStream == self.input) {
        self.connectFlag |= RYStreamPairConnectFlagInputStreaRYonnected;
    }else if (aStream == self.output) {
        self.connectFlag |= RYStreamPairConnectFlagOutputStreaRYonnected;
    }
    if (self.connectFlag == RYStreamPairConnectFlagAllStreaRYonnected) {
        
        self.connected = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.successBlock) {
                self.successBlock();
            }
            self.successBlock = nil;
            self.failBlock = nil;
        });
        [self.timer invalidate];
    }
}

- (void)whenStreamErrorOccured:(NSStream *)aStream {
    
    if (self.connected) {
        [self closeStream];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self streamDidDisconnect];
        });
    }else {
        [self.timer invalidate];
        [self closeStream];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.failBlock) {
                self.failBlock(aStream.streamError);
            }
            /*
             以下两个方法调用顺序互换后竟然会导致崩溃
             **/
            self.failBlock = nil;
            self.successBlock = nil;
        });
    }
}

@end