//
//  MPRoktSession.h
//  mParticle-Apple-SDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A Rokt session suitable for handoff between native and non-native integrations (e.g. WebView).
 *
 * Includes the session id plus an optional short-lived session token used to authorize offers and
 * events. Mirrors Web launcher options: `sessionId` is required for handoff; `sessionToken` is
 * optional (Bearer continuity when present).
 */
@interface MPRoktSession : NSObject

/**
 * The Rokt session identifier. Must be non-empty when passed to `-setSession:`.
 */
@property (nonatomic, copy, readonly) NSString *sessionId;

/**
 * Optional JWT session token used as a Bearer credential for offers and events.
 * When nil or empty, `-setSession:` applies the session id only (same as Web `sessionId`
 * without `sessionToken`).
 */
@property (nonatomic, copy, readonly, nullable) NSString *sessionToken;

/**
 * Optional Unix epoch milliseconds when `sessionToken` expires (matches server `expires_at` when known).
 * Ignored when `sessionToken` is absent.
 */
@property (nonatomic, strong, readonly, nullable) NSNumber *expiresAt;

/**
 * Creates a session handoff value.
 *
 * @param sessionId The Rokt session identifier.
 * @param sessionToken Optional JWT session token (`nil` for id-only handoff).
 * @param expiresAt Optional token expiry as Unix epoch milliseconds (`nil` if unknown).
 */
- (instancetype)initWithSessionId:(NSString *)sessionId
                     sessionToken:(nullable NSString *)sessionToken
                        expiresAt:(nullable NSNumber *)expiresAt NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
