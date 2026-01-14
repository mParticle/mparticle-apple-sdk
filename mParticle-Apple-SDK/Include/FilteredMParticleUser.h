//
//  FilteredMParticleUser.h
//

#import <Foundation/Foundation.h>

@class MParticleUser;
@class MPKitConfiguration;

@interface FilteredMParticleUser : NSObject

@property(readonly, strong, nonnull) NSNumber *userId;

/**
 Returns whether this user is currently logged in
 */
@property(readonly) BOOL isLoggedIn;

/**
 Gets current user identities (readonly)
 @returns A dictionary containing the collection of user identities
 @see MPUserIdentity
 */
@property (readonly, strong, nonnull) NSDictionary<NSNumber *, NSString *> *userIdentities;

/**
 Gets current user's IDFA (readonly)
 @returns A string that represents a unique, resettable device identifier that allows developers to track user activity for personalized ads. This will always be nil if ATTStatus is not set to authorized.
 @see MPIdentityIOSAdvertiserId
 */
@property (readonly, strong, nullable) NSString *idfa;

/**
 Gets current user's IDFV (readonly)
 @returns A string that represents a unique, non-resettable alphanumeric code Apple assigns to a specific device, identical for all apps from the same developer on that device.
 @see MPIdentityIOSVendorId
 */
@property (readonly, strong, nullable) NSString *idfv;

/**
 Gets all user attributes.
 @returns A dictionary containing the collection of user attributes.
 */
@property (readonly, strong, nonnull) NSDictionary<NSString *, id> *userAttributes;

- (instancetype _Nonnull )initWithMParticleUser:(MParticleUser *_Nonnull)user kitConfiguration:(MPKitConfiguration *_Nonnull)kitConfiguration;

@end
