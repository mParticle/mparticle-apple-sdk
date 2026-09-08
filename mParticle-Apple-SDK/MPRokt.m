//
//  MPRokt.m
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 4/22/25.
//

#import "MPRokt.h"
@import RoktContracts;
#import "mParticle.h"
@import mParticle_Apple_SDK_Swift;
#import "MPILogger.h"
#import "MPExtensionProtocol.h"
#import "Kits/MPKitContainer+MParticlePrivate.h"

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;

@end

static id<MPRoktKitDispatchTarget> MPRoktKitAsDispatchTarget(id kitInstance) {
    if (![kitInstance conformsToProtocol:@protocol(MPRoktKitDispatchTarget)]) {
        return nil;
    }
    return kitInstance;
}

static NSInteger const kMPRoktKitCode = 181;

@implementation MPRokt

/// Displays a Rokt ad placement with the specified identifier and user attributes.
/// This is a convenience method that calls the full selectPlacements method with nil for optional parameters.
/// - Parameters:
///   - identifier: The Rokt placement identifier configured in the Rokt dashboard (e.g., "checkout_confirmation")
///   - attributes: Optional dictionary of user attributes to pass to Rokt (e.g., email, firstName, etc.)
- (void)selectPlacements:(NSString *)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
    MPILogDebug(@"MPRokt selectPlacements (short) called - identifier: %@, attributes count: %lu",
                identifier, (unsigned long)attributes.count);
    [self selectPlacements:identifier attributes:attributes embeddedViews:nil config:nil onEvent:nil];
}

