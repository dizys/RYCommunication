//
//  FT800Authorization.m
//  FT800SDK
//
//  Created by ldc on 2020/11/12.
//

#import "FT800Authorization.h"
#import "FT800DataResolver.h"
#import "RYBleAccessory.h"
#import "RYSocketAccessory.h"

@interface FT800Authorization ()

@property (nonatomic, strong) FT800DataResolver *resolver;

@end

@implementation FT800Authorization

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timeout = 5;
        self.resolver = [[FT800DataResolver alloc] init];
        __weak typeof(self) weakSelf = self;
        self.resolver.resolvedBlock = ^(id  _Nonnull result) {
            FT800ResolverModel *model = (FT800ResolverModel *)result;
            switch (model.type) {
                case FT800PackageTypeHandshake:
                    if (weakSelf.validatedBlock) {
                        weakSelf.validatedBlock(RYAuthorizationResultAuthorized);
                    }
                    break;
                default:
                    break;
            }
        };
    }
    return self;
}

- (void)startChallenge {
    
    if (self.accessory) {
        if ([self.accessory isKindOfClass:[RYSocketAccessory class]]) {
            RYSocketAccessory *temp = (RYSocketAccessory *)self.accessory;
            if (temp.port != 9100) {
                [FT800LikeCommandGenerator default].port = 0;
                NSData *cmd = [[FT800LikeCommandGenerator default] handshake:true];
                [self.accessory writeDataImmutably:cmd];
                return;
            } 
        }
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
