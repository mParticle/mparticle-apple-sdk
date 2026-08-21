//
//  MPRokt.h
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 4/22/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class RoktEmbeddedView;
@class RoktConfig;
@class RoktEvent;
@class MPRoktSession;
@protocol RoktPaymentExtension;

/**
 * Main interface for interacting with Rokt functionality.
 * Handles placement selection and widget management.
 */
@interface MPRokt : NSObject

/**
 * Selects placements with the given identifier and attributes.
 * Simplified version without embedded views or callbacks.
 *
 * @param identifier Unique identifier for the placement
 * @param attributes Optional dictionary of attributes to customize the placement
 */
- (void)selectPlacements:(NSString *_Nonnull)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes;

/**
 * Selects a Rokt placement with full configuration options including embedded views and event callback.
 *
 * @param identifier Unique identifier for the placement
 * @param attributes Optional dictionary of attributes to customize the placement
 * @param embeddedViews Optional dictionary mapping placement names to their embedded views
 * @param config Optional configuration object for customizing the placement display
 * @param onEvent Optional callback block to handle Rokt events
 */
- (void)selectPlacements:(NSString *_Nonnull)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes
           embeddedViews:(NSDictionary<NSString *, RoktEmbeddedView *> * _Nullable)embeddedViews
                  config:(RoktConfig * _Nullable)config
                 onEvent:(void (^ _Nullable)(RoktEvent * _Nonnull))onEvent;

/**
 * Used to report a successful conversion without displaying a placement
 *
 * @param identifier Unique identifier for the placement
 * @param catalogItemId Unique identifier for the catalog item ID
 * @param success Indicates whether or not the purchase was successful
 */
- (void)purchaseFinalized:(NSString *_Nonnull)identifier
            catalogItemId:(NSString *_Nonnull)catalogItemId
                  success:(BOOL)success;

/**
 * Used to subscribe to Rokt events for a specific placement
 *
 * @param identifier The identifier of the placement to subscribe to
 * @param onEvent The block to execute when the event is triggered
 */
- (void)events:(NSString *_Nonnull)identifier onEvent:(void (^ _Nullable)(RoktEvent * _Nonnull))onEvent;

/**
 * Used to subscribe to global Rokt events from all sources.
 * Additional events that are not associated with a view (such as InitComplete) will also be delivered.
 *
 * @param onEvent The block to execute when the event is triggered
 */
- (void)globalEvents:(void (^ _Nonnull)(RoktEvent * _Nonnull))onEvent;

/**
 * Used to close Rokt overlay placements
 */
- (void)close;

/**
 * Set the session to use for the next execute call.
 *
 * Use this when you have a session from a non-native integration (e.g. WebView)
 * and want the session to stay consistent across integrations. Call before the next execute.
 *
 * Matches Web launcher options: pass a non-empty `sessionId` with optional `sessionToken`.
 * When the token is present, offers/events can send `Authorization: Bearer`. When only the id
 * is present, the id is applied without Bearer seeding. Empty `sessionId` (or token without id)
 * is ignored.
 *
 * @param session The session id and optional JWT session token (optional expiry).
 */
- (void)setSession:(MPRoktSession * _Nonnull)session;

/**
 * Get the current session (id + token) for use within a non-native integration e.g. WebView.
 *
 * @return The session, or nil if no session is present or the token has expired.
 */
- (MPRoktSession * _Nullable)getSession;

/**
 * Set the session id to use for the next execute call.
 * This is useful for cases where you have a session id from a non-native integration,
 * e.g. WebView, and you want the session to be consistent across integrations.
 *
 * @note Empty strings are ignored and will not update the session.
 * Prefer `-setSession:` so the session token is also applied for offers and events.
 *
 * @param sessionId The session id to be set. Must be a non-empty string.
 */
- (void)setSessionId:(NSString * _Nonnull)sessionId __attribute__((deprecated("Use setSession: to set session id and session token.")));

/**
 * Get the session id to use within a non-native integration e.g. WebView.
 *
 * Prefer `-getSession` to also read the session token.
 *
 * @return The session id or nil if no session is present.
 */
- (NSString * _Nullable)getSessionId __attribute__((deprecated("Use getSession to read session id and session token.")));

/**
 * End the current Rokt session so the next selectPlacements call starts a new one.
 *
 * Intended for self-service terminals — kiosks, counter tablets, shared point-of-sale
 * hardware — where a queue of unrelated customers uses a single device. Without this the
 * Rokt SDK reuses its stored session, so successive customers are recorded as one person
 * and frequency capping, attribution and reporting all treat them as one.
 *
 * Call this at a transaction boundary, not between screens within one customer's journey:
 * two placements shown to the same customer are meant to share a session.
 *
 * Buffered events are flushed before the session is dropped, so events belonging to the
 * departing customer stay attributed to them. Calling this with no active session is a no-op.
 *
 * @note This also clears the id returned by getSessionId, so a WebView session hand-off must
 * be re-established afterwards.
 */
- (void)clearSession;

/**
 * Registers a payment extension for Shoppable Ads.
 * The payment extension handles payment processing (e.g., Apple Pay via Stripe).
 *
 * For the mParticle path, the Rokt kit reads \c stripePublishableKey from kit configuration
 * (mParticle dashboard) and passes it to Rokt as \c stripeKey. The partner still supplies
 * platform-specific setup in the payment extension (e.g., Apple Pay merchant ID).
 *
 * @param paymentExtension An object conforming to RoktPaymentExtension (PaymentExtension in Swift; from RoktContracts)
 */
- (void)registerPaymentExtension:(id<RoktPaymentExtension> _Nonnull)paymentExtension;

/**
 * Displays a Shoppable Ads overlay placement.
 * Requires a payment extension to be registered first via registerPaymentExtension:.
 *
 * @param identifier The view name / placement identifier
 * @param attributes User attributes for targeting
 */
- (void)selectShoppableAds:(NSString * _Nonnull)identifier
                attributes:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes;

/**
 * Displays a Shoppable Ads overlay placement with configuration and callbacks.
 *
 * @param identifier The view name / placement identifier
 * @param attributes User attributes for targeting
 * @param config Optional display configuration (color mode, caching)
 * @param onEvent Optional callback block to handle Rokt events
 */
- (void)selectShoppableAds:(NSString * _Nonnull)identifier
                attributes:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes
                    config:(RoktConfig * _Nullable)config
                   onEvent:(void (^ _Nullable)(RoktEvent * _Nonnull))onEvent;

/**
 * Forwards a redirect URL (e.g. Afterpay, PayPal) to the registered Rokt payment extension(s).
 * Call from your AppDelegate's application:openURL:options: or SceneDelegate's scene:openURLContexts:
 * (SwiftUI: onOpenURL) so Rokt can complete redirect-based payment flows.
 *
 * @param url The URL received by your app.
 * @return YES if a registered payment extension claimed the URL; NO otherwise.
 */
- (BOOL)handleURLCallback:(NSURL * _Nonnull)url NS_SWIFT_NAME(handleURLCallback(with:));


@end