/// Displays a Rokt ad placement with full configuration options.
/// This method handles user identity synchronization, attribute mapping, and forwards the request to the Rokt Kit.
/// Device identifiers (IDFA/IDFV) are automatically added if available.
/// - Parameters:
///   - identifier: The Rokt placement identifier configured in the Rokt dashboard
///   - attributes: Optional dictionary of user attributes (email, firstName, etc.). Attributes will be mapped according to dashboard configuration.
///   - embeddedViews: Optional dictionary mapping placement identifiers to embedded view containers for inline placements
///   - config: Optional Rokt configuration object (e.g., for dark mode or custom styling)
///   - onEvent: Optional callback block to handle Rokt events
- (void)selectPlacements:(NSString *)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes
           embeddedViews:(NSDictionary<NSString *, RoktEmbeddedView *> * _Nullable)embeddedViews
                  config:(RoktConfig * _Nullable)config
                 onEvent:(void (^ _Nullable)(RoktEvent * _Nonnull))onEvent {
    [self logRoktApiDiagnostic:@"SELECT_PLACEMENTS"];
    MPILogDebug(@"MPRokt selectPlacements (full) called - identifier: %@, attributes count: %lu, embeddedViews count: %lu, config: %@, onEvent: %@",
                identifier,
                (unsigned long)attributes.count,
                (unsigned long)embeddedViews.count,
                config ? @"present" : @"nil",
                onEvent ? @"present" : @"nil");
    
    // Capture the timestamp immediately when selectPlacements is called (in milliseconds)
    long long jointSdkSelectPlacementsTimestamp = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    RoktPlacementOptions *placementOptions = [[RoktPlacementOptions alloc] initWithTimestamp:jointSdkSelectPlacementsTimestamp];
    
    MPILogVerbose(@"MParticle.Rokt selectPlacements called with attributes: %@", attributes);
    dispatch_async([MParticle messageQueue], ^{
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:identifier];
        [queueParameters addParameter:attributes ?: @{}];
        [queueParameters addParameter:embeddedViews];
        [queueParameters addParameter:config];
        [queueParameters addParameter:onEvent];
        [queueParameters addParameter:placementOptions];

        SEL roktSelector = @selector(selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:);
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                  event:nil
                                                             parameters:queueParameters
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

/// Notifies Rokt that a purchase from a placement offer has been finalized.
/// Call this method to inform Rokt about the completion status of an offer purchase initiated from a placement.
/// - Parameters:
///   - identifier: The identifier of the placement where the offer was displayed
///   - catalogItemId: The identifier of the catalog item that was purchased
///   - success: Whether the purchase was successful (YES) or failed (NO)
- (void)purchaseFinalized:(NSString * _Nonnull)identifier catalogItemId:(NSString * _Nonnull)catalogItemId success:(BOOL)success {
    [self logRoktApiDiagnostic:@"PURCHASE_FINALIZED"];
    MPILogDebug(@"MPRokt purchaseFinalized - identifier: %@, catalogItemId: %@, success: %@",
                identifier, catalogItemId, success ? @"YES" : @"NO");
    dispatch_async(dispatch_get_main_queue(), ^{
        // Forwarding call to kits
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:identifier];
        [queueParameters addParameter:catalogItemId];
        [queueParameters addParameter:@(success)];
        
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(purchaseFinalized:catalogItemId:success:)
                                                                  event:nil
                                                             parameters:queueParameters
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

/// Registers a callback to receive events from a specific Rokt placement.
/// Use this to listen for events like placement shown, offer selected, placement closed, etc.
/// - Parameters:
///   - identifier: The Rokt placement identifier to listen for events from
///   - onEvent: Callback block that receives RoktEvent objects when placement events occur
- (void)events:(NSString * _Nonnull)identifier onEvent:(void (^ _Nullable)(RoktEvent * _Nonnull))onEvent {
    [self logRoktApiDiagnostic:@"ROKT_EVENTS"];
    MPILogDebug(@"MPRokt events called - identifier: %@, onEvent: %@",
                identifier, onEvent ? @"present" : @"nil");
    dispatch_async(dispatch_get_main_queue(), ^{
        // Forwarding call to kits
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:identifier];
        [queueParameters addParameter:onEvent];

        SEL roktSelector = @selector(events:onEvent:);
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                  event:nil
                                                                 parameters:queueParameters
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

/// Registers a callback to receive global events from all Rokt sources.
/// Additional events that are not associated with a view (such as InitComplete) will also be delivered.
/// - Parameters:
///   - onEvent: Callback block that receives RoktEvent objects when events occur
- (void)globalEvents:(void (^ _Nonnull)(RoktEvent * _Nonnull))onEvent {
    [self logRoktApiDiagnostic:@"ROKT_GLOBAL_EVENTS"];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Forwarding call to kits
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:onEvent];

        SEL roktSelector = @selector(globalEvents:);
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                  event:nil
                                                             parameters:queueParameters
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

/// Closes any currently displayed Rokt placement.
/// Call this method to programmatically dismiss an active Rokt overlay or embedded placement.
- (void)close {
    [self logRoktApiDiagnostic:@"ROKT_CLOSE"];
    MPILogDebug(@"MPRokt close called");
    dispatch_async(dispatch_get_main_queue(), ^{
        // Forwarding call to kits
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(close)
                                                                  event:nil
                                                             parameters:nil
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

/// Set the session id to use for the next execute call.
/// This is useful for cases where you have a session id from a non-native integration,
/// e.g. WebView, and you want the session to be consistent across integrations.
/// - Note: Empty strings are ignored and will not update the session.
/// - Parameters:
///   - sessionId: The session id to be set. Must be a non-empty string.
- (void)setSessionId:(NSString * _Nonnull)sessionId {
    [self logRoktApiDiagnostic:@"ROKT_SET_SESSION_ID"];
    MPILogDebug(@"MPRokt setSessionId called - sessionId: %@", sessionId ? @"present" : @"nil");
    dispatch_async(dispatch_get_main_queue(), ^{
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:sessionId];

        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(setSessionId:)
                                                                  event:nil
                                                             parameters:queueParameters
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

/// End the current Rokt session so the next selectPlacements call starts a new one.
///
/// Intended for self-service terminals where a queue of unrelated customers shares one
/// device. Fire-and-forget, mirroring `close`: the kit performs the reset synchronously on
/// its side, so there is nothing to return here.
- (void)clearSession {
    [self logRoktApiDiagnostic:@"ROKT_CLEAR_SESSION"];
    MPILogDebug(@"MPRokt clearSession called");
    // Dispatched on the message queue, not the main queue, so it stays ordered with
    // selectPlacements. Both forwards ultimately hop to main inside the kit container, so
    // dispatching from two different queues would leave the order down to which one drains
    // first — and a partner calling clearSession then selectPlacements would sometimes send the
    // departing customer's token.
    dispatch_async([MParticle messageQueue], ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(clearSession)
                                                                  event:nil
                                                             parameters:nil
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

/// Get the session id to use within a non-native integration e.g. WebView.
/// - Returns: The session id or nil if no session is present.
- (NSString * _Nullable)getSessionId {
    [self logRoktApiDiagnostic:@"ROKT_GET_SESSION_ID"];
    MPILogDebug(@"MPRokt getSessionId called");
    __block NSString *result = nil;

    NSArray<id<MPExtensionKitProtocol>> *activeKits = [[MParticle sharedInstance].kitContainer_PRIVATE activeKitsRegistry];
    
    if (!activeKits || activeKits.count == 0) {
        MPILogDebug(@"MPRokt getSessionId - no active kits found");
        return nil;
    }
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKits) {
        if ([kitRegister.code integerValue] == kMPRoktKitCode) {
            id<MPRoktKitDispatchTarget> target = MPRoktKitAsDispatchTarget(kitRegister.wrapperInstance);
            if (target && [target respondsToSelector:@selector(getSessionId)]) {
                result = [target getSessionId];
                MPILogDebug(@"MPRokt getSessionId returning: %@", result ? @"session present" : @"nil");
                break;
            } else {
                MPILogDebug(@"MPRokt getSessionId - kit found but doesn't adopt MPRoktKitDispatchTarget or getSessionId");
            }
        }
    }
    
    if (!result) {
        MPILogDebug(@"MPRokt getSessionId - Rokt Kit not found in active kits");
    }

    return result;
}

- (void)logRoktApiDiagnostic:(NSString *)code {
    if (code.length == 0) {
        return;
    }
    NSArray<id<MPExtensionKitProtocol>> *activeKits = [[MParticle sharedInstance].kitContainer_PRIVATE activeKitsRegistry];
    for (id<MPExtensionKitProtocol> kitRegister in activeKits) {
        if ([kitRegister.code integerValue] == kMPRoktKitCode) {
            id<MPRoktKitDispatchTarget> target = MPRoktKitAsDispatchTarget(kitRegister.wrapperInstance);
            if ([target respondsToSelector:@selector(logMParticleApiDiagnostic:)]) {
                [target logMParticleApiDiagnostic:code];
            }
            break;
        }
    }
}

/**
 * Registers a payment extension for Shoppable Ads.
 * The payment extension handles payment processing (e.g., Apple Pay via Stripe).
 *
 * For the mParticle path, the Rokt kit reads `stripePublishableKey` from kit configuration
 * (dashboard) and passes it to Rokt as `stripeKey`. The partner still supplies platform-specific
 * setup in the payment extension (e.g., Apple Pay merchant ID).
 *
 * @param paymentExtension An object conforming to RoktPaymentExtension (PaymentExtension in Swift; from RoktContracts)
 */
- (void)registerPaymentExtension:(id<RoktPaymentExtension> _Nonnull)paymentExtension {
    [self logRoktApiDiagnostic:@"REGISTER_PAYMENT_EXTENSION"];
    dispatch_async([MParticle messageQueue], ^{
        MPILogDebug(@"MPRokt forwarding to kit - registerPaymentExtension: %@",
                    paymentExtension);
        // Forwarding call to kits
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:paymentExtension];
        
        SEL roktSelector = @selector(registerPaymentExtension:);
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                  event:nil
                                                             parameters:queueParameters
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

/**
 * Displays a Shoppable Ads overlay placement.
 * Requires a payment extension to be registered first via registerPaymentExtension:.
 *
 * @param identifier The view name / placement identifier
 * @param attributes User attributes for targeting
 */
- (void)selectShoppableAds:(NSString * _Nonnull)identifier
                attributes:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes {
    MPILogDebug(@"MPRokt selectShoppableAds (short) called - identifier: %@, attributes count: %lu",
                identifier, (unsigned long)attributes.count);
    [self selectShoppableAds:identifier attributes:attributes config:nil onEvent:nil];
}

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
                   onEvent:(void (^ _Nullable)(RoktEvent * _Nonnull))onEvent {
    [self logRoktApiDiagnostic:@"SELECT_SHOPPABLE_ADS"];
    MPILogDebug(@"MPRokt selectShoppableAds (full) called - identifier: %@, attributes count: %lu, config: %@, onEvent: %@",
                identifier,
                (unsigned long)attributes.count,
                config ? @"present" : @"nil",
                onEvent ? @"present" : @"nil");
    
    MPILogVerbose(@"MParticle.Rokt selectShoppableAds called with attributes: %@", attributes);
    dispatch_async([MParticle messageQueue], ^{
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:identifier];
        [queueParameters addParameter:attributes];
        [queueParameters addParameter:config];
        [queueParameters addParameter:onEvent];

        SEL roktSelector = @selector(selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:);
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                  event:nil
                                                             parameters:queueParameters
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

/// Forwards a redirect URL (e.g. Afterpay, PayPal) to the registered Rokt payment extension(s) via the Rokt Kit.
/// Uses a synchronous kit lookup (not \c forwardSDKCall) because the caller relies on the BOOL return value.
/// - Parameter url: The URL received by the app's URL handler.
/// - Returns: YES if a registered payment extension claimed the URL; NO otherwise (including when the Rokt Kit is not registered).
- (BOOL)handleURLCallback:(NSURL * _Nonnull)url {
    [self logRoktApiDiagnostic:@"ROKT_HANDLE_URL_CALLBACK"];
    MPILogDebug(@"MPRokt handleURLCallback called - url: %@", url);
    if (!url) {
        return NO;
    }

    NSArray<id<MPExtensionKitProtocol>> *activeKits = [[MParticle sharedInstance].kitContainer_PRIVATE activeKitsRegistry];
    if (!activeKits || activeKits.count == 0) {
        MPILogDebug(@"MPRokt handleURLCallback - no active kits found");
        return NO;
    }

    for (id<MPExtensionKitProtocol> kitRegister in activeKits) {
        if ([kitRegister.code integerValue] == kMPRoktKitCode) {
            id<MPRoktKitDispatchTarget> target = MPRoktKitAsDispatchTarget(kitRegister.wrapperInstance);
            if (target && [target respondsToSelector:@selector(handleURLCallback:)]) {
                BOOL handled = [target handleURLCallback:url];
                MPILogDebug(@"MPRokt handleURLCallback returning: %@", handled ? @"YES" : @"NO");
                return handled;
            }
            MPILogDebug(@"MPRokt handleURLCallback - kit found but doesn't adopt MPRoktKitDispatchTarget or handleURLCallback:");
            return NO;
        }
    }

    MPILogDebug(@"MPRokt handleURLCallback - Rokt Kit not found in active kits");
    return NO;
}

@end
