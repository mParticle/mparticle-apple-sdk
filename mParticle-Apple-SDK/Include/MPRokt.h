//
//  MPRokt.h
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 4/22/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Callback container for Rokt callbacks.
 * Used to handle various lifecycle and UI events from Rokt.
 */
@interface MPRoktEventCallback : NSObject

/** Called when the Rokt placement has finished loading */
@property (nonatomic, copy, nullable) void (^onLoad)(void);
/** Called when the Rokt placement is being unloaded/removed */
@property (nonatomic, copy, nullable) void (^onUnLoad)(void);
/** Called when Rokt reccomends the UI shows a loading indicator */
@property (nonatomic, copy, nullable) void (^onShouldShowLoadingIndicator)(void);
/** Called when Rokt reccomends the UI hides its loading indicator */
@property (nonatomic, copy, nullable) void (^onShouldHideLoadingIndicator)(void);
/** Called when the embedded view's size changes */
@property (nonatomic, copy, nullable) void (^onEmbeddedSizeChange)(NSString * _Nonnull, CGFloat);

@end

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
 * Selects a Rokt placement with full configuration options including embedded views and callbacks.
 *
 * @param identifier Unique identifier for the placement
 * @param attributes Optional dictionary of attributes to customize the placement
 * @param embeddedViews Optional dictionary mapping placement names to their embedded views
 * @param roktEventCallback Optional callback object to handle widget events
 */
- (void)selectPlacements:(NSString *_Nonnull)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes
           embeddedViews:(NSDictionary<NSString *, MPRoktEmbeddedView *> * _Nullable)embeddedViews
                  config:(MPRoktConfig * _Nullable)config
               callbacks:(MPRoktEventCallback * _Nullable)roktEventCallback;

/**
 * Used to report a successful conversion without displaying a placement
 *
 * @param placementId Unique identifier for the placement
 * @param catalogItemId Unique identifier for the catalog item ID
 * @param success Indicates whether or not the purchase was successful
 */
- (void)purchaseFinalized:(NSString *_Nonnull)placementId
            catalogItemId:(NSString *_Nonnull)catalogItemId
                  success:(BOOL)success;

/**
 * Used to subscribe to Rokt events
 *
 * @param identifier The identifier of the placement to subscribe to
 * @param onEvent The block to execute when the event is triggered
 */
- (void)events:(NSString *_Nonnull)identifier onEvent:(void (^ _Nullable)(MPRoktEvent * _Nonnull))onEvent;

/**
 * Used to close Rokt overlay placements
 */
- (void)close;

@end
