//
//  MPRokt.m
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 4/22/25.
//

#import "MPRokt.h"
#import "mParticle.h"
#import "MPForwardQueueParameters.h"
#import "MPILogger.h"
#import "MPIConstants.h"
#import "MPIdentityDTO.h"
#import "MPExtensionProtocol.h"

// Constants for kit configuration keys
static NSString * const kMPKitConfigurationIdKey = @"id";
static NSString * const kMPAttributeMappingSourceKey = @"map";
static NSString * const kMPAttributeMappingDestinationKey = @"value";

// Rokt attribute keys
static NSString * const kMPRoktAttributeKeySandbox = @"sandbox";

// Rokt kit identifier
static const NSInteger kMPRoktKitId = 181;

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;

@end

@implementation MPRoktEventCallback
@end

@implementation MPRoktEmbeddedView
@end

@implementation MPRoktConfig
@end

@interface MPRoktPlacementOptions ()

@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString *, NSNumber *> *mutablePerformanceMarkers;

@end

@implementation MPRoktPlacementOptions

- (nonnull instancetype)initWithTimestamp:(long long)timestamp {
    self = [super init];
    if (self) {
        _jointSdkSelectPlacements = timestamp;
        _mutablePerformanceMarkers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (nonnull NSDictionary<NSString *, NSNumber *> *)dynamicPerformanceMarkers {
    return [self.mutablePerformanceMarkers copy];
}

- (void)setDynamicPerformanceMarkerValue:(nonnull NSNumber *)value forKey:(nonnull NSString *)key {
    self.mutablePerformanceMarkers[key] = value;
}

@end

@implementation MPRokt

/// Displays a Rokt ad placement with the specified identifier and user attributes.
/// This is a convenience method that calls the full selectPlacements method with nil for optional parameters.
/// - Parameters:
///   - identifier: The Rokt placement identifier configured in the Rokt dashboard (e.g., "checkout_confirmation")
///   - attributes: Optional dictionary of user attributes to pass to Rokt (e.g., email, firstName, etc.)
- (void)selectPlacements:(NSString *)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
    MPILogDebug(@"MPRokt selectPlacements called - identifier: %@, attributes count: %lu",
                identifier, (unsigned long)attributes.count);
    [self selectPlacements:identifier attributes:attributes embeddedViews:nil config:nil callbacks:nil];
}

/// Displays a Rokt ad placement with full configuration options.
/// This method handles user identity synchronization, attribute mapping, and forwards the request to the Rokt Kit.
/// Device identifiers (IDFA/IDFV) are automatically added if available.
/// - Parameters:
///   - identifier: The Rokt placement identifier configured in the Rokt dashboard
///   - attributes: Optional dictionary of user attributes (email, firstName, etc.). Attributes will be mapped according to dashboard configuration.
///   - embeddedViews: Optional dictionary mapping placement identifiers to embedded view containers for inline placements
///   - config: Optional Rokt configuration object (e.g., for dark mode or custom styling)
///   - callbacks: Optional callback handlers for Rokt events (selection, display, completion, etc.)
- (void)selectPlacements:(NSString *)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes
           embeddedViews:(NSDictionary<NSString *, MPRoktEmbeddedView *> * _Nullable)embeddedViews
                  config:(MPRoktConfig * _Nullable)config
               callbacks:(MPRoktEventCallback * _Nullable)callbacks {
    MPILogDebug(@"MPRokt selectPlacements (full) - identifier: %@, attributes: %lu, embeddedViews: %lu, config: %@, callbacks: %@",
                identifier,
                (unsigned long)attributes.count,
                (unsigned long)embeddedViews.count,
                config ? @"present" : @"nil",
                callbacks ? @"present" : @"nil");
    
    // Capture the timestamp immediately when selectPlacements is called (in milliseconds)
    long long jointSdkSelectPlacementsTimestamp = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    MPRoktPlacementOptions *placementOptions = [[MPRoktPlacementOptions alloc] initWithTimestamp:jointSdkSelectPlacementsTimestamp];
    
    MParticleUser *currentUser = [MParticle sharedInstance].identity.currentUser;
    if (!currentUser) {
        MPILogWarning(@"MPRokt selectPlacements - currentUser is nil, identity sync may not work as expected");
    } else {
        MPILogDebug(@"MPRokt current user present - userId: %@", currentUser.userId);
    }
    
    // If email is passed in as an attribute and it's different than the existing identity, identify with it
    [self confirmUser:attributes user:currentUser completion:^(MParticleUser *_Nullable resolvedUser) {
        MPILogDebug(@"MPRokt confirmUser completed - resolvedUser: %@, userId: %@",
                    resolvedUser ? @"present" : @"nil", resolvedUser.userId);
        
        NSArray<NSDictionary<NSString *, NSString *> *> *attributeMap = [self getRoktPlacementAttributesMapping];

        MPILogVerbose(@"MParticle.Rokt selectPlacements called with attributes: %@", attributes);

        // If attributeMap is nil the kit hasn't been initialized
        if (attributeMap) {
            NSMutableDictionary *mappedAttributes = attributes.mutableCopy;
            for (NSDictionary<NSString *, NSString *> *map in attributeMap) {
                NSString *mapFrom = map[kMPAttributeMappingSourceKey];
                NSString *mapTo = map[kMPAttributeMappingDestinationKey];
                if (mappedAttributes[mapFrom]) {
                    NSString * value = mappedAttributes[mapFrom];
                    [mappedAttributes removeObjectForKey:mapFrom];
                    mappedAttributes[mapTo] = value;
                }
            }
            for (NSString *key in mappedAttributes) {
                if (![key isEqual:kMPRoktAttributeKeySandbox]) {
                    [resolvedUser setUserAttribute:key value:mappedAttributes[key]];
                }
            }
            
            dispatch_async([MParticle messageQueue], ^{
                MPILogDebug(@"MPRokt forwarding to kit - identifier: %@, mappedAttributes count: %lu",
                            identifier, (unsigned long)mappedAttributes.count);
                // Forwarding call to kits
                MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
                [queueParameters addParameter:identifier];
                [queueParameters addParameter:[self confirmSandboxAttribute:mappedAttributes]];
                [queueParameters addParameter:embeddedViews];
                [queueParameters addParameter:config];
                [queueParameters addParameter:callbacks];
                [queueParameters addParameter:placementOptions];
                
                SEL roktSelector = @selector(executeWithIdentifier:attributes:embeddedViews:config:callbacks:filteredUser:options:);
                [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                          event:nil
                                                                     parameters:queueParameters
                                                                    messageType:MPMessageTypeEvent
                                                                       userInfo:nil
                ];
            });
        } else {
            MPILogWarning(@"MPRokt selectPlacements not performed - Rokt Kit not configured. Check with your Rokt representative to ensure the kit is enabled.");
        }
    }];
}

/// Notifies Rokt that a purchase from a placement offer has been finalized.
/// Call this method to inform Rokt about the completion status of an offer purchase initiated from a placement.
/// - Parameters:
///   - placementId: The identifier of the placement where the offer was displayed
///   - catalogItemId: The identifier of the catalog item that was purchased
///   - success: Whether the purchase was successful (YES) or failed (NO)
- (void)purchaseFinalized:(NSString * _Nonnull)placementId catalogItemId:(NSString * _Nonnull)catalogItemId success:(BOOL)success {
    MPILogDebug(@"MPRokt purchaseFinalized - placementId: %@, catalogItemId: %@, success: %@",
                placementId, catalogItemId, success ? @"YES" : @"NO");
    dispatch_async(dispatch_get_main_queue(), ^{
        // Forwarding call to kits
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:placementId];
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
///   - onEvent: Callback block that receives MPRoktEvent objects when placement events occur
- (void)events:(NSString * _Nonnull)identifier onEvent:(void (^ _Nullable)(MPRoktEvent * _Nonnull))onEvent {
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

/// Closes any currently displayed Rokt placement.
/// Call this method to programmatically dismiss an active Rokt overlay or embedded placement.
- (void)close {
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

/// Get the session id to use within a non-native integration e.g. WebView.
/// - Returns: The session id or nil if no session is present.
- (NSString * _Nullable)getSessionId {
    MPILogDebug(@"MPRokt getSessionId called");
    __block NSString *result = nil;

    NSArray<id<MPExtensionKitProtocol>> *activeKits = [[MParticle sharedInstance].kitContainer_PRIVATE activeKitsRegistry];
    
    if (!activeKits || activeKits.count == 0) {
        MPILogDebug(@"MPRokt getSessionId - no active kits found");
        return nil;
    }
    
    for (id<MPExtensionKitProtocol> kitRegister in activeKits) {
        if ([kitRegister.code integerValue] == kMPRoktKitId) {
            id kitInstance = kitRegister.wrapperInstance;
            if (kitInstance && [kitInstance respondsToSelector:@selector(getSessionId)]) {
                result = [kitInstance performSelector:@selector(getSessionId)];
                MPILogDebug(@"MPRokt getSessionId returning: %@", result ? @"session present" : @"nil");
                break;
            } else {
                MPILogDebug(@"MPRokt getSessionId - kit found but doesn't respond to getSessionId");
            }
        }
    }
    
    if (!result) {
        MPILogDebug(@"MPRokt getSessionId - Rokt Kit not found in active kits");
    }

    return result;
}

#pragma mark - Private Helper Methods

/// Retrieves the Rokt Kit configuration from the kit container.
/// @return The Rokt Kit configuration dictionary, or nil if Rokt Kit is not configured.
- (NSDictionary * _Nullable)getRoktKitConfiguration {
    NSArray<NSDictionary *> *kitConfigs = [MParticle sharedInstance].kitContainer_PRIVATE.originalConfig.copy;
    MPILogDebug(@"MPRokt getRoktKitConfiguration - examining %lu kit config(s)", (unsigned long)kitConfigs.count);
    for (NSDictionary *kitConfig in kitConfigs) {
        if ([kitConfig[kMPKitConfigurationIdKey] integerValue] == kMPRoktKitId) {
            return kitConfig;
        }
    }
    NSMutableArray *kitIds = [NSMutableArray array];
    for (NSDictionary *kitConfig in kitConfigs) {
        [kitIds addObject:kitConfig[kMPKitConfigurationIdKey] ?: @"nil"];
    }
    MPILogWarning(@"MPRokt kit (ID %ld) not found in configurations. Available kit IDs: %@",
                  (long)kMPRoktKitId, kitIds);
    return nil;
}

/// Retrieves the attribute mapping configuration for the Rokt Kit from the mParticle dashboard settings.
/// The mapping defines how attribute keys should be renamed before being sent to Rokt (e.g., "userEmail" → "email").
/// @return An array of mapping dictionaries with "map" (source key) and "value" (destination key), or nil if Rokt Kit is not configured.
- (NSArray<NSDictionary<NSString *, NSString *> *> *)getRoktPlacementAttributesMapping {
    NSArray<NSDictionary<NSString *, NSString *> *> *attributeMap = nil;
    
    // Get the kit configuration
    NSDictionary *roktKitConfig = [self getRoktKitConfiguration];
    
    // Return nil if no Rokt Kit configuration found
    if (!roktKitConfig) {
        MPILogWarning(@"MPRokt kit configuration not found");
        return nil;
    }
    
    // Get the placement attributes map
    NSString *strAttributeMap;
    NSData *dataAttributeMap;
    // Rokt Kit is available though there may not be an attribute map
    attributeMap = @[];
    id configJSONString = roktKitConfig[kMPRemoteConfigKitConfigurationKey][kMPPlacementAttributesMapping];
    if (configJSONString != nil && configJSONString != [NSNull null]) {
        strAttributeMap = [configJSONString stringByRemovingPercentEncoding];
        dataAttributeMap = [strAttributeMap dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if (dataAttributeMap != nil) {
        // Convert it to an array of dictionaries
        NSError *error = nil;
        
        @try {
            attributeMap = [NSJSONSerialization JSONObjectWithData:dataAttributeMap options:kNilOptions error:&error];
        } @catch (NSException *exception) {
            MPILogError(@"MPRokt exception parsing placement attribute map: %@", exception);
        }
        
        if (attributeMap && !error) {
            MPILogDebug(@"MPRokt successfully parsed placement attribute map with %lu entries", (unsigned long)attributeMap.count);
        } else {
            MPILogError(@"MPRokt failed to parse placement attribute map: %@", error);
        }
    }
    
    return attributeMap;
}

/// Retrieves the configured identity type to use for hashed email from the Rokt Kit configuration.
/// The hashed email identity type is determined by dashboard settings and may vary (e.g., CustomerId, Other, etc.).
/// @return The NSNumber representing the MPIdentity type for hashed email, or nil if not configured.
- (NSNumber *)getRoktHashedEmailUserIdentityType {
    // Get the kit configuration
    NSDictionary *roktKitConfig = [self getRoktKitConfiguration];
    
    // Get the string representing which identity to use and convert it to the key (NSNumber)
    NSString *hashedIdentityTypeString = roktKitConfig[kMPRemoteConfigKitConfigurationKey][kMPHashedEmailUserIdentityType];
    NSNumber *hashedIdentityTypeNumber = [MPIdentityHTTPIdentities identityTypeForString:hashedIdentityTypeString.lowercaseString];
    
    MPILogDebug(@"MPRokt getRoktHashedEmailUserIdentityType - typeString: %@, typeNumber: %@",
                hashedIdentityTypeString ?: @"nil", hashedIdentityTypeNumber ?: @"nil");
    
    return hashedIdentityTypeNumber;
}

/// Ensures the "sandbox" attribute is present in the attributes dictionary.
/// If not already set by the caller, the sandbox value is automatically determined based on the current mParticle environment
/// (MPEnvironmentDevelopment → "true", production → "false"). This tells Rokt whether to show test or production ads.
/// - Parameter attributes: The input attributes dictionary to validate
/// @return A dictionary with the sandbox attribute guaranteed to be present
- (NSDictionary<NSString *, NSString *> *)confirmSandboxAttribute:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
    NSMutableDictionary<NSString *, NSString *> *finalAttributes = attributes.mutableCopy;
    
    // Determine the value of the sandbox attribute based off the current environment
    MPEnvironment currentEnvironment = [[MParticle sharedInstance] environment];
    NSString *sandboxValue = (currentEnvironment == MPEnvironmentDevelopment) ? @"true" : @"false";
    MPILogDebug(@"MPRokt confirmSandboxAttribute - environment: %ld, sandbox: %@", (long)currentEnvironment, sandboxValue);
    
    if (finalAttributes != nil) {
        // Only set sandbox if it`s not set by the client
        if (![finalAttributes.allKeys containsObject:kMPRoktAttributeKeySandbox]) {
            finalAttributes[kMPRoktAttributeKeySandbox] = sandboxValue;
        }
    } else {
        finalAttributes = [[NSMutableDictionary alloc] initWithDictionary:@{kMPRoktAttributeKeySandbox: sandboxValue}];
    }
    
    return finalAttributes;
}

/// Synchronizes user identity with mParticle if email or hashed email is provided in attributes.
/// If the email or hashed email in attributes differs from the current user's identity, this method performs
/// an identity API call to update the user before proceeding. This ensures Rokt has the most current user identity.
/// - Parameters:
///   - attributes: Dictionary that may contain "email" or "emailsha256" keys
///   - user: The current mParticle user
///   - completion: Completion handler called with the resolved (possibly updated) user
- (void)confirmUser:(NSDictionary<NSString *, NSString *> * _Nullable)attributes user:(MParticleUser * _Nullable)user completion:(void (^)(MParticleUser *_Nullable))completion {
    MPILogDebug(@"MPRokt confirmUser - user: %@, email in attributes: %@, hashedEmail in attributes: %@",
                user.userId,
                attributes[@"email"] ? @"present" : @"nil",
                attributes[@"emailsha256"] ? @"present" : @"nil");
    
    NSString *email = attributes[@"email"];
    NSString *hashedEmail = attributes[@"emailsha256"];
    NSNumber *hashedEmailIdentity = [self getRoktHashedEmailUserIdentityType];
    
    BOOL shouldIdentifyFromEmail = (email && ![email isEqual:user.identities[@(MPIdentityEmail)]]);
    BOOL shouldIdentifyFromHash = (hashedEmail && hashedEmailIdentity && ![hashedEmail isEqual:user.identities[hashedEmailIdentity]]);

    MPILogDebug(@"MPRokt confirmUser decision - shouldIdentifyFromEmail: %@, shouldIdentifyFromHash: %@",
                shouldIdentifyFromEmail ? @"YES" : @"NO",
                shouldIdentifyFromHash ? @"YES" : @"NO");

    if (shouldIdentifyFromEmail || shouldIdentifyFromHash) {
        // Identify the user with the new identity information
        MPIdentityApiRequest *identityRequest = user ? [MPIdentityApiRequest requestWithUser:user] : [MPIdentityApiRequest requestWithEmptyUser];
        [identityRequest setIdentity:email identityType:MPIdentityEmail];
        if (hashedEmailIdentity != nil) {
            [identityRequest setIdentity:hashedEmail identityType:hashedEmailIdentity.unsignedIntegerValue];
        }
        
        MPILogDebug(@"MPRokt confirmUser - calling identity API to sync user");
        [[[MParticle sharedInstance] identity] identify:identityRequest completion:^(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error) {
            if (error) {
                MPILogError(@"MPRokt failed to sync email from selectPlacement to user: %@", error);
                completion(user);
            } else {
                MPILogVerbose(@"MPRokt updated user identity based off selectPlacement's attributes: %@", apiResult.user.identities);
                completion(apiResult.user);
            }
        }];
        
        // Warn the customer if we had to identify and therefore delay their Rokt placement.
        if (shouldIdentifyFromEmail) {
            MPILogWarning(@"MPRokt the existing email on the user does not match the email passed in to `selectPlacements:`. Please remember to sync the email identity to mParticle as soon as you receive it. We will now identify the user before continuing to `selectPlacements:`");
        } else if (shouldIdentifyFromHash) {
            MPILogWarning(@"MPRokt the existing hashed email on the user does not match the hashed email passed in to `selectPlacements:`. Please remember to sync the hashed email identity to mParticle as soon as you receive it. We will now identify the user before continuing to `selectPlacements:`");
        }
    } else {
        completion(user);
    }
}

@end
