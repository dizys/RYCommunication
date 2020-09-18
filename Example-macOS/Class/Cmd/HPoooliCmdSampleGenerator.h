//
//  HPoooliCmdSampleGenerator.h
//  PoooliExample
//
//  Created by ldc on 2019/12/3.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <RYCommunication-macOS/RYCommunication-macOS.h>
#import "HProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HPoooliCmdSampleGenerator : NSObject <HCmdSampleGenerator>

@property (nonatomic, weak) id<RYAccessory> transimitter;

@property (nonatomic, weak) NSViewController *target;

@property (nonatomic, strong) NSMutableData *cacheData;

- (instancetype)initWith:(id<RYAccessory>)transmitter target:(NSViewController *)target;

- (void)setDensity;

- (void)setStandbyTime;

- (void)printImage;

@end

NS_ASSUME_NONNULL_END
