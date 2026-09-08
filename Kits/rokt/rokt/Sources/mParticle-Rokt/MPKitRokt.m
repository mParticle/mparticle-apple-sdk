#import "MPKitRokt.h"

#if SWIFT_PACKAGE
@import mParticle_Rokt_Internal;
#else
#import <mParticle_Rokt/mParticle_Rokt-Swift.h>
#endif

@interface MParticle (MPRoktKitPrivate)
+ (dispatch_queue_t)messageQueue;
@end

@interface FilteredMParticleUser (MPRoktKitPrivate)
- (NSDictionary<NSString *, id> *)mp_filteredUserAttributesByMergingAttributes:(NSDictionary<NSString *, id> *)attributes;
@end

@interface MPKitRokt () {
    MPKitAPI *_kitApi;
}
@property (nonatomic, strong) MPRoktKitImplementation *implementation;
@end

static NSDictionary<NSString *, RoktEmbeddedView *> *MPRoktValidEmbeddedViews(NSDictionary *embeddedViews) {
    NSMutableDictionary<NSString *, RoktEmbeddedView *> *validViews = [NSMutableDictionary dictionary];
    Class embeddedViewClass = NSClassFromString(@"RoktEmbeddedView");
    [embeddedViews enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if ([key isKindOfClass:[NSString class]] &&
            embeddedViewClass != Nil &&
            [value isKindOfClass:embeddedViewClass]) {
            validViews[key] = value;
        }
    }];
    return validViews;
}

@implementation MPKitRokt

+ (NSNumber *)kitCode {
    return @181;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Rokt" className:@"MPKitRokt"];
    [MParticle registerExtension:kitRegister];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _implementation = [[MPRoktKitImplementation alloc] init];
        __weak typeof(self) weakSelf = self;
        _implementation.warningHandler = ^(NSString *message) {
            [weakSelf.kitApi logWarning:@"%@", message];
        };
        _implementation.afterPendingAttributeWrites = ^(dispatch_block_t completion) {
            dispatch_async([MParticle messageQueue], ^{
                dispatch_async(dispatch_get_main_queue(), completion);
            });
        };
        _implementation.filterUserAttributes = ^NSDictionary<NSString *, id> *(
            NSDictionary<NSString *, id> *attributes,
            FilteredMParticleUser *filteredUser
        ) {
            if (![filteredUser respondsToSelector:@selector(mp_filteredUserAttributesByMergingAttributes:)]) {
                return nil;
            }
            return [filteredUser mp_filteredUserAttributesByMergingAttributes:attributes];
        };
    }
    return self;
}

- (NSDictionary *)configuration {
    return self.implementation.configuration;
}

- (void)setConfiguration:(NSDictionary *)configuration {
    self.implementation.configuration = configuration ?: @{};
}

- (BOOL)started {
    return self.implementation.started;
}

- (void)setKitApi:(MPKitAPI *)kitApi {
    _kitApi = kitApi;
    [self.implementation setContextWithOwner:self kitAPI:kitApi];
}

- (MPKitAPI *)kitApi {
    return _kitApi;
}

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    [self.implementation setContextWithOwner:self kitAPI:self.kitApi];
    return [self.implementation didFinishLaunchingWithConfiguration:configuration];
}

- (void)start {
    [self.implementation start];
}

- (void)stop {
    [self.implementation stop];
}

- (MPKitExecStatus *)selectPlacementsWithIdentifier:(NSString *)identifier
                                         attributes:(NSDictionary<NSString *, NSString *> *)attributes
                                      embeddedViews:(NSDictionary<NSString *, RoktEmbeddedView *> *)embeddedViews
                                             config:(RoktConfig *)config
                                            onEvent:(void (^)(RoktEvent *))onEvent
                                       filteredUser:(FilteredMParticleUser *)filteredUser
                                            options:(RoktPlacementOptions *)options {
    return [self.implementation selectPlacementsWithIdentifier:identifier
                                                    attributes:attributes
                                                 embeddedViews:[self confirmEmbeddedViews:embeddedViews]
                                                        config:config
                                                       onEvent:onEvent
                                                  filteredUser:filteredUser
                                                       options:options];
}

- (NSDictionary<NSString *, RoktEmbeddedView *> *)confirmEmbeddedViews:(NSDictionary *)embeddedViews {
    return MPRoktValidEmbeddedViews(embeddedViews);
}

- (MPKitExecStatus *)selectShoppableAdsWithIdentifier:(NSString *)identifier
                                            attributes:(NSDictionary<NSString *, NSString *> *)attributes
                                                config:(RoktConfig *)config
                                               onEvent:(void (^)(RoktEvent *))onEvent
                                          filteredUser:(FilteredMParticleUser *)filteredUser {
    return [self.implementation selectShoppableAdsWithIdentifier:identifier
                                                       attributes:attributes
                                                           config:config
                                                          onEvent:onEvent
                                                     filteredUser:filteredUser];
}

- (MPKitExecStatus *)registerPaymentExtension:(id<RoktPaymentExtension>)paymentExtension {
    return [self.implementation registerPaymentExtension:paymentExtension];
}

- (MPKitExecStatus *)purchaseFinalized:(NSString *)identifier
                         catalogItemId:(NSString *)catalogItemId
                               success:(NSNumber *)success {
    return [self.implementation purchaseFinalized:identifier catalogItemId:catalogItemId success:success];
}

- (MPKitExecStatus *)events:(NSString *)identifier onEvent:(void (^)(RoktEvent *))onEvent {
    return [self.implementation events:identifier onEvent:onEvent];
}

- (MPKitExecStatus *)globalEvents:(void (^)(RoktEvent *))onEvent {
    return [self.implementation globalEvents:onEvent];
}

- (MPKitExecStatus *)close {
    return [self.implementation close];
}

- (MPKitExecStatus *)setSessionId:(NSString *)sessionId {
    return [self.implementation setSessionId:sessionId];
}

- (NSString *)getSessionId {
    return [self.implementation getSessionId];
}

- (MPKitExecStatus *)clearSession {
    return [self.implementation clearSession];
}

- (BOOL)handleURLCallback:(NSURL *)url {
    return [self.implementation handleURLCallback:url];
}

- (void)logMParticleApiDiagnostic:(NSString *)code {
    [self.implementation logMParticleApiDiagnostic:code];
}

- (MPKitExecStatus *)setWrapperSdk:(MPWrapperSdk)wrapperSdk version:(NSString *)wrapperSdkVersion {
    return [self.implementation setWrapperSdk:wrapperSdk version:wrapperSdkVersion];
}

+ (NSDictionary<NSString *, NSString *> *)prepareAttributes:(NSDictionary<NSString *, NSString *> *)attributes
                                                filteredUser:(FilteredMParticleUser *)filteredUser
                                              performMapping:(BOOL)performMapping {
    return [MPRoktKitImplementation prepareAttributes:attributes
                                         filteredUser:filteredUser
                                       performMapping:performMapping];
}

+ (NSNumber *)getRoktHashedEmailUserIdentityType {
    return [MPRoktKitImplementation getRoktHashedEmailUserIdentityType];
}

+ (void)logSelectPlacementEvent:(NSDictionary<NSString *, NSString *> *)attributes {
    [MPRoktKitImplementation logSelectPlacementEvent:attributes];
}

@end
