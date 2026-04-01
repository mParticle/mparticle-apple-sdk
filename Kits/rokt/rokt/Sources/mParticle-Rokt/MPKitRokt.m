#import "MPKitRokt.h"
@import Rokt_Widget;
@import RoktContracts;

// Kit version
static NSString * const kMPRoktKitVersion = @"8.3.3";

// Constants for kit configuration keys
static NSString * const kMPKitConfigurationIdKey = @"id";
static NSString * const kMPRemoteConfigKitConfigurationKey = @"as";
static NSString * const kMPAttributeMappingSourceKey = @"map";
static NSString * const kMPAttributeMappingDestinationKey = @"value";

// Rokt attribute keys
static NSString * const kMPRoktAttributeKeySandbox = @"sandbox";

// Rokt kit constants
static NSString * const kMPRoktRemoteConfigKitHashesKey = @"hs";
static NSString * const kMPRemoteConfigUserAttributeFilter = @"ua";
static NSString * const MPKitRoktErrorDomain = @"com.mparticle.kits.rokt";
static NSString * const MPKitRoktErrorMessageKey = @"mParticle-Rokt Error";
static NSString * const kMPPlacementAttributesMapping = @"placementAttributesMapping";
static NSString * const kMPHashedEmailUserIdentityType = @"hashedEmailUserIdentityType";
static NSString * const kMPEventNameSelectPlacements = @"selectPlacements";
static NSString * const kMPRoktIdentityTypeEmailSha256 = @"emailsha256";
static NSString * const kMPRoktIdentityTypeMpid = @"mpid";

// Rokt kit identifier
static NSInteger const kMPRoktKitCode = 181;

static __weak MPKitRokt *roktKit = nil;

@interface MPKitRokt () <MPKitProtocol>

@property (nonatomic, unsafe_unretained) BOOL started;

@end

@implementation MPKitRokt

/*
    mParticle will supply a unique kit code for you. Please contact our team
*/
+ (NSNumber *)kitCode {
    return @(kMPRoktKitCode); // Replace with the actual kit code assigned by mParticle
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Rokt" className:@"MPKitRokt"];
    [MParticle registerExtension:kitRegister];
}

