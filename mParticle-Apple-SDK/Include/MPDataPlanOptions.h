//
//  MPDataPlanOptions.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Planning settings for kit blocking
 */
@interface MPDataPlanOptions : NSObject
/**
 Data Plan.
 
 Data plan value (JSON schema) for blocking data to kits.
 */
@property (nonatomic, strong, readwrite, nullable) NSDictionary *dataPlan;

/**
 Whether to block unplanned events from being sent to kits, default false
 */
@property (nonatomic, readwrite) BOOL blockEvents;

/**
 Whether to block unplanned event attributes from being sent to kits, default false
 */
@property (nonatomic, readwrite) BOOL blockEventAttributes;

/**
 Whether to block unplanned user attributes from being sent to kits, default false
 */
@property (nonatomic, readwrite) BOOL blockUserAttributes;

/**
 Whether to block unplanned user identities from being sent to kits, default false
 */
@property (nonatomic, readwrite) BOOL blockUserIdentities;

@end

NS_ASSUME_NONNULL_END
