//
//  RYNotHandlingResolver.h
//  RYCommunication
//
//  Created by ldc on 2020/9/7.
//  Copyright © 2020 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "base.h"
#import "RYDataRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface RYNotHandlingResolver : NSObject <RYDataResolver>

@end

@interface RYCommonResolver : NSObject <RYDataResolver>

@property (nonatomic, strong) RYDataRouter *router;

- (void)registerHandle;

@end

NS_ASSUME_NONNULL_END