- (MPKitExecStatus *)execStatus:(MPKitReturnCode)returnCode {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.class.kitCode returnCode:returnCode];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    NSString *partnerId = configuration[@"accountId"];

    if (!partnerId) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }

    _configuration = configuration;
    roktKit = self;
    
    NSString *sdkVersion = [MParticle sharedInstance].version;

    // Initialize Rokt SDK here
    [MPKitRokt MPLog:[NSString stringWithFormat:@"Attempting to initialize Rokt with Kit Version: %@", kMPRoktKitVersion]];
    
    [MPKitRokt applyMParticleLogLevel];
    
    // Subscribe to global events to receive RoktInitComplete
    [Rokt globalEventsOnEvent:^(RoktEvent * _Nonnull event) {
        if ([event isKindOfClass:[RoktInitComplete class]]) {
            RoktInitComplete *initComplete = (RoktInitComplete *)event;
            if (initComplete.success) {
                [self start];
                [MPKitRokt MPLog:@"Rokt Init Complete"];
                NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
                [[NSNotificationCenter defaultCenter] postNotificationName:@"mParticle.Rokt.Initialized"
                                                                    object:nil
                                                                  userInfo:userInfo];
            }
        }
    }];

    [Rokt initWithRoktTagId:partnerId mParticleSdkVersion:sdkVersion mParticleKitVersion:kMPRoktKitVersion];
    
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (void)start {
    static dispatch_once_t kitPredicate;

    dispatch_once(&kitPredicate, ^{
        self->_started = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

/// Displays a Rokt ad placement with full configuration options.
/// This method handles user identity synchronization, attribute mapping, and forwards the request to the Rokt SDK.
/// Device identifiers (IDFA/IDFV) are automatically added if available.
/// @param identifier The Rokt placement identifier configured in the Rokt dashboard
/// @param attributes Dictionary of user attributes (email, firstName, etc.). Attributes will be mapped according to dashboard configuration.
/// @param embeddedViews Optional dictionary mapping placement identifiers to embedded view containers for inline placements
/// @param config Optional Rokt configuration from RoktContracts (shared with mParticle core).
/// @param onEvent Optional callback for RoktContracts `RoktEvent` values from the Rokt SDK.
/// @param filteredUser The current user when this placement was requested. Filtered for the kit as per settings in the mParticle UI
/// @return MPKitExecStatus indicating success or failure of the operation
- (MPKitExecStatus *)executeWithIdentifier:(NSString * _Nullable)identifier
                                attributes:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes
                             embeddedViews:(NSDictionary<NSString *, RoktEmbeddedView *> * _Nullable)embeddedViews
                                    config:(RoktConfig * _Nullable)config
                                   onEvent:(void (^ _Nullable)(RoktEvent * _Nonnull))onEvent
                              filteredUser:(FilteredMParticleUser * _Nonnull)filteredUser
                                   options:(RoktPlacementOptions * _Nullable)options {
    [MPKitRokt MPLog:[NSString stringWithFormat:@"Rokt Kit recieved `executeWithIdentifier` method with the following arguments: \n identifier: %@ \n attributes: %@ \n embeddedViews: %@ \n config: %@ \n onEvent: %@ \n filteredUser identities: %@ \n options: %@", identifier, attributes, embeddedViews, config, onEvent, filteredUser.userIdentities, options]];
    NSDictionary<NSString *, NSString *> *finalAtt = [MPKitRokt prepareAttributes:attributes filteredUser:filteredUser performMapping:NO];
    
    // Log custom event for selectPlacements call
    [MPKitRokt logSelectPlacementEvent:finalAtt];

    NSDictionary<NSString *, RoktEmbeddedView *> *confirmedViews = [self confirmEmbeddedViews:embeddedViews];

    RoktPlacementOptions *placementOptions = options ?: [[RoktPlacementOptions alloc] initWithTimestamp:0];

    [Rokt selectPlacementsWithIdentifier:identifier
                              attributes:finalAtt
                              placements:confirmedViews
                                  config:config
                        placementOptions:placementOptions
                                onEvent:onEvent];

    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

/// \param wrapperSdk The type of wrapper SDK
///
/// \param wrapperSdkVersion A string representing the wrapper SDK version
///
- (nonnull MPKitExecStatus *)setWrapperSdk:(MPWrapperSdk)wrapperSdk version:(nonnull NSString *)wrapperSdkVersion {
    RoktFrameworkType roktFrameworkType = [self mapMPWrapperSdkToRoktFrameworkType:wrapperSdk];
    [Rokt setFrameworkTypeWithFrameworkType:roktFrameworkType];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

- (RoktFrameworkType)mapMPWrapperSdkToRoktFrameworkType:(MPWrapperSdk)wrapperSdk {
    switch (wrapperSdk) {
        case MPWrapperSdkCordova:
            return RoktFrameworkTypeCordova;
        case MPWrapperSdkReactNative:
            return RoktFrameworkTypeReactNative;
        case MPWrapperSdkFlutter:
            return RoktFrameworkTypeFlutter;
        default:
            return RoktFrameworkTypeIOS;
    }
}

- (NSDictionary<NSString *, RoktEmbeddedView *> * _Nullable)confirmEmbeddedViews:(NSDictionary<NSString *, RoktEmbeddedView *> * _Nullable)embeddedViews {
    if (!embeddedViews || embeddedViews.count == 0) {
        return @{};
    }

    NSMutableDictionary<NSString *, RoktEmbeddedView *> *safePlacements = [NSMutableDictionary dictionary];
    for (NSString *key in embeddedViews) {
        RoktEmbeddedView *view = embeddedViews[key];
        if ([view isKindOfClass:[UIView class]]) {
            safePlacements[key] = view;
        } else {
            [MPKitRokt MPLog:[NSString stringWithFormat:@"Rokt embedded view is incorrect type. Found: %@ but required: UIView subclass", NSStringFromClass([view class])]];
        }
    }
    return safePlacements;
}

/// Ensures the "sandbox" attribute is present in the attributes dictionary.
/// If not already set by the caller, the sandbox value is automatically determined based on the current mParticle environment
/// (MPEnvironmentDevelopment → "true", production → "false"). This tells Rokt whether to show test or production ads.
/// @param attributes The input attributes dictionary to validate
/// @return A dictionary with the sandbox attribute guaranteed to be present
+ (NSDictionary<NSString *, NSString *> *)confirmSandboxAttribute:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
    NSMutableDictionary<NSString *, NSString *> *finalAttributes = attributes.mutableCopy;
    
    // Determine the value of the sandbox attribute based off the current environment
    NSString *sandboxValue = ([[MParticle sharedInstance] environment] == MPEnvironmentDevelopment) ? @"true" : @"false";
    
    if (finalAttributes != nil) {
        // Only set sandbox if it's not set by the client
        if (![finalAttributes.allKeys containsObject:kMPRoktAttributeKeySandbox]) {
            finalAttributes[kMPRoktAttributeKeySandbox] = sandboxValue;
        }
    } else {
        finalAttributes = [[NSMutableDictionary alloc] initWithDictionary:@{kMPRoktAttributeKeySandbox: sandboxValue}];
    }
    
    [MPKitRokt MPLog:[NSString stringWithFormat:@"Sandbox value: %@", finalAttributes[kMPRoktAttributeKeySandbox]]];
    return finalAttributes;
}

+ (NSDictionary<NSString *, NSString *> * _Nonnull)prepareAttributes:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes filteredUser:(FilteredMParticleUser * _Nullable)filteredUser performMapping:(BOOL)performMapping {
    if (filteredUser == nil && roktKit != nil) {
        filteredUser = [[[MPKitAPI alloc] init] getCurrentUserWithKit:roktKit];
    }
    NSDictionary<NSString *, NSString *> *mappedAttributes = attributes;
    if (performMapping) {
        mappedAttributes = [MPKitRokt mapAttributes:attributes filteredUser:filteredUser];
    }
    
    NSMutableDictionary<NSString *, NSString *> *finalAtt = [[NSMutableDictionary alloc] init];
    [finalAtt addEntriesFromDictionary:mappedAttributes];
    
    // Add all known user identities to the attributes being passed to the Rokt SDK
    [self addIdentityAttributes:finalAtt filteredUser:filteredUser];
    
    // Handle hashed email use case
    [self handleHashedEmail:finalAtt];
    
    // The core SDK does not set sandbox on the user, but we must pass it to Rokt if provided
    if (attributes[kMPRoktAttributeKeySandbox] != nil) {
        [finalAtt addEntriesFromDictionary:@{kMPRoktAttributeKeySandbox: attributes[kMPRoktAttributeKeySandbox]}];
    }
    
    [MPKitRokt MPLog:[NSString stringWithFormat:@"Attributes updated with mapped user Attributes and Identities: %@", finalAtt]];
    return [MPKitRokt confirmSandboxAttribute:finalAtt];
}

+ (NSDictionary<NSString *, NSString *> *)transformValuesToString:(NSDictionary<NSString *, id> * _Nullable)originalDictionary {
    __block NSMutableDictionary<NSString *, NSString *> *transformedDictionary = [[NSMutableDictionary alloc] initWithCapacity:originalDictionary.count];
    Class NSStringClass = [NSString class];
    Class NSNumberClass = [NSNumber class];
    
    [originalDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:NSStringClass]) {
            transformedDictionary[key] = obj;
        } else if ([obj isKindOfClass:NSNumberClass]) {
            NSNumber *numberAttribute = (NSNumber *)obj;
            
            if (numberAttribute == (void *)kCFBooleanFalse || numberAttribute == (void *)kCFBooleanTrue) {
                transformedDictionary[key] = [numberAttribute boolValue] ? @"true" : @"false";
            } else {
                transformedDictionary[key] = [numberAttribute stringValue];
            }
        } else if ([obj isKindOfClass:[NSDate class]]) {
            transformedDictionary[key] = [MPKitAPI stringFromDateRFC3339:obj];
        } else if ([obj isKindOfClass:[NSData class]] && [(NSData *)obj length] > 0) {
            transformedDictionary[key] = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            transformedDictionary[key] = [obj description];
        } else if ([obj isKindOfClass:[NSMutableDictionary class]]) {
            transformedDictionary[key] = [obj description];
        } else if ([obj isKindOfClass:[NSArray class]]) {
            transformedDictionary[key] = [obj description];
        } else if ([obj isKindOfClass:[NSMutableArray class]]) {
            transformedDictionary[key] = [obj description];
        } else if ([obj isKindOfClass:[NSNull class]]) {
            transformedDictionary[key] = @"null";
        }
    }];
    
    return transformedDictionary;
}

/// Retrieves the attribute mapping configuration for the Rokt Kit from the mParticle dashboard settings.
/// The mapping defines how attribute keys should be renamed before being sent to Rokt (e.g., "userEmail" → "email").
/// @param attributes The input attributes dictionary
/// @param filteredUser The current mParticle user
/// @return A dictionary with mapped attributes according to dashboard configuration
+ (NSDictionary<NSString *, NSString *> *)mapAttributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes filteredUser:(FilteredMParticleUser * _Nonnull)filteredUser {
    NSArray<NSDictionary<NSString *, NSString *> *> *attributeMap = nil;
    
    // Get the kit configuration
    NSDictionary *roktKitConfig = [MPKitRokt getKitConfig];
    
    // Return original attributes if no Rokt Kit configuration found
    if (!roktKitConfig) {
        return attributes;
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
            [MPKitRokt MPLog:[NSString stringWithFormat:@"Exception parsing placement attribute map: %@", exception]];
        }
        
        if (attributeMap && !error) {
            [MPKitRokt MPLog:[NSString stringWithFormat:@"Successfully parsed placement attribute map with %lu entries", (unsigned long)attributeMap.count]];
        } else {
            [MPKitRokt MPLog:[NSString stringWithFormat:@"Failed to parse placement attribute map: %@", error]];
        }
    }
    
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
                [[MParticle sharedInstance].identity.currentUser setUserAttribute:key value:mappedAttributes[key]];
            }
        }
        
        // Add userAttributes to the attributes sent to Rokt
        for (NSString *uaKey in filteredUser.userAttributes) {
            if (![mappedAttributes.allKeys containsObject:uaKey]) {
                mappedAttributes[uaKey] = filteredUser.userAttributes[uaKey];
            }
        }
        
        return [MPKitRokt transformValuesToString:mappedAttributes];
    } else {
        return attributes;
    }
}

