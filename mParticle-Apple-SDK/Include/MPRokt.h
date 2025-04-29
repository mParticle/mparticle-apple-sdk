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
 * @param placements Optional dictionary mapping placement names to their embedded views
 * @param roktEventCallback Optional callback object to handle widget events
 */
- (void)selectPlacements:(NSString *_Nonnull)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes
              placements:(NSDictionary<NSString *, MPRoktEmbeddedView *> * _Nullable)placements
               callbacks:(MPRoktEventCallback * _Nullable)roktEventCallback;

@end
