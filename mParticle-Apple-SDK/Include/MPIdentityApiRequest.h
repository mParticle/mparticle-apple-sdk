//
//  MPIdentityApiRequest.h
//

#import <Foundation/Foundation.h>
#import "MParticleUser.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Main identity request object, used to resolve a set of user identities to a resulting MPID.
 
 (Device identities are also taken into account and will be added automatically by the SDK.)
 */
@interface MPIdentityApiRequest : NSObject

+ (instancetype)requestWithEmptyUser;
+ (instancetype)requestWithUser:(MParticleUser *) user;

- (void)setIdentity:(nullable NSString *)identityString identityType:(MPIdentity)identityType;

@property (nonatomic, strong, nullable) NSString *email;
@property (nonatomic, strong, nullable) NSString *customerId;
@property (nonatomic, strong, nullable, readonly) NSDictionary<NSNumber*, NSObject*> *identities;

@end

NS_ASSUME_NONNULL_END