+ (void)addIdentityAttributes:(NSMutableDictionary<NSString *, NSString *> * _Nullable)attributes filteredUser:(FilteredMParticleUser * _Nonnull)filteredUser {
    NSMutableDictionary<NSString *, NSString *> *identityAttributes = [[NSMutableDictionary alloc] init];
    for (NSNumber *identityNumberKey in filteredUser.userIdentities) {
        NSString *identityStringKey = [MPKitRokt stringForIdentityType:identityNumberKey.unsignedIntegerValue];
        [identityAttributes setObject:filteredUser.userIdentities[identityNumberKey] forKey:identityStringKey];
    }
    
    if (attributes != nil) {
        [attributes addEntriesFromDictionary:identityAttributes];
    } else {
        attributes = identityAttributes;
    }
    
    // Add MPID to the attributes being passed to the Rokt SDK
    attributes[kMPRoktIdentityTypeMpid] = filteredUser.userId.stringValue;
}

+ (void)handleHashedEmail:(NSMutableDictionary<NSString *, NSString *> * _Nullable)attributes {
    NSString *emailKey = [MPKitRokt stringForIdentityType:MPIdentityEmail];
    NSString *hashedEmailValue = attributes[kMPRoktIdentityTypeEmailSha256];
    
    // Remove email if hashed value set
    if (emailKey != kMPRoktIdentityTypeEmailSha256 && hashedEmailValue != nil) {
        [attributes removeObjectForKey:emailKey];
    }
}

