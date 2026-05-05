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

/**
 SHA-256 hashed email address for privacy-safe identity resolution.
 Maps to the `other` identity type (@c MPIdentityOther).
 */
@property (nonatomic, strong, nullable) NSString *emailSha256;

/**
 SHA-256 hashed mobile number for privacy-safe identity resolution.
 Maps to the `other2` identity type (@c MPIdentityOther2).
 */
@property (nonatomic, strong, nullable) NSString *mobileSha256;

@property (nonatomic, strong, nullable, readonly) NSDictionary<NSNumber*, NSObject*> *identities;

@end

NS_ASSUME_NONNULL_END
