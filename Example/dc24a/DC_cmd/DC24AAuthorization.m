//
//  DC24AAuthorization.m
//  DC24ASDK
//
//  Created by ldc on 2020/11/12.
//

#import "DC24AAuthorization.h"
#import "DC24ADataResolver.h"
#import "RYBleAccessory.h"
#import "RYSocketAccessory.h"

@interface DC24AAuthorization ()

@property (nonatomic, strong) DC24ADataResolver *resolver;

@end

@implementation DC24AAuthorization

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timeout = 5;
        self.resolver = [[DC24ADataResolver alloc] init];
        __weak typeof(self) weakSelf = self;
        self.resolver.resolvedBlock = ^(id  _Nonnull result) {
            NSLog(@"result：%@",result);
//            DC24AResolverModel *model = (DC24AResolverModel *)result;
//            switch (model.type) {
//                case DC24APackageTypeHandshake:
//                    if (weakSelf.validatedBlock) {
//                        weakSelf.validatedBlock(RYAuthorizationResultAuthorized);
//                    }
//                    break;
//                default:
//                    break;
//            }
        };
    }
    return self;
}

- (void)startChallenge {

    if (self.accessory) {
//        if ([self.accessory isKindOfClass:[RYSocketAccessory class]]) {
//            RYSocketAccessory *temp = (RYSocketAccessory *)self.accessory;
//            if (temp.port != 9100) {
//                [DC24ALikeCommandGenerator default].port = 0;
//                NSData *cmd = [[DC24ALikeCommandGenerator default] handshake:true];
//                [self.accessory writeDataImmutably:cmd];
//                return;
//            }
//        }
        if (self.validatedBlock) {
            self.validatedBlock(RYAuthorizationResultAuthorized);
        }
    }else {
        if (self.validatedBlock) {
            self.validatedBlock(RYAuthorizationResultDenied);
        }
    }
}

- (void)readInput:(NSData *)data {
    
    [self.resolver readInput:data];
}

@end