+ (NSString *)stringForIdentityType:(MPIdentity)identityType {
    NSNumber *hashedEmailIdentity = [MPKitRokt getRoktHashedEmailUserIdentityType];
    
    if (hashedEmailIdentity && hashedEmailIdentity.unsignedIntValue == identityType) {
        return kMPRoktIdentityTypeEmailSha256;
    }
    
    NSDictionary<NSNumber *, NSString *> *identityStrings = @{@(MPIdentityCustomerId): @"customerid",
                                                             @(MPIdentityEmail): @"email",
                                                             @(MPIdentityFacebook): @"facebook",
                                                             @(MPIdentityFacebookCustomAudienceId): @"facebookcustomaudienceid",
                                                             @(MPIdentityGoogle): @"google",
                                                             @(MPIdentityMicrosoft): @"microsoft",
                                                             @(MPIdentityOther): @"other",
                                                             @(MPIdentityTwitter): @"twitter",
                                                             @(MPIdentityYahoo): @"yahoo",
                                                             @(MPIdentityOther2): @"other2",
                                                             @(MPIdentityOther3): @"other3",
                                                             @(MPIdentityOther4): @"other4",
                                                             @(MPIdentityOther5): @"other5",
                                                             @(MPIdentityOther6): @"other6",
                                                             @(MPIdentityOther7): @"other7",
                                                             @(MPIdentityOther8): @"other8",
                                                             @(MPIdentityOther9): @"other9",
                                                             @(MPIdentityOther10): @"other10",
                                                             @(MPIdentityMobileNumber): @"mobile_number",
                                                             @(MPIdentityPhoneNumber2): @"phone_number_2",
                                                             @(MPIdentityPhoneNumber3): @"phone_number_3",
                                                             @(MPIdentityIOSAdvertiserId): @"ios_idfa",
                                                             @(MPIdentityIOSVendorId): @"ios_idfv",
                                                             @(MPIdentityPushToken): @"push_token",
                                                             @(MPIdentityDeviceApplicationStamp): @"device_application_stamp"};

    return identityStrings[@(identityType)];
}

