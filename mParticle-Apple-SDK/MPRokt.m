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

// Constants for kit configuration keys
static NSString * const kMPKitConfigurationIdKey = @"id";
static NSString * const kMPAttributeMappingSourceKey = @"map";
static NSString * const kMPAttributeMappingDestinationKey = @"value";

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;

@end

@implementation MPRoktEventCallback
@end

@implementation MPRoktEmbeddedView
@end

@implementation MPRoktConfig
@end

@implementation MPRokt

/// Displays a Rokt ad placement with the specified identifier and user attributes.
/// This is a convenience method that calls the full selectPlacements method with nil for optional parameters.
/// - Parameters:
///   - identifier: The Rokt placement identifier configured in the Rokt dashboard (e.g., "checkout_confirmation")
///   - attributes: Optional dictionary of user attributes to pass to Rokt (e.g., email, firstName, etc.)
- (void)selectPlacements:(NSString *)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
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
    MParticleUser *currentUser = [MParticle sharedInstance].identity.currentUser;
    
    // If email is passed in as an attribute and it's different than the existing identity, identify with it
    [self confirmUser:attributes user:currentUser completion:^(MParticleUser *_Nullable resolvedUser) {
        NSArray<NSDictionary<NSString *, NSString *> *> *attributeMap = [self getRoktPlacementAttributesMapping];

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
            
            // Add IDFA to attributes if available
            NSString *idfa = resolvedUser.identities[@(MPIdentityIOSAdvertiserId)];
            if (idfa.length > 0) {
                mappedAttributes[kMPRoktAttributeKeyIDFA] = idfa;
            }
            
            dispatch_async([MParticle messageQueue], ^{
                // Forwarding call to kits
                MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
                [queueParameters addParameter:identifier];
                [queueParameters addParameter:[self confirmSandboxAttribute:mappedAttributes]];
                [queueParameters addParameter:embeddedViews];
                [queueParameters addParameter:config];
                [queueParameters addParameter:callbacks];
                
                SEL roktSelector = @selector(executeWithIdentifier:attributes:embeddedViews:config:callbacks:filteredUser:);
                [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                          event:nil
                                                                     parameters:queueParameters
                                                                    messageType:MPMessageTypeEvent
                                                                       userInfo:nil
                ];
            });
        } else {
            MPILogVerbose(@"[MParticle.Rokt selectPlacements: not performed since Kit not configured");
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

/// Retrieves the attribute mapping configuration for the Rokt Kit from the mParticle dashboard settings.
/// The mapping defines how attribute keys should be renamed before being sent to Rokt (e.g., "userEmail" → "email").
/// @return An array of mapping dictionaries with "map" (source key) and "value" (destination key), or nil if Rokt Kit is not configured.
- (NSArray<NSDictionary<NSString *, NSString *> *> *)getRoktPlacementAttributesMapping {
    NSArray<NSDictionary<NSString *, NSString *> *> *attributeMap = nil;
    
    // Get the kit configuration
    NSArray<NSDictionary *> *kitConfigs = [MParticle sharedInstance].kitContainer_PRIVATE.originalConfig.copy;
    NSDictionary *roktKitConfig;
    for (NSDictionary *kitConfig in kitConfigs) {
        if (kitConfig[kMPKitConfigurationIdKey] != nil && [kitConfig[kMPKitConfigurationIdKey] integerValue] == 181) {
            roktKitConfig = kitConfig;
        }
    }
    
    // Return nil if no Rokt Kit configuration found
    if (!roktKitConfig) {
        MPILogVerbose(@"Rokt kit configuration not found");
        return nil;
    }
    
    // Get the placement attributes map
    NSString *strAttributeMap;
    NSData *dataAttributeMap;
    // Rokt Kit is available though there may not be an attribute map
    attributeMap = @[];
    if (roktKitConfig[kMPPlacementAttributesMapping] != [NSNull null]) {
        strAttributeMap = [roktKitConfig[kMPPlacementAttributesMapping] stringByRemovingPercentEncoding];
        dataAttributeMap = [strAttributeMap dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if (dataAttributeMap != nil) {
        // Convert it to an array of dictionaries
        NSError *error = nil;
        
        @try {
            attributeMap = [NSJSONSerialization JSONObjectWithData:dataAttributeMap options:kNilOptions error:&error];
        } @catch (NSException *exception) {
        }
        
        if (attributeMap && !error) {
            NSLog(@"%@", attributeMap);
        } else {
            NSLog(@"%@", error);
        }
    }
    
    return attributeMap;
}

/// Retrieves the configured identity type to use for hashed email from the Rokt Kit configuration.
/// The hashed email identity type is determined by dashboard settings and may vary (e.g., CustomerId, Other, etc.).
/// @return The NSNumber representing the MPIdentity type for hashed email, or nil if not configured.
- (NSNumber *)getRoktHashedEmailUserIdentityType {
    // Get the kit configuration
    NSArray<NSDictionary *> *kitConfigs = [MParticle sharedInstance].kitContainer_PRIVATE.originalConfig.copy;
    NSDictionary *roktKitConfig;
    for (NSDictionary *kitConfig in kitConfigs) {
        if (kitConfig[kMPKitConfigurationIdKey] != nil && [kitConfig[kMPKitConfigurationIdKey] integerValue] == 181) {
            roktKitConfig = kitConfig;
        }
    }
    
    // Get the string representing which identity to use and convert it to the key (NSNumber)
    NSString *hashedIdentityTypeString = roktKitConfig[kMPHashedEmailUserIdentityType];
    NSNumber *hashedIdentityTypeNumber = [MPIdentityHTTPIdentities identityTypeForString:hashedIdentityTypeString.lowercaseString];
    
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
    NSString *sandboxValue = ([[MParticle sharedInstance] environment] == MPEnvironmentDevelopment) ? @"true" : @"false";
    
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
    NSString *email = attributes[@"email"];
    NSString *hashedEmail = attributes[@"emailsha256"];
    NSNumber *hashedEmailIdentity = [self getRoktHashedEmailUserIdentityType];
    
    BOOL shouldIdentifyFromEmail = (email && ![email isEqualToString:user.identities[@(MPIdentityEmail)]]);
    BOOL shouldIdentifyFromHash = (hashedEmail && hashedEmailIdentity && ![hashedEmail isEqualToString: user.identities[hashedEmailIdentity]]);

    if (shouldIdentifyFromEmail || shouldIdentifyFromHash) {
        // Identify the user with the new identity information
        MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithUser:user];
        [identityRequest setIdentity:email identityType:MPIdentityEmail];
        if (hashedEmailIdentity != nil) {
            [identityRequest setIdentity:hashedEmail identityType:hashedEmailIdentity.unsignedIntegerValue];
        }
        
        [[[MParticle sharedInstance] identity] identify:identityRequest completion:^(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error) {
            if (error) {
                NSLog(@"Failed to sync email from selectPlacement to user: %@", error);
                completion(user);
            } else {
                NSLog(@"Updated user identity based off selectPlacement's attributes: %@", apiResult.user.identities);
                completion(apiResult.user);
            }
        }];
        
        // Warn the customer if we had to identify and therefore delay their Rokt placement.
        if (shouldIdentifyFromEmail) {
            NSLog(@"The existing email on the user (%@) does not match the email passed in to `selectPlacements:` (%@). Please remember to sync the email identity to mParticle as soon as you receive it. We will now identify the user before continuing to `selectPlacements:`", user.identities[@(MPIdentityEmail)], email);
        } else if (shouldIdentifyFromHash) {
            NSLog(@"The existing hashed email on the user (%@) does not match the email passed in to `selectPlacements:` (%@). Please remember to sync the email identity to mParticle as soon as you receive it. We will now identify the user before continuing to `selectPlacements:`", user.identities[hashedEmailIdentity], hashedEmail);
        }
    } else {
        completion(user);
    }
}

@end
