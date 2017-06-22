//
//  MPIdentityApiResult.h
//

#import <Foundation/Foundation.h>
#import "MParticleUser.h"

@interface MPIdentityApiResult : NSObject

@property(nonatomic, strong, readonly, nonnull) MParticleUser *user;

@end