+ (NSNumber *)identityTypeForString:(NSString *)identityString {
    if (identityString == nil) {
        return nil;
    }
    NSDictionary<NSString *, NSNumber *> *identityNumbers = @{@"customerid": @(MPIdentityCustomerId),
                                                             @"email": @(MPIdentityEmail),
                                                             @"facebook": @(MPIdentityFacebook),
                                                             @"facebookcustomaudienceid": @(MPIdentityFacebookCustomAudienceId),
                                                             @"google": @(MPIdentityGoogle),
                                                             @"microsoft": @(MPIdentityMicrosoft),
                                                             @"other": @(MPIdentityOther),
                                                             @"twitter": @(MPIdentityTwitter),
                                                             @"yahoo": @(MPIdentityYahoo),
                                                             @"other2": @(MPIdentityOther2),
                                                             @"other3": @(MPIdentityOther3),
                                                             @"other4": @(MPIdentityOther4),
                                                             @"other5": @(MPIdentityOther5),
                                                             @"other6": @(MPIdentityOther6),
                                                             @"other7": @(MPIdentityOther7),
                                                             @"other8": @(MPIdentityOther8),
                                                             @"other9": @(MPIdentityOther9),
                                                             @"other10": @(MPIdentityOther10),
                                                             @"mobile_number": @(MPIdentityMobileNumber),
                                                             @"phone_number_2": @(MPIdentityPhoneNumber2),
                                                             @"phone_number_3": @(MPIdentityPhoneNumber3),
                                                             @"ios_idfa": @(MPIdentityIOSAdvertiserId),
                                                             @"ios_idfv": @(MPIdentityIOSVendorId),
                                                             @"push_token": @(MPIdentityPushToken),
                                                             @"device_application_stamp": @(MPIdentityDeviceApplicationStamp)};
    
    return identityNumbers[identityString];
}

#pragma mark - Private Helper Methods

/// Retrieves the Rokt Kit configuration from the kit container.
/// @return The Rokt Kit configuration dictionary, or nil if Rokt Kit is not configured.
+ (NSDictionary * _Nullable)getKitConfig {
    NSArray<NSDictionary *> *kitConfigs = [MParticle sharedInstance].kitContainer_PRIVATE.originalConfig.copy;
    for (NSDictionary *kitConfig in kitConfigs) {
        if ([kitConfig[kMPKitConfigurationIdKey] integerValue] == kMPRoktKitCode) {
            return kitConfig;
        }
    }
   [MPKitRokt MPLog:@"Rokt Kit is not configured in kit container"];
    return nil;
}

/// Retrieves the configured identity type to use for hashed email from the Rokt Kit configuration.
/// The hashed email identity type is determined by dashboard settings and may vary (e.g., CustomerId, Other, etc.).
/// @return The NSNumber representing the MPIdentity type for hashed email, or nil if not configured.
+ (NSNumber * _Nullable)getRoktHashedEmailUserIdentityType {
    NSDictionary *roktKitConfig = [MPKitRokt getKitConfig];
    
    // Get the string representing which identity to use and convert it to the key (NSNumber)
    NSString *hashedIdentityTypeString = roktKitConfig[kMPRemoteConfigKitConfigurationKey][kMPHashedEmailUserIdentityType];
    NSNumber *hashedIdentityTypeNumber = [MPKitRokt identityTypeForString:hashedIdentityTypeString.lowercaseString];
    
    return hashedIdentityTypeNumber;
}

