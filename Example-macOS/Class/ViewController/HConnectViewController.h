//
//  HConnectViewController.h
//  PoooliExample
//
//  Created by ldc on 2019/12/2.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RYCommunication-macOS/RYCommunication-macOS.h>

typedef NS_ENUM(NSUInteger, HInterfaceType) {
    HInterfaceTypeUSB,
    HInterfaceTypeBluetooth,
};

NS_ASSUME_NONNULL_BEGIN

@interface HConnectViewController : NSViewController

@property (nonatomic, assign) HInterfaceType interfaceType;

@property (nonatomic, copy) void (^ _Nullable connectBlock)(id<RYAccessory>);

@end

NS_ASSUME_NONNULL_END
