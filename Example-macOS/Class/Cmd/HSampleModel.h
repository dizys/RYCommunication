//
//  HSampleModel.h
//  PoooliExample
//
//  Created by ldc on 2019/12/3.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HSampleModel : NSObject

- (instancetype)initWith:(SEL)selector title:(NSString *)title detail:(NSString * _Nullable)detailTitle;

@property (nonatomic, assign) SEL selector;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *detailTitle;

@end

NS_ASSUME_NONNULL_END
