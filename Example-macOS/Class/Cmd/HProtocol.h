//
//  HProtocol.h
//  PoooliExample
//
//  Created by ldc on 2019/12/3.
//  Copyright © 2019 Xiamen Hanin. All rights reserved.
//

#ifndef HProtocol_h
#define HProtocol_h
#import <Foundation/Foundation.h>
#import "HSampleModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HCmdSampleGenerator <NSObject>

@property (nonatomic, strong, readonly) NSMutableArray<HSampleModel *> *sampleList;

@end

NS_ASSUME_NONNULL_END
#endif /* HProtocol_h */
