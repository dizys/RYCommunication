//
//  HSampleModel.m
//  PoooliExample
//
//  Created by ldc on 2019/12/3.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#import "HSampleModel.h"

@implementation HSampleModel

- (instancetype)initWith:(SEL)selector title:(NSString *)title detail:(NSString *)detailTitle
{
    self = [super init];
    if (self) {
        self.selector = selector;
        self.title = title;
        self.detailTitle = detailTitle;
    }
    return self;
}

@end
