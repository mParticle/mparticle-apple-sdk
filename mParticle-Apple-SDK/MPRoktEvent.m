#import "MPRoktEvent.h"

#pragma mark - MPRoktEvent

@implementation MPRoktEvent
@end

#pragma mark - MPRoktInitComplete

@interface MPRoktInitComplete ()
@property (nonatomic, readwrite) BOOL success;
@end

@implementation MPRoktInitComplete

- (instancetype)initWithSuccess:(BOOL)success {
    self = [super init];
    if (self) {
        _success = success;
    }
    return self;
}

@end

#pragma mark - MPRoktShowLoadingIndicator

@implementation MPRoktShowLoadingIndicator
@end

#pragma mark - MPRoktHideLoadingIndicator

@implementation MPRoktHideLoadingIndicator
@end

#pragma mark - MPRoktPlacementInteractive

@interface MPRoktPlacementInteractive ()
@property (nonatomic, readwrite, nullable) NSString *placementId;
@end

@implementation MPRoktPlacementInteractive

- (instancetype)initWithPlacementId:(nullable NSString *)placementId {
    self = [super init];
    if (self) {
        _placementId = placementId;
    }
    return self;
}

@end

#pragma mark - MPRoktPlacementReady

@interface MPRoktPlacementReady ()
@property (nonatomic, readwrite, nullable) NSString *placementId;
@end

@implementation MPRoktPlacementReady

- (instancetype)initWithPlacementId:(nullable NSString *)placementId {
    self = [super init];
    if (self) {
        _placementId = placementId;
    }
    return self;
}

@end

#pragma mark - MPRoktOfferEngagement

@interface MPRoktOfferEngagement ()
@property (nonatomic, readwrite, nullable) NSString *placementId;
@end

@implementation MPRoktOfferEngagement

- (instancetype)initWithPlacementId:(nullable NSString *)placementId {
    self = [super init];
    if (self) {
        _placementId = placementId;
    }
    return self;
}

@end

#pragma mark - MPRoktOpenUrl

@interface MPRoktOpenUrl ()
@property (nonatomic, readwrite, nullable) NSString *placementId;
@property (nonatomic, readwrite) NSString *url;
@end

@implementation MPRoktOpenUrl

- (instancetype)initWithPlacementId:(nullable NSString *)placementId url:(NSString *)url {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _url = url;
    }
    return self;
}

@end

#pragma mark - MPRoktPositiveEngagement

@interface MPRoktPositiveEngagement ()
@property (nonatomic, readwrite, nullable) NSString *placementId;
@end

@implementation MPRoktPositiveEngagement

- (instancetype)initWithPlacementId:(nullable NSString *)placementId {
    self = [super init];
    if (self) {
        _placementId = placementId;
    }
    return self;
}

@end

#pragma mark - MPRoktPlacementClosed

@interface MPRoktPlacementClosed ()
@property (nonatomic, readwrite, nullable) NSString *placementId;
@end

@implementation MPRoktPlacementClosed

- (instancetype)initWithPlacementId:(nullable NSString *)placementId {
    self = [super init];
    if (self) {
        _placementId = placementId;
    }
    return self;
}

@end

#pragma mark - MPRoktPlacementCompleted

@interface MPRoktPlacementCompleted ()
@property (nonatomic, readwrite, nullable) NSString *placementId;
@end

@implementation MPRoktPlacementCompleted

- (instancetype)initWithPlacementId:(nullable NSString *)placementId {
    self = [super init];
    if (self) {
        _placementId = placementId;
    }
    return self;
}

@end

#pragma mark - MPRoktPlacementFailure

@interface MPRoktPlacementFailure ()
@property (nonatomic, readwrite, nullable) NSString *placementId;
@end

@implementation MPRoktPlacementFailure

- (instancetype)initWithPlacementId:(nullable NSString *)placementId {
    self = [super init];
    if (self) {
        _placementId = placementId;
    }
    return self;
}

@end

#pragma mark - MPRoktFirstPositiveEngagement

@interface MPRoktFirstPositiveEngagement ()
@property (nonatomic, readwrite, nullable) NSString *placementId;
@end

@implementation MPRoktFirstPositiveEngagement

- (instancetype)initWithPlacementId:(nullable NSString *)placementId {
    self = [super init];
    if (self) {
        _placementId = placementId;
    }
    return self;
}

@end

#pragma mark - MPRoktCartItemInstantPurchase

@interface MPRoktCartItemInstantPurchase ()
@property (nonatomic, readwrite) NSString *placementId;
@property (nonatomic, readwrite, nullable) NSString *name;
@property (nonatomic, readwrite) NSString *cartItemId;
@property (nonatomic, readwrite) NSString *catalogItemId;
@property (nonatomic, readwrite) NSString *currency;
@property (nonatomic, readwrite) NSString *itemDescription;
@property (nonatomic, readwrite, nullable) NSString *linkedProductId;
@property (nonatomic, readwrite) NSString *providerData;
@property (nonatomic, readwrite, nullable) NSDecimalNumber *quantity;
@property (nonatomic, readwrite, nullable) NSDecimalNumber *totalPrice;
@property (nonatomic, readwrite, nullable) NSDecimalNumber *unitPrice;
@end

@implementation MPRoktCartItemInstantPurchase

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
                          unitPrice:(nullable NSDecimalNumber *)unitPrice {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _name = name;
        _cartItemId = cartItemId;
        _catalogItemId = catalogItemId;
        _currency = currency;
        _itemDescription = description;
        _linkedProductId = linkedProductId;
        _providerData = providerData;
        _quantity = quantity;
        _totalPrice = totalPrice;
        _unitPrice = unitPrice;
    }
    return self;
}

- (NSString *)description {
    return _itemDescription;
}

@end
