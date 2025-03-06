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
 The unique audience ID of this audience
 */
@property(readonly, strong, nonnull) NSNumber *audienceId;

- (instancetype)initWithAudienceId:(NSNumber *)audienceId;

@end

extern NSString * _Nonnull const kMPAudienceMembershipKey;
extern NSString * _Nonnull const kMPAudienceIdKey;

NS_ASSUME_NONNULL_END
