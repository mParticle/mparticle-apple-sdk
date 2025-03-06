//
//  MParticleUser.h
//
//

#import <Foundation/Foundation.h>
#import "MPAudience.h"
#import "MPEnums.h"
#import "MPConsentState.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A single user as represented by the mParticle SDK
 */
@interface MParticleUser : NSObject

/**
 The mParticle id associated with this user (MPID)
 */
@property(readonly, strong, nonnull) NSNumber *userId;

/**
 The date when this user was first seen by the SDK
 */
@property(readonly, strong, nonnull) NSDate *firstSeen;

/**
 The date when this user was most recently seen by the SDK
 */
@property(readonly, strong, nonnull) NSDate *lastSeen;

/**
 Returns whether this user is currently logged in
 */
@property(readonly) BOOL isLoggedIn;

/**
 Gets current identities (readonly)
 @returns A dictionary containing the collection of all identities including device identities
 @see MPIdentity
 */
@property (readonly, strong, nonnull) NSDictionary<NSNumber *, NSString *> *identities;

/**
 Gets/sets all user attributes.
 @returns A dictionary containing the collection of user attributes.
 */
@property (readwrite, strong, nonnull) NSDictionary<NSString *, id> *userAttributes;

/**
 Increments the value of a user attribute by the provided amount. If the key does not
 exist among the current user attributes, this method will add the key to the user attributes
 and set the value to the provided amount. If the key already exists and the existing value is not
 a number, the operation will abort.
 
 Note: this method has been changed to be async, return value will always be @0.
 
 @param key The attribute key
 @param value The increment amount
 @returns The static value @0
 */
- (nullable NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value;

/**
 Sets a single user attribute. The property will be combined with any existing attributes.
 There is a 100 count limit to user attributes.
 @param key The user attribute key
 @param value The user attribute value
 */
- (void)setUserAttribute:(NSString *)key value:(id)value;

/**
 Sets a list of user attributes associated with a key.
 @param key The user attribute list key
 @param values An array of user attributes
 */
- (void)setUserAttributeList:(NSString *)key values:(NSArray<NSString *> *)values;

/**
 Sets a single user tag or attribute.  The property will be combined with any existing attributes.
 There is a 100 count limit to user attributes.
 @param tag The user tag/attribute
 */
- (void)setUserTag:(NSString *)tag;

/**
 Removes a single user attribute.
 @param key The user attribute key
 */
- (void)removeUserAttribute:(NSString *)key;

#pragma mark - User Audiences
/**
 Retrieves user audiences from mParticle's servers and returns the result as an array of MPAudience objects
 @param completionHandler A block to be called when the results are available.
 */
- (void)getUserAudiencesWithCompletionHandler:(void (^)(NSArray<MPAudience *> *currentAudiences, NSError * _Nullable error))completionHandler;

#pragma mark - Consent State
/**
 Sets the user's current consent state.
 @param state A consent state object
 */
- (void)setConsentState:(MPConsentState *)state;
/**
 Gets the users consent state.
 @returns The user's current consent state object
 */
- (nullable MPConsentState *)consentState;

@end

NS_ASSUME_NONNULL_END
