//
//  MPAudience.h
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 2/20/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPAudience : NSObject

/**
 The mParticle id associated with this user (MPID)
 */
@property(readonly, strong, nonnull) NSNumber *audienceId;

/**
 The date when this user was first seen by the SDK
 */
@property(readonly, strong, nonnull) NSString *name;

- (instancetype)initWithAudienceId:(NSNumber *)audienceId andName:(NSString *)name;

- (instancetype)initWithDictionary:(NSDictionary *)audienceDictionary;

@end

extern NSString * _Nonnull const kMPAudienceListKey;
extern NSString * _Nonnull const kMPAudienceIdKey;
extern NSString * _Nonnull const kMPAudienceNameKey;
extern NSString * _Nonnull const kMPAudienceMembershipListKey;
extern NSString * _Nonnull const kMPAudienceMembershipListChangeActionKey;
extern NSString * _Nonnull const kMPAudienceMembershipListChangeActionAddValue;
extern NSString * _Nonnull const kMPAudienceMembershipListChangeActionDropValue;

NS_ASSUME_NONNULL_END
