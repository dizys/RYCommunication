//
//  HCentralMessageRepeater.m
//  BleKit
//
//  Created by ldc on 2019/3/25.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "HCentralMessageRepeater.h"
#import <objc/runtime.h>

@interface HCentralMessageRepeater ()

@property (nonatomic, strong) NSMapTable<CBPeripheral *, HBleAccessory *> *targets;

@end

@implementation HCentralMessageRepeater

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.targets = [NSMapTable weakToWeakObjectsMapTable];
    }
    return self;
}

- (void)registTarget:(HBleAccessory *)target {
    
    [self.targets setObject:target forKey:target.peripheral];
}

- (void)unregistTarget:(HBleAccessory *)target {
    
    [self.targets setObject:nil forKey:target.peripheral];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSEnumerator<CBPeripheral *> *enumerator = self.targets.keyEnumerator;
    CBPeripheral *peripheral;
    while ((peripheral = enumerator.nextObject)) {
        id target = [self.targets objectForKey:peripheral];
        if ([target respondsToSelector:_cmd]) {
            [(id<CBCentralManagerDelegate>)target centralManagerDidUpdateState:central];
        }
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    
    SEL temp = invocation.selector;
    invocation.selector = temp;
    BOOL existPeripheralParam = true;
    if (sel_isEqual(temp, @selector(centralManager:willRestoreState:)) || 
        sel_isEqual(temp, @selector(centralManager:didDiscoverPeripheral:advertisementData:RSSI:))) {
        existPeripheralParam = false;
    }
    if (!existPeripheralParam) {
        NSEnumerator<CBPeripheral *> *enumerator = self.targets.keyEnumerator;
        CBPeripheral *peripheral;
        while ((peripheral = enumerator.nextObject)) {
            id target = [self.targets objectForKey:peripheral];
            if ([target respondsToSelector:invocation.selector]) {
                [invocation invokeWithTarget:target];
            }
        }
    }else {
        CBPeripheral *__unsafe_unretained periperal;
        [invocation getArgument:&periperal atIndex:3];
        if (!periperal) {
            return;
        }
        NSObject<CBCentralManagerDelegate> *target = [self.targets objectForKey:periperal];
        if (target && [target respondsToSelector:invocation.selector]) {
            [invocation invokeWithTarget:target];
        }
    }
    
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    
    if (self.targets.count > 0) {
        return true;
    }else {
        return false;
    }
}

@end
