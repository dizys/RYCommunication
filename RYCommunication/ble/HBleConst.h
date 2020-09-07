//
//  HBleConst.h
//  HYEditor
//
//  Created by ldc on 2019/12/18.
//  Copyright © 2019 swiftHY. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN NSErrorDomain HBleConnectErrorDomain;

typedef NS_ENUM(NSInteger, HBleConnectErrorCode) {
    HBleConnectErrorCodeSystemError,
    HBleConnectErrorCodeTimeout,
    HBleConnectErrorCodeServiceNotFound,
    HBleConnectErrorCodeCharacteristicNotFound,
};

NS_ASSUME_NONNULL_END
