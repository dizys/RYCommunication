//
//  RYTask.h
//  SDK
//
//  Created by ldc on 2022/2/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RYTask : NSObject

@property (nonatomic, strong) NSData *data;

@property (nonatomic, copy, nullable) void (^ progressBlock)(NSProgress *);

@end

NS_ASSUME_NONNULL_END
