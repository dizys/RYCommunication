//
//  RYCommunication.h
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for RYCommunication.
FOUNDATION_EXPORT double RYCommunicationVersionNumber;

//! Project version string for RYCommunication.
FOUNDATION_EXPORT const unsigned char RYCommunicationVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <RYCommunication/PublicHeader.h>

#import <RYCommunication/base.h>

#import <RYCommunication/RYResolver.h>

#import <RYCommunication/RYAuthorization.h>

#if TARGET_OS_IOS

#import <RYCommunication/RYExternalAccessory.h>

#import <RYCommunication/RYStreamPair.h>

#import <RYCommunication/RYSocketAccessory.h>

#import <RYCommunication/RYBleAccessory.h>

#import <RYCommunication/RYBleConst.h>

#import <RYCommunication/RYBleService.h>

#import <RYCommunication/RYCentralManager.h>

#endif

#if TARGET_OS_OSX

#import <RYCommunication/RYUSBAccessory.h>

#import <RYCommunication/RYBluetoothAccessory.h>

#endif