/// Notifies Rokt that a purchase from a placement offer has been finalized.
/// Call this method to inform Rokt about the completion status of an offer purchase initiated from a placement.
/// @param placementId The identifier of the placement where the offer was displayed
/// @param catalogItemId The identifier of the catalog item that was purchased
/// @param success Whether the purchase was successful (YES) or failed (NO)
/// @return MPKitExecStatus indicating success or failure of the operation
- (MPKitExecStatus *)purchaseFinalized:(NSString *)identifier catalogItemId:(NSString *)catalogItemId success:(NSNumber *)success {
    if (identifier != nil && catalogItemId != nil && success != nil) {
        [Rokt purchaseFinalizedWithIdentifier:identifier catalogItemId:catalogItemId success:success.boolValue];
        return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    }
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeFail];
}

- (MPKitExecStatus *)events:(NSString *)identifier onEvent:(void (^ _Nullable)(RoktEvent * _Nonnull))onEvent {
    [Rokt eventsWithIdentifier:identifier onEvent:onEvent];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)globalEvents:(void (^)(RoktEvent * _Nonnull))onEvent {
    [Rokt globalEventsOnEvent:onEvent];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)close {
    [Rokt close];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

/// Set the session id to use for the next execute call.
/// This is useful for cases where you have a session id from a non-native integration,
/// e.g. WebView, and you want the session to be consistent across integrations.
///
/// @param sessionId The session id to be set. Must be a non-empty string.
- (MPKitExecStatus *)setSessionId:(NSString *)sessionId {
    [Rokt setSessionIdWithSessionId:sessionId];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

/// Get the session id to use within a non-native integration e.g. WebView.
///
/// @return The session id or nil if no session is present.
- (NSString *)getSessionId {
    return [Rokt getSessionId];
}

#pragma mark - User attributes and identities

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    MPKitExecStatus *execStatus = nil;
    
    if (identityType == MPUserIdentityEmail) {
        // Set user email in Rokt SDK
        // [Rokt setUserEmail:identityString];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    } else if (identityType == MPUserIdentityCustomerId) {
        // Set user ID in Rokt SDK
        // [Rokt setUserId:identityString];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    } else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeUnavailable];
    }
    
    return execStatus;
}

#pragma mark Application
/*
    Implement this method if your SDK handles a user interacting with a remote notification action
*/
 - (MPKitExecStatus *)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
 }

/*
    Implement this method if your SDK receives and handles remote notifications
*/
 - (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
 }

/*
    Implement this method if your SDK registers the device token for remote notifications
*/
 - (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
 }

/*
    Implement this method if your SDK handles continueUserActivity method from the App Delegate
*/
 - (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
 }

/*
    Implement this method if your SDK handles the iOS 9 and above App Delegate method to open URL with options
*/
 - (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
 }

/*
    Implement this method if your SDK handles the iOS 8 and below App Delegate method open URL
*/
 - (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
 }

#pragma mark User attributes
/*
    Implement this method if your SDK allows for incrementing numeric user attributes.
*/
- (MPKitExecStatus *)onIncrementUserAttribute:(FilteredMParticleUser *)user {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
}

/*
    Implement this method if your SDK resets user attributes.
*/
- (MPKitExecStatus *)onRemoveUserAttribute:(FilteredMParticleUser *)user {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
}

/*
    Implement this method if your SDK sets user attributes.
*/
- (MPKitExecStatus *)onSetUserAttribute:(FilteredMParticleUser *)user {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
}

/*
    Implement this method if your SDK supports setting value-less attributes
*/
- (MPKitExecStatus *)onSetUserTag:(FilteredMParticleUser *)user {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
}

#pragma mark Identity
/*
    Implement this method if your SDK should be notified any time the mParticle ID (MPID) changes. This will occur on initial install of the app, and potentially after a login or logout.
*/
- (MPKitExecStatus *)onIdentifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
}

/*
    Implement this method if your SDK should be notified when the user logs in
*/
- (MPKitExecStatus *)onLoginComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
}

