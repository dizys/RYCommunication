//
//  MTCmdSampleGenerator.h
//  PoooliExample
//
//  Created by ldc on 2019/12/3.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <RYCommunication/RYCommunication.h>
#import "HProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTCmdSampleGenerator : NSObject <HCmdSampleGenerator>

@property (nonatomic, weak) id<RYAccessory> transimitter;

@property (nonatomic, weak) NSViewController *target;

- (instancetype)initWith:(id<RYAccessory>)transmitter target:(NSViewController *)target;

@end

NS_ASSUME_NONNULL_END
