//
//  MPIdentityApiResult.h
//

#import <Foundation/Foundation.h>
#import "MParticleUser.h"

@interface MPIdentityApiResult : NSObject

@property(nonatomic, strong, readwrite, nonnull) MParticleUser *user;

@end
