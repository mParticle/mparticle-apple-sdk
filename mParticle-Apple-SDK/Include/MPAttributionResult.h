//
//  MPAttributionResult.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Attribution information returned by a kit.
 */
@interface MPAttributionResult : NSObject

/**
 Free-form attribution info dictionary.
 */
@property (nonatomic) NSDictionary *linkInfo;
@property (nonatomic, readonly) NSNumber *kitCode;
@property (nonatomic, readonly) NSString *kitName;

@end

NS_ASSUME_NONNULL_END
