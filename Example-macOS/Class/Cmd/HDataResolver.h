//
//  HDataResolver.h
//  MocolourSDK
//
//  Created by ldc on 2019/12/17.
//  Copyright © 2019 swiftHY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RYCommunication-macOS/RYCommunication-macOS.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MTCmdType) {
    MTCmdTypePrinterInfo,
    MTCmdTypeCarbonRibbonBrand,
    MTCmdTypeCarbonRibbonRemainCount,
    MTCmdTypeSn,
    MTCmdTypeFirmwareVersion,
    MTCmdTypeClearBuffer,
    MTCmdTypeAutoStatus,
    MTCmdTypeImageSliceAck,
    MTCmdTypeFirmwareSliceAck,
    MTCmdTypeCommonSet,
    MTCmdTypeCommonGet,
    MTCmdTypeCarbonRibbonProperty,
};

typedef NS_ENUM(Byte, MTCarbonRibbonResponseProperty) {
    MTCarbonRibbonResponsePropertyUid = 0,
    MTCarbonRibbonResponsePropertyPrinterModelAvailable = 1,
    MTCarbonRibbonResponsePropertyWidth = 2,
    MTCarbonRibbonResponsePropertyType = 3,
    MTCarbonRibbonResponsePropertyVenderId = 4,
    MTCarbonRibbonResponsePropertyHeatFactor = 5,
    MTCarbonRibbonResponsePropertyLengthPrinted = 0x10,
};

@interface MTResolverModel : RYCommonResolverModel

@property (nonatomic, assign) MTCmdType type;

@end

@interface MTDataResolver : RYCommonResolver

@end

NS_ASSUME_NONNULL_END
