//
//  MPRoktSession.h
//  mParticle-Apple-SDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A Rokt session suitable for handoff between native and non-native integrations (e.g. WebView).
 *
 * Includes the session id, short-lived session token, and token expiry used to authorize offers
 * and events. Use the legacy session-id APIs for id-only handoff.
 */
@interface MPRoktSession : NSObject

/**
 * The Rokt session identifier. Must be non-empty when passed to `-setSession:`.
 */
@property (nonatomic, copy, readonly) NSString *sessionId;

/**
 * JWT session token used as a Bearer credential for offers and events.
 */
@property (nonatomic, copy, readonly) NSString *sessionToken;

/**
 * Unix epoch milliseconds when `sessionToken` expires (matches server `expires_at`).
 */
@property (nonatomic, strong, readonly) NSNumber *expiresAt;

/**
 * Creates a session handoff value.
 *
 * @param sessionId The Rokt session identifier.
 * @param sessionToken The JWT session token.
 * @param expiresAt Token expiry as Unix epoch milliseconds.
 */
- (instancetype)initWithSessionId:(NSString *)sessionId
                     sessionToken:(NSString *)sessionToken
                        expiresAt:(NSNumber *)expiresAt NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
