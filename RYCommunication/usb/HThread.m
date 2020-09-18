//
//  HThread.m
//  USBExample
//
//  Created by ldc on 2019/11/22.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "HThread.h"

static NSThread *thread;
static NSRunLoop *runloop;

@implementation HThread

+ (void)entryRunloop:(id) __unused object {
    
    @autoreleasepool {
        [NSThread currentThread].name = @"com.h.background.thread";
        runloop = [NSRunLoop currentRunLoop];
        [runloop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runloop run];
    }
}

+ (NSThread *)thread {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(entryRunloop:) object:nil];
        [thread start];
    });
    return thread;
}

@end
