#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Base class for all Rokt events.
 */
@interface MPRoktEvent : NSObject
@end

/**
 Event indicating Rokt initialization completed.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktInitComplete)
@interface MPRoktInitComplete : MPRoktEvent

/**
 Whether initialization was successful.
 */
@property (nonatomic, readonly) BOOL success;

/**
 Initializes a new init complete event.
 @param success Whether initialization was successful
 @return A new MPRoktInitComplete instance
 */
- (instancetype)initWithSuccess:(BOOL)success;

@end

/**
 Event indicating the loading indicator should be shown.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktShowLoadingIndicator)
@interface MPRoktShowLoadingIndicator : MPRoktEvent
@end

/**
 Event indicating the loading indicator should be hidden.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktHideLoadingIndicator)
@interface MPRoktHideLoadingIndicator : MPRoktEvent
@end

/**
 Event indicating a placement became interactive.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktPlacementInteractive)
@interface MPRoktPlacementInteractive : MPRoktEvent

/**
 The placement identifier, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *placementId;

/**
 Initializes a new placement interactive event.
 @param placementId The placement identifier
 @return A new MPRoktPlacementInteractive instance
 */
- (instancetype)initWithPlacementId:(nullable NSString *)placementId;

@end

/**
 Event indicating a placement is ready.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktPlacementReady)
@interface MPRoktPlacementReady : MPRoktEvent

/**
 The placement identifier, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *placementId;

/**
 Initializes a new placement ready event.
 @param placementId The placement identifier
 @return A new MPRoktPlacementReady instance
 */
- (instancetype)initWithPlacementId:(nullable NSString *)placementId;

@end

/**
 Event indicating an offer engagement occurred.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktOfferEngagement)
@interface MPRoktOfferEngagement : MPRoktEvent

/**
 The placement identifier, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *placementId;

/**
 Initializes a new offer engagement event.
 @param placementId The placement identifier
 @return A new MPRoktOfferEngagement instance
 */
- (instancetype)initWithPlacementId:(nullable NSString *)placementId;

@end

/**
 Event indicating a URL should be opened.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktOpenUrl)
@interface MPRoktOpenUrl : MPRoktEvent

/**
 The placement identifier, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *placementId;

/**
 The URL to open.
 */
@property (nonatomic, readonly) NSString *url;

/**
 Initializes a new open URL event.
 @param placementId The placement identifier
 @param url The URL to open
 @return A new MPRoktOpenUrl instance
 */
- (instancetype)initWithPlacementId:(nullable NSString *)placementId url:(NSString *)url;

@end

/**
 Event indicating a positive engagement occurred.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktPositiveEngagement)
@interface MPRoktPositiveEngagement : MPRoktEvent

/**
 The placement identifier, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *placementId;

/**
 Initializes a new positive engagement event.
 @param placementId The placement identifier
 @return A new MPRoktPositiveEngagement instance
 */
- (instancetype)initWithPlacementId:(nullable NSString *)placementId;

@end

/**
 Event indicating a placement was closed.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktPlacementClosed)
@interface MPRoktPlacementClosed : MPRoktEvent

/**
 The placement identifier, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *placementId;

/**
 Initializes a new placement closed event.
 @param placementId The placement identifier
 @return A new MPRoktPlacementClosed instance
 */
- (instancetype)initWithPlacementId:(nullable NSString *)placementId;

@end

/**
 Event indicating a placement was completed.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktPlacementCompleted)
@interface MPRoktPlacementCompleted : MPRoktEvent

/**
 The placement identifier, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *placementId;

/**
 Initializes a new placement completed event.
 @param placementId The placement identifier
 @return A new MPRoktPlacementCompleted instance
 */
- (instancetype)initWithPlacementId:(nullable NSString *)placementId;

@end

/**
 Event indicating a placement failure occurred.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktPlacementFailure)
@interface MPRoktPlacementFailure : MPRoktEvent

/**
 The placement identifier, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *placementId;

/**
 Initializes a new placement failure event.
 @param placementId The placement identifier
 @return A new MPRoktPlacementFailure instance
 */
- (instancetype)initWithPlacementId:(nullable NSString *)placementId;

@end

/**
 Event indicating the first positive engagement occurred.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktFirstPositiveEngagement)
@interface MPRoktFirstPositiveEngagement : MPRoktEvent

/**
 The placement identifier, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *placementId;

/**
 Initializes a new first positive engagement event.
 @param placementId The placement identifier
 @return A new MPRoktFirstPositiveEngagement instance
 */
- (instancetype)initWithPlacementId:(nullable NSString *)placementId;

@end

/**
 Event indicating a cart item instant purchase occurred.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktCartItemInstantPurchase)
@interface MPRoktCartItemInstantPurchase : MPRoktEvent

/**
 The placement identifier.
 */
@property (nonatomic, readonly) NSString *placementId;

/**
 The name of the item, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *name;

/**
 The cart item identifier.
 */
@property (nonatomic, readonly) NSString *cartItemId;

/**
 The catalog item identifier.
 */
@property (nonatomic, readonly) NSString *catalogItemId;

/**
 The currency code.
 */
@property (nonatomic, readonly) NSString *currency;

/**
 The linked product identifier, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSString *linkedProductId;

/**
 Provider-specific data.
 */
@property (nonatomic, readonly) NSString *providerData;

/**
 The quantity, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSDecimalNumber *quantity;

/**
 The total price, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSDecimalNumber *totalPrice;

/**
 The unit price, or nil if not available.
 */
@property (nonatomic, readonly, nullable) NSDecimalNumber *unitPrice;

/**
 Initializes a new cart item instant purchase event.
 @param placementId The placement identifier
 @param name The item name
 @param cartItemId The cart item identifier
 @param catalogItemId The catalog item identifier
 @param currency The currency code
 @param description The item description
 @param linkedProductId The linked product identifier
 @param providerData Provider-specific data
 @param quantity The quantity
 @param totalPrice The total price
 @param unitPrice The unit price
 @return A new MPRoktCartItemInstantPurchase instance
 */
- (instancetype)initWithPlacementId:(NSString *)placementId
                               name:(nullable NSString *)name
                         cartItemId:(NSString *)cartItemId
                      catalogItemId:(NSString *)catalogItemId
                           currency:(NSString *)currency
                        description:(NSString *)description
                    linkedProductId:(nullable NSString *)linkedProductId
                       providerData:(NSString *)providerData
                           quantity:(nullable NSDecimalNumber *)quantity
                         totalPrice:(nullable NSDecimalNumber *)totalPrice
                          unitPrice:(nullable NSDecimalNumber *)unitPrice;

@end

/**
 Event indicating the height of an embedded placement changed.
 This event is only emitted for embedded placements.
 */
NS_SWIFT_NAME(MPRoktEvent.MPRoktEmbeddedSizeChanged)
@interface MPRoktEmbeddedSizeChanged : MPRoktEvent

/**
 The placement identifier.
 */
@property (nonatomic, readonly) NSString *placementId;

/**
 The new height of the placement.
 */
@property (nonatomic, readonly) CGFloat updatedHeight;

/**
 Initializes a new embedded size changed event.
 @param placementId The placement identifier
 @param updatedHeight The new height of the placement
 @return A new MPRoktEmbeddedSizeChanged instance
 */
- (instancetype)initWithPlacementId:(NSString *)placementId updatedHeight:(CGFloat)updatedHeight;

@end

NS_ASSUME_NONNULL_END
