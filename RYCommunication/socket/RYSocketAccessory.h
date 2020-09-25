//
//  RYSocketAccessory.h
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RYStreamPair.h"

NS_ASSUME_NONNULL_BEGIN

@interface RYSocketAccessory : RYStreamPair

@property (nonatomic, copy) NSString *ip;

@property (nonatomic, assign) NSInteger port;

- (instancetype)initWith:(NSString *)ip port:(NSInteger)port;

@end

NS_ASSUME_NONNULL_END