/*
    Implement this method if your SDK should be notified when the user logs out
*/
- (MPKitExecStatus *)onLogoutComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
}

/*
    Implement this method if your SDK should be notified when user identities change
*/
- (MPKitExecStatus *)onModifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
}

#pragma mark Events
/*
    Implement this method if your SDK wants to log any kind of events.
    Please see MPBaseEvent.h
*/
- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        return [self routeCommerceEvent:(MPCommerceEvent *)event];
    } else {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }
}
/*
    Implement this method if your SDK logs user events.
    This requires logBaseEvent to be implemented as well.
    Please see MPEvent.h
*/
 - (MPKitExecStatus *)routeEvent:(MPEvent *)event {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
 }
/*
    Implement this method if your SDK logs screen events
    Please see MPEvent.h
*/
 - (MPKitExecStatus *)logScreen:(MPEvent *)event {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
 }

#pragma mark e-Commerce
/*
    Implement this method if your SDK supports commerce events.
    This requires logBaseEvent to be implemented as well.
    If your SDK does support commerce event, but does not support all commerce event actions available in the mParticle SDK,
    expand the received commerce event into regular events and log them accordingly (see sample code below)
    Please see MPCommerceEvent.h > MPCommerceEventAction for complete list
*/
 - (MPKitExecStatus *)routeCommerceEvent:(MPCommerceEvent *)commerceEvent {
     MPKitExecStatus *execStatus = [self execStatus:MPKitReturnCodeSuccess];

     // In this example, this SDK only supports the 'Purchase' commerce event action
     if (commerceEvent.action == MPCommerceEventActionPurchase) {
             /* Your code goes here. */

             [execStatus incrementForwardCount];
     } else { // Other commerce events are expanded and logged as regular events
         NSArray *expandedInstructions = [commerceEvent expandedInstructions];

         for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
             [self routeEvent:commerceEventInstruction.event];
             [execStatus incrementForwardCount];
         }
     }

     return execStatus;
 }

#pragma mark Assorted
/*
    Implement this method if your SDK implements an opt out mechanism for users.
*/
 - (MPKitExecStatus *)setOptOut:(BOOL)optOut {
     /*  Your code goes here.
         If the execution is not successful, please use a code other than MPKitReturnCodeSuccess for the execution status.
         Please see MPKitExecStatus.h for all exec status codes
      */

     return [self execStatus:MPKitReturnCodeSuccess];
 }

+ (void)MPLog:(NSString *)string {
    NSString *msg = [NSString stringWithFormat:@"%@%@", @"MPRokt -> ", string];
    if ([[MParticle sharedInstance] environment] == MPEnvironmentDevelopment) {
        NSLog(@"%@", msg);
    }
}

#pragma mark - Log Level Mapping

/// Maps mParticle log level to Rokt SDK log level
+ (RoktLogLevel)roktLogLevelFromMParticleLogLevel:(MPILogLevel)mpLogLevel {
    switch (mpLogLevel) {
        case MPILogLevelVerbose:
            return RoktLogLevelVerbose;
        case MPILogLevelDebug:
            return RoktLogLevelDebug;
        case MPILogLevelWarning:
            return RoktLogLevelWarning;
        case MPILogLevelError:
            return RoktLogLevelError;
        case MPILogLevelNone:
        default:
            return RoktLogLevelNone;
    }
}

/// Applies mParticle's current log level to the Rokt SDK
+ (void)applyMParticleLogLevel {
    MPILogLevel mpLogLevel = [MParticle sharedInstance].logLevel;
    RoktLogLevel roktLogLevel = [MPKitRokt roktLogLevelFromMParticleLogLevel:mpLogLevel];
    [Rokt setLogLevel:roktLogLevel];
    [MPKitRokt MPLog:[NSString stringWithFormat:@"Applied log level mapping: mParticle %lu -> Rokt %ld",
                      (unsigned long)mpLogLevel, (long)roktLogLevel]];
}

+ (void)logSelectPlacementEvent:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes {
    MPEvent *event = [[MPEvent alloc] initWithName:kMPEventNameSelectPlacements type:MPEventTypeOther];
    event.customAttributes = attributes;
    [[MParticle sharedInstance] logEvent:event];
    [MPKitRokt MPLog:[NSString stringWithFormat:@"Logged selectplacements custom event with attributes: %@", attributes]];
}

@end
