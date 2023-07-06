//
//  MParticleSession.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An SDK session.
 
 Sessions are typically started and ended automatically by the SDK based on App lifecycle events.
 
 Automatic session management can be disabled if desired and is always disabled in App Extensions.
 
 @see currentSession
 */
@interface MParticleSession : NSObject

/**
 A hash of the session UUID.
 */
@property (nonatomic, readonly) NSNumber *sessionID;

/**
 The session UUID.
 */
@property (nonatomic, readonly) NSString *UUID;

/**
 The session start time.
 */
@property (nonatomic, readonly) NSNumber *startTime;

@end

NS_ASSUME_NONNULL_END
