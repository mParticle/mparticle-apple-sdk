//
//  MPRokt.h
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 4/22/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@import RoktContracts;

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
 * Set the session id to use for the next execute call.
 * This is useful for cases where you have a session id from a non-native integration,
 * e.g. WebView, and you want the session to be consistent across integrations.
 *
 * @note Empty strings are ignored and will not update the session.
 *
 * @param sessionId The session id to be set. Must be a non-empty string.
 */
- (void)setSessionId:(NSString * _Nonnull)sessionId;

/**
 * Get the session id to use within a non-native integration e.g. WebView.
 *
 * @return The session id or nil if no session is present.
 */
- (NSString * _Nullable)getSessionId;

@end
