//
//  MPRokt.h
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 4/22/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Custom view class for embedding Rokt widgets in the UI.
 * Inherits from UIView and provides container functionality for Rokt placements.
 */
@interface MPRoktEmbeddedView : UIView

@end

// An enum of the possible options for an MPRoktConfig colorMode
typedef NS_ENUM(NSInteger, MPColorMode) {
    MPColorModeLight = 0,
    MPColorModeDark = 1,
    MPColorModeSystem = 2
};

/**
 * A class for customizing the UI displayed by Rokt
 */
@interface MPRoktConfig : NSObject
/** The max duration for the cache */
@property (nonatomic, copy, nullable) NSNumber *cacheDuration;
/** The attributes you would like tied to the cache */
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *cacheAttributes;
/** The color mode you would like Rokt to display in */
@property (nonatomic) MPColorMode colorMode;

@end

/**
 * A class for handling Rokt events
 */
@class MPRoktEvent;

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
           embeddedViews:(NSDictionary<NSString *, MPRoktEmbeddedView *> * _Nullable)embeddedViews
                  config:(MPRoktConfig * _Nullable)config
                 onEvent:(void (^ _Nullable)(MPRoktEvent * _Nonnull))onEvent;

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
- (void)events:(NSString *_Nonnull)identifier onEvent:(void (^ _Nullable)(MPRoktEvent * _Nonnull))onEvent;

/**
 * Used to subscribe to global Rokt events from all sources.
 * Additional events that are not associated with a view (such as InitComplete) will also be delivered.
 *
 * @param onEvent The block to execute when the event is triggered
 */
- (void)globalEvents:(void (^ _Nonnull)(MPRoktEvent * _Nonnull))onEvent;

/**
 * Used to close Rokt overlay placements
 */
- (void)close;

@end
