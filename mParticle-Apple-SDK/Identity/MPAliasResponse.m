//
//  MPAliasResponse.m
//

#import "MPAliasResponse.h"
@import mParticle_Apple_SDK_Swift;

@implementation MPAliasResponse

- (BOOL)isSuccessful {
    return [MPAliasResponsePlanPRIVATE isSuccessCode:_responseCode];
}

@end
