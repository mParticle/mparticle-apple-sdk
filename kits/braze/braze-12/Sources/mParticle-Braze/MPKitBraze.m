#import "MPKitBraze.h"

#if TARGET_OS_IOS
    @import BrazeKit;
    @import BrazeKitCompat;
    @import BrazeUI;
#else
    @import BrazeKit;
    @import BrazeKitCompat;
#endif

static NSString *const eabAPIKey = @"apiKey";
static NSString *const eabOptions = @"options";
static NSString *const hostConfigKey = @"host";
static NSString *const userIdTypeKey = @"userIdentificationType";
static NSString *const emailIdTypeKey = @"emailIdentificationType";
static NSString *const enableTypeDetectionKey = @"enableTypeDetection";
static NSString *const bundleCommerceEventData = @"bundleCommerceEventData";
static NSString *const replaceSkuWithProductName = @"replaceSkuWithProductName";
static NSString *const subscriptionGroupMapping = @"subscriptionGroupMapping";

// The possible values for userIdentificationType
static NSString *const userIdValueOther = @"Other";
static NSString *const userIdValueOther2 = @"Other2";
static NSString *const userIdValueOther3 = @"Other3";
static NSString *const userIdValueOther4 = @"Other4";
static NSString *const userIdValueOther5 = @"Other5";
static NSString *const userIdValueOther6 = @"Other6";
static NSString *const userIdValueOther7 = @"Other7";
static NSString *const userIdValueOther8 = @"Other8";
static NSString *const userIdValueOther9 = @"Other9";
static NSString *const userIdValueOther10 = @"Other10";
static NSString *const userIdValueCustomerId = @"CustomerId";
static NSString *const userIdValueFacebook = @"Facebook";
static NSString *const userIdValueTwitter = @"Twitter";
static NSString *const userIdValueGoogle = @"Google";
static NSString *const userIdValueMicrosoft = @"Microsoft";
static NSString *const userIdValueYahoo = @"Yahoo";
static NSString *const userIdValueEmail = @"Email";
static NSString *const userIdValueAlias = @"Alias";
static NSString *const userIdValueMPID = @"MPID";

// User Attribute key with reserved functionality for Braze kit
static NSString *const brazeUserAttributeDob = @"dob";
static NSString *const brazeUserAttributeEmailSubscribe = @"email_subscribe";
static NSString *const brazeUserAttributePushSubscribe = @"push_subscribe";

// Strings used when sending enhanced commerce events
static NSString *const attributesKey = @"Attributes";
static NSString *const productKey = @"products";
static NSString *const promotionKey = @"promotions";
static NSString *const impressionKey = @"impressions";

// Strings used for Google Consent
static NSString *const MPMapKey = @"map";
static NSString *const MPValueKey = @"value";
static NSString *const MPConsentMappingSDKKey = @"consentMappingSDK";
static NSString *const MPGoogleAdUserDataKey = @"google_ad_user_data";
static NSString *const MPGoogleAdPersonalizationKey = @"google_ad_personalization";
static NSString *const BGoogleAdUserDataKey = @"$google_ad_user_data";
static NSString *const BGoogleAdPersonalizationKey = @"$google_ad_personalization";

#if TARGET_OS_IOS
static id<BrazeInAppMessageUIDelegate> inAppMessageControllerDelegate = nil;
static BOOL shouldDisableNotificationHandling = NO;
#endif
static id<BrazeDelegate> urlDelegate = nil;
static Braze *brazeInstance = nil;
static id brazeLocationProvider = nil;
static NSSet<BRZTrackingProperty*> *brazeTrackingPropertyAllowList;

@interface MPKitBraze() {
    Braze *appboyInstance;
    BOOL collectIDFA;
    BOOL forwardScreenViews;
    NSMutableDictionary *subscriptionGroupDictionary;
}

@property (nonatomic) NSString *host;
@property (nonatomic) BOOL enableTypeDetection;

@end


@implementation MPKitBraze

+ (NSNumber *)kitCode {
    return @28;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Appboy" className:@"MPKitAppboy"];
    [MParticle registerExtension:kitRegister];
}

#if TARGET_OS_IOS
+ (void)setInAppMessageControllerDelegate:(id)delegate {
    inAppMessageControllerDelegate = (id<BrazeInAppMessageUIDelegate>)delegate;
}

+ (id<BrazeInAppMessageUIDelegate>)inAppMessageControllerDelegate {
    return inAppMessageControllerDelegate;
}

+ (void)setShouldDisableNotificationHandling:(BOOL)isDisabled {
    shouldDisableNotificationHandling = isDisabled;
}

+ (BOOL)shouldDisableNotificationHandling {
    return shouldDisableNotificationHandling;
}

#endif

+ (void)setURLDelegate:(id)delegate {
    urlDelegate = (id<BrazeDelegate>)delegate;
}

+ (id<BrazeDelegate>)urlDelegate {
    return urlDelegate;
}

+ (void)setBrazeInstance:(id)instance {
    if ([instance isKindOfClass:[Braze class]]) {
        brazeInstance = instance;
    }
}

+ (Braze *)brazeInstance {
    return brazeInstance;
}

+ (void)setBrazeLocationProvider:(nonnull id)instance {
    brazeLocationProvider = instance;
}

+ (void)setBrazeTrackingPropertyAllowList:(nonnull NSSet<BRZTrackingProperty*> *)allowList {
    for (id property in allowList) {
        if (![property isKindOfClass:[BRZTrackingProperty class]]) {
            return;
        }
    }
    brazeTrackingPropertyAllowList = allowList;
}

#pragma mark Private methods
- (NSString *)stringRepresentation:(id)value {
    NSString *stringRepresentation = nil;
    
    if ([value isKindOfClass:[NSString class]]) {
        stringRepresentation = value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        stringRepresentation = [(NSNumber *)value stringValue];
    } else if ([value isKindOfClass:[NSDate class]]) {
        stringRepresentation = [MPKitAPI stringFromDateRFC3339:value];
    } else if ([value isKindOfClass:[NSData class]]) {
        stringRepresentation = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
    
    return stringRepresentation;
}

- (Braze *)appboyInstance {
    return self->appboyInstance;
}

- (void)setAppboyInstance:(Braze *)instance {
    self->appboyInstance = instance;
}

- (NSString *)stripCharacter:(NSString *)character fromString:(NSString *)originalString {
    NSRange range = [originalString rangeOfString:character];
    
    if (range.location == 0) {
        NSMutableString *strippedString = [originalString mutableCopy];
        [strippedString replaceOccurrencesOfString:character withString:@"" options:NSCaseInsensitiveSearch range:range];
        return [strippedString copy];
    } else {
        return originalString;
    }
}

- (NSMutableDictionary *)getSubscriptionGroupIds:(NSString *)subscriptionGroupMap {
    NSMutableDictionary *subscriptionGroupDictionary = [NSMutableDictionary dictionary];
    
    if (!subscriptionGroupMap.length) {
        return subscriptionGroupDictionary;
    }
    
    NSData *subsctiprionGroupData = [subscriptionGroupMap dataUsingEncoding:NSUTF8StringEncoding];

    NSError *error = nil;
    NSArray *subsctiprionGroupDataArray = [NSJSONSerialization JSONObjectWithData:subsctiprionGroupData options:0 error:&error];

    for (NSDictionary *item in subsctiprionGroupDataArray) {
        NSString *key = item[@"map"];
        NSString *value = item[@"value"];
        subscriptionGroupDictionary[key] = value;
    }

    return subscriptionGroupDictionary;
}

- (MPKitExecStatus *)logAppboyCustomEvent:(MPEvent *)event eventType:(NSUInteger)eventType {
    void (^logCustomEvent)(void) = ^{
        NSDictionary *transformedEventInfo = [event.customAttributes transformValuesToString];
        
        NSMutableDictionary *eventInfo = [[NSMutableDictionary alloc] initWithCapacity:event.customAttributes.count];
        [transformedEventInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *strippedKey = [self stripCharacter:@"$" fromString:key];
            eventInfo[strippedKey] = obj;
        }];
        
        NSDictionary *detectedEventInfo = eventInfo;
        if (self->_enableTypeDetection) {
            detectedEventInfo = [self simplifiedDictionary:eventInfo];
        }
        
        // Appboy expects that the properties are non empty when present.
        if (detectedEventInfo && detectedEventInfo.count > 0) {
            [self->appboyInstance logCustomEvent:event.name properties:detectedEventInfo];
        } else {
            [self->appboyInstance logCustomEvent:event.name];
        }
        
        NSString *eventTypeString = [@(eventType) stringValue];
        
        for (NSString *key in eventInfo) {
            NSString *eventTypePlusNamePlusKey = [[NSString stringWithFormat:@"%@%@%@", eventTypeString, event.name, key] lowercaseString];
            NSString *hashValue = [MPKitAPI hashString:eventTypePlusNamePlusKey];
            
            NSDictionary *forwardUserAttributes;
            
            // Delete from array
            forwardUserAttributes = self.configuration[@"ear"];
            if (forwardUserAttributes[hashValue]) {
                [self->appboyInstance.user removeFromCustomAttributeStringArrayWithKey:forwardUserAttributes[hashValue] value:eventInfo[key]];
            }
            
            // Add to array
            forwardUserAttributes = self.configuration[@"eaa"];
            if (forwardUserAttributes[hashValue]) {
                [self->appboyInstance.user addToCustomAttributeStringArrayWithKey:forwardUserAttributes[hashValue] value:eventInfo[key]];
            }
            
            // Add key/value pair
            forwardUserAttributes = self.configuration[@"eas"];
            if (forwardUserAttributes[hashValue]) {
                [self setUserAttribute:forwardUserAttributes[hashValue] value:eventInfo[key]];
            }
        }
    };
    
    if ([NSThread isMainThread]) {
        logCustomEvent();
    } else {
        dispatch_async(dispatch_get_main_queue(), logCustomEvent);
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (BOOL)isAdvertisingTrackingEnabled {
    BOOL advertisingTrackingEnabled = NO;
    Class MPIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    
    if (MPIdentifierManager) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"sharedManager");
        id<NSObject> adIdentityManager = [MPIdentifierManager performSelector:selector];
        selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        advertisingTrackingEnabled = (BOOL)[adIdentityManager performSelector:selector];
#pragma clang diagnostic pop
#pragma clang diagnostic pop
    }
    
    return advertisingTrackingEnabled && collectIDFA;
}

- (NSString *)advertisingIdentifierString {
    NSString *_advertiserId = nil;
    Class MPIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    
    if (MPIdentifierManager) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"sharedManager");
        id<NSObject> adIdentityManager = [MPIdentifierManager performSelector:selector];
        
        selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL advertisingTrackingEnabled = (BOOL)[adIdentityManager performSelector:selector];
        if (advertisingTrackingEnabled) {
            selector = NSSelectorFromString(@"advertisingIdentifier");
            _advertiserId = [[adIdentityManager performSelector:selector] UUIDString];
        }
#pragma clang diagnostic pop
#pragma clang diagnostic pop
    }
    
    return _advertiserId;
}

- (BOOL)isAppTrackingEnabled {
    BOOL appTrackingEnabled = NO;
    Class ATTrackingManager = NSClassFromString(@"ATTrackingManager");
    
    if (ATTrackingManager) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"trackingAuthorizationStatus");
        NSUInteger trackingAuthorizationStatus = (NSUInteger)[ATTrackingManager performSelector:selector];
        appTrackingEnabled = (trackingAuthorizationStatus == 3); // ATTrackingManagerAuthorizationStatusAuthorized
#pragma clang diagnostic pop
#pragma clang diagnostic pop
    }
    
    return appTrackingEnabled;
}

#pragma mark MPKitInstanceProtocol methods
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    
    // Use the static braze instance if set
    [self setAppboyInstance:brazeInstance];
    
    MPKitExecStatus *execStatus = nil;
    
    if (!configuration[eabAPIKey]) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
    _configuration = configuration;
    
    collectIDFA = NO;
    forwardScreenViews = NO;
    
    _host = configuration[hostConfigKey];
    _enableTypeDetection = [configuration[enableTypeDetectionKey] boolValue];
    
    //If Braze is already initialized, immediately "start" the kit, this
    //is here for:
    // 1. Apps that initialize Braze prior to mParticle, and/or
    // 2. Apps that initialize mParticle too late, causing the SDK to miss
    //    the launch notification which would otherwise trigger start().
    if (self->appboyInstance) {
        NSLog(@"mParticle -> Warning: Braze SDK initialized outside of mParticle kit, this will mean Braze settings within the mParticle dashboard such as API key, endpoint URL, flush interval and others will not be respected.");
        [self start];
    } else {
        _started = NO;
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (id const)providerKitInstance {
    return [self started] ? appboyInstance : nil;
}

- (void)start {
    if (!self->appboyInstance) {
        NSDictionary *optionsDict = [self optionsDictionary];
        BRZConfiguration *configuration = [[BRZConfiguration alloc] initWithApiKey:self.configuration[eabAPIKey] endpoint:optionsDict[ABKEndpointKey]];
        
        [configuration.api addSDKMetadata:@[BRZSDKMetadata.mparticle]];
        configuration.api.sdkFlavor = ((NSNumber *)optionsDict[ABKSDKFlavorKey]).intValue;
        configuration.api.requestPolicy = ((NSNumber *)optionsDict[ABKRequestProcessingPolicyOptionKey]).intValue;
        NSNumber *flushIntervalOption = (NSNumber *)optionsDict[ABKFlushIntervalOptionKey] ?: @10; // If not set, use the default 10 seconds specified in Braze SDK header
        configuration.api.flushInterval = flushIntervalOption.doubleValue < 1.0 ? 1.0 : flushIntervalOption.doubleValue; // Ensure value is above the minimum of 1.0 per run time warning from Braze SDK
        configuration.api.trackingPropertyAllowList = brazeTrackingPropertyAllowList;
        
        configuration.sessionTimeout = ((NSNumber *)optionsDict[ABKSessionTimeoutKey]).doubleValue;
        
        configuration.triggerMinimumTimeInterval = ((NSNumber *)optionsDict[ABKMinimumTriggerTimeIntervalKey]).doubleValue;
        
        NSNumber *automaticLocationTrackingOption = (NSNumber *)optionsDict[ABKEnableAutomaticLocationCollectionKey];
        if (automaticLocationTrackingOption != nil && automaticLocationTrackingOption.boolValue && brazeLocationProvider) {
            configuration.location.automaticLocationCollection = YES;
            configuration.location.brazeLocationProvider = brazeLocationProvider;
        }
        
        self->appboyInstance = [[Braze alloc] initWithConfiguration:configuration];
    }
    
    if (!self->appboyInstance) {
        return;
    }
    
    self->forwardScreenViews = self.configuration[@"forwardScreenViews"] && [self.configuration[@"forwardScreenViews"] caseInsensitiveCompare:@"true"] == NSOrderedSame;
    
    self->collectIDFA = self.configuration[@"ABKCollectIDFA"] && [self.configuration[@"ABKCollectIDFA"] caseInsensitiveCompare:@"true"] == NSOrderedSame;
    
    if (self->collectIDFA) {
        [self->appboyInstance setIdentifierForAdvertiser:[self advertisingIdentifierString]];
    }
    [self->appboyInstance setAdTrackingEnabled:[self isAppTrackingEnabled]];
    
    if ([MPKitBraze urlDelegate]) {
        self->appboyInstance.delegate = [MPKitBraze urlDelegate];
    }
    
    self->subscriptionGroupDictionary = [self getSubscriptionGroupIds:self.configuration[subscriptionGroupMapping]];
    
#if TARGET_OS_IOS
    BrazeInAppMessageUI *inAppMessageUI = [[BrazeInAppMessageUI alloc] init];
    inAppMessageUI.delegate = [MPKitBraze inAppMessageControllerDelegate];
    [self->appboyInstance setInAppMessagePresenter:inAppMessageUI];
#endif
    
    FilteredMParticleUser *currentUser = [[self kitApi] getCurrentUserWithKit:self];
    if (currentUser.userId.integerValue != 0) {
        [self updateUser:currentUser request:currentUser.userIdentities];
    }
    
    self->_started = YES;
    
    // Update Consent on start
    [self updateConsent];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (void)stop {
    self->appboyInstance = nil;
    _started = NO;
    _configuration = nil;
}

- (NSMutableDictionary<NSString *, NSObject *> *)optionsDictionary {
    NSArray <NSString *> *serverKeys = @[@"ABKRequestProcessingPolicyOptionKey", @"ABKFlushIntervalOptionKey", @"ABKSessionTimeoutKey", @"ABKMinimumTriggerTimeIntervalKey"];
    NSArray <NSString *> *appboyKeys = @[ABKRequestProcessingPolicyOptionKey, ABKFlushIntervalOptionKey, ABKSessionTimeoutKey, ABKMinimumTriggerTimeIntervalKey];
    NSMutableDictionary<NSString *, NSObject *> *optionsDictionary = [[NSMutableDictionary alloc] initWithCapacity:serverKeys.count];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterNoStyle;
    
    [serverKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull serverKey, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *optionValue = self.configuration[serverKey];
        
        if (optionValue != nil && (NSNull *)optionValue != [NSNull null]) {
            NSString *appboyKey = appboyKeys[idx];
            NSNumber *numberValue = nil;
            @try {
                numberValue = [numberFormatter numberFromString:optionValue];
            } @catch (NSException *exception) {
                numberValue = nil;
            }
            if (numberValue != nil) {
                optionsDictionary[appboyKey] = numberValue;
            }
        }
    }];
    
    if (self.host.length) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
        optionsDictionary[ABKEndpointKey] = self.host;
#pragma clang diagnostic pop
    }
    
    if (optionsDictionary.count == 0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
        optionsDictionary = [[NSMutableDictionary alloc] initWithCapacity:serverKeys.count];
    }
    optionsDictionary[ABKSDKFlavorKey] = @(MPARTICLE);
#pragma clang diagnostic pop
    
#if TARGET_OS_IOS
    optionsDictionary[ABKEnableAutomaticLocationCollectionKey] = @(YES);
    if (self.configuration[@"ABKDisableAutomaticLocationCollectionKey"]) {
        if ([self.configuration[@"ABKDisableAutomaticLocationCollectionKey"] caseInsensitiveCompare:@"true"] == NSOrderedSame) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
            optionsDictionary[ABKEnableAutomaticLocationCollectionKey] = @(NO);
#pragma clang diagnostic pop
        }
    }
#endif
    
    return optionsDictionary;
}

- (MPKitExecStatus *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    [appboyInstance.user incrementCustomUserAttribute:key by:[value integerValue]];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        return [self routeCommerceEvent:(MPCommerceEvent *)event];
    } else {
        return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeUnavailable];
    }
}

- (MPKitExecStatus *)routeCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess forwardCount:0];
    
    if (commerceEvent.action == MPCommerceEventActionPurchase) {
        NSMutableDictionary *baseProductAttributes = [[NSMutableDictionary alloc] init];
        NSDictionary *transactionAttributes = [self simplifiedDictionary:[commerceEvent.transactionAttributes beautifiedDictionaryRepresentation]];
        
        if (transactionAttributes) {
            [baseProductAttributes addEntriesFromDictionary:transactionAttributes];
        }
        
        NSDictionary *commerceEventAttributes = [commerceEvent beautifiedAttributes];
        NSArray *keys = @[kMPExpCECheckoutOptions, kMPExpCECheckoutStep, kMPExpCEProductListName, kMPExpCEProductListSource];
        
        for (NSString *key in keys) {
            if (commerceEventAttributes[key]) {
                baseProductAttributes[key] = commerceEventAttributes[key];
            }
        }
        
        NSDictionary *commerceCustomAttribues = [commerceEvent.customAttributes transformValuesToString];
        for (NSString *key in commerceCustomAttribues) {
            baseProductAttributes[key] = commerceCustomAttribues[key];
        }
        
        NSArray *products = commerceEvent.products;
        NSString *currency = commerceEvent.currency ? : @"USD";
        NSMutableDictionary *properties;
        
        // Add relevant attributes from the commerce event
        properties = [[NSMutableDictionary alloc] init];
        if (baseProductAttributes.count > 0) {
            [properties addEntriesFromDictionary:baseProductAttributes];
        }
        
        if ([_configuration[bundleCommerceEventData] boolValue]) {
            if (commerceEvent.customAttributes.count > 0) {
                [properties removeObjectsForKeys:[commerceEvent.customAttributes allKeys]];
                [properties setValue:commerceEvent.customAttributes forKey:attributesKey];
            }
            NSArray *productArray = [self getProductListParameters:products];
            if (productArray.count > 0) {
                [properties setValue:productArray forKey:productKey];
            }
            NSArray *promotionArray = [self getPromotionListParameters:commerceEvent.promotionContainer.promotions];
            if (promotionArray.count > 0) {
                [properties setValue:promotionArray forKey:promotionKey];
            }
            NSArray *impressionArray = [self getImpressionListParameters:commerceEvent.impressions];
            if (impressionArray.count > 0) {
                [properties setValue:impressionArray forKey:impressionKey];
            }
            
            NSString *eventName = [NSString stringWithFormat:@"eCommerce - %@", [self eventNameForAction:commerceEvent.action]];
            
            [appboyInstance logPurchase:eventName
                               currency:currency
                                  price:[commerceEvent.transactionAttributes.revenue doubleValue]
                             properties:properties];
            
            [execStatus incrementForwardCount];
        } else {
            for (MPProduct *product in products) {
                // Add attributes from the product itself
                NSDictionary *productDictionary = [product beautifiedDictionaryRepresentation];
                if (productDictionary) {
                    [properties addEntriesFromDictionary:productDictionary];
                }
                
                NSString *sanitizedProductName = product.sku;
                if ([@"True" isEqualToString:_configuration[replaceSkuWithProductName]]) {
                    sanitizedProductName = product.name;
                }
                
                // Strips key/values already being passed to Appboy, plus key/values initialized to default values
                keys = @[kMPExpProductSKU, kMPProductCurrency, kMPExpProductUnitPrice, kMPExpProductQuantity];
                [properties removeObjectsForKeys:keys];
                
                [appboyInstance logPurchase:sanitizedProductName
                                   currency:currency
                                      price:[product.price doubleValue]
                                   quantity:[product.quantity integerValue]
                                 properties:properties];
                
                [execStatus incrementForwardCount];
            }
        }
    } else {
        if ([_configuration[bundleCommerceEventData] boolValue]) {
            NSDictionary *transformedEventInfo = [commerceEvent.customAttributes transformValuesToString];
            
            NSMutableDictionary *eventInfo = [[NSMutableDictionary alloc] initWithCapacity:commerceEvent.customAttributes.count];
            [transformedEventInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
                NSString *strippedKey = [self stripCharacter:@"$" fromString:key];
                eventInfo[strippedKey] = obj;
            }];
            
            if (self->_enableTypeDetection) {
                eventInfo = [[self simplifiedDictionary:eventInfo] mutableCopy];
            }
            
            if (commerceEvent.customAttributes.count > 0) {
                [eventInfo removeObjectsForKeys:[commerceEvent.customAttributes allKeys]];
                [eventInfo setValue:commerceEvent.customAttributes forKey:attributesKey];
            }
            NSArray *productArray = [self getProductListParameters:commerceEvent.products];
            if (productArray.count > 0) {
                [eventInfo setValue:productArray forKey:productKey];
            }
            NSArray *promotionArray = [self getPromotionListParameters:commerceEvent.promotionContainer.promotions];
            if (promotionArray.count > 0) {
                [eventInfo setValue:promotionArray forKey:promotionKey];
            }
            NSArray *impressionArray = [self getImpressionListParameters:commerceEvent.impressions];
            if (impressionArray.count > 0) {
                [eventInfo setValue:impressionArray forKey:impressionKey];
            }
            
            NSString *eventName = [NSString stringWithFormat:@"eCommerce - %@", [self eventNameForAction:commerceEvent.action]];
            if ([eventName isEqualToString:@"eCommerce - unknown"]) {
                if (commerceEvent.impressions) {
                    eventName = @"eCommerce - impression";
                } else if (commerceEvent.promotionContainer.action) {
                    eventName = [NSString stringWithFormat:@"eCommerce - %@", [self eventNameForPromotionAction:commerceEvent.promotionContainer.action]];
                }
            }
            
            // Appboy expects that the properties are non empty when present.
            if (eventInfo.count > 0) {
                [self->appboyInstance logCustomEvent:eventName properties:eventInfo];
            } else {
                [self->appboyInstance logCustomEvent:eventName];
            }
            [execStatus incrementForwardCount];
        } else {
            NSArray *expandedInstructions = [commerceEvent expandedInstructions];
            
            for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
                [self logBaseEvent:commerceEventInstruction.event];
                [execStatus incrementForwardCount];
            }
        }
    }
    
    return execStatus;
}

- (MPKitExecStatus *)routeEvent:(MPEvent *)event {
    return [self logAppboyCustomEvent:event eventType:event.type];
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    MPKitExecStatus *execStatus = nil;
    
    if (forwardScreenViews) {
        execStatus = [self logAppboyCustomEvent:event eventType:0];
    } else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeCannotExecute];
    }
    
    return execStatus;
}

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];

#if TARGET_OS_IOS
    if (shouldDisableNotificationHandling) {
        return execStatus;
    }
    
    if (![appboyInstance.notifications handleBackgroundNotificationWithUserInfo:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult fetchResult) {}]) {
        NSLog(@"mParticle -> Invalid Braze remote notification: %@", userInfo);
    }
#endif
    
    return execStatus;
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    [appboyInstance.user unsetCustomAttributeWithKey:key];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    
#if TARGET_OS_IOS
    if (shouldDisableNotificationHandling) {
        return execStatus;
    }
    
    [appboyInstance.notifications registerDeviceToken:deviceToken];
#endif
    
    return execStatus;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    MPKitReturnCode returnCode;
    
    if (optOut) {
        [appboyInstance.user setEmailSubscriptionState:BRZUserSubscriptionStateSubscribed];
        returnCode = MPKitReturnCodeSuccess;
    } else {
        returnCode = MPKitReturnCodeCannotExecute;
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:returnCode];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    MPKitExecStatus *execStatus;
    
    if (!value) {
        [appboyInstance.user unsetCustomAttributeWithKey:key];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
        return execStatus;
    }
    
    value = [self stringRepresentation:value];
    
    if (!value) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
        return execStatus;
    }
    
    if ([key isEqualToString:mParticleUserAttributeFirstName]) {
        [appboyInstance.user setFirstName:value];
    } else if ([key isEqualToString:mParticleUserAttributeLastName]) {
        [appboyInstance.user setLastName:value];
    } else if ([key isEqualToString:mParticleUserAttributeAge]) {
        NSDate *now = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear fromDate:now];
        NSInteger age = 0;
        
        @try {
            age = [value integerValue];
        } @catch (NSException *exception) {
            NSLog(@"mParticle -> Invalid age: %@", value);
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
            return execStatus;
        }
        
        NSDateComponents *birthComponents = [[NSDateComponents alloc] init];
        birthComponents.year = dateComponents.year - age;
        birthComponents.month = 01;
        birthComponents.day = 01;
        
        [appboyInstance.user setDateOfBirth:[calendar dateFromComponents:birthComponents]];
    } else if ([key isEqualToString:brazeUserAttributeDob]) {
        // Expected Date Format @"yyyy'-'MM'-'dd"
        NSCalendar *calendar = [NSCalendar currentCalendar];

        NSString *yearString = [value substringToIndex:4];
        NSRange monthRange = NSMakeRange(5, 2);
        NSString *monthString = [value substringWithRange:monthRange];
        NSRange dayRange = NSMakeRange(8, 2);
        NSString *dayString = [value substringWithRange:dayRange];

        NSInteger year = 0;
        NSInteger month = 0;
        NSInteger day = 0;
           
       @try {
           year = [yearString integerValue];
       } @catch (NSException *exception) {
           NSLog(@"mParticle -> Invalid dob year: %@ \nPlease use this date format @\"yyyy'-'MM'-'dd\"", yearString);
           execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
           return execStatus;
       }
        
        @try {
            month = [monthString integerValue];
        } @catch (NSException *exception) {
            NSLog(@"mParticle -> Invalid dob month: %@ \nPlease use this date format @\"yyyy'-'MM'-'dd\"", monthString);
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
            return execStatus;
        }
        
        @try {
            day = [dayString integerValue];
        } @catch (NSException *exception) {
            NSLog(@"mParticle -> Invalid dob day: %@ \nPlease use this date format @\"yyyy'-'MM'-'dd\"", dayString);
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
            return execStatus;
        }
       
       NSDateComponents *birthComponents = [[NSDateComponents alloc] init];
       birthComponents.year = year;
       birthComponents.month = month;
       birthComponents.day = day;
       
       [appboyInstance.user setDateOfBirth:[calendar dateFromComponents:birthComponents]];
   } else if ([key isEqualToString:mParticleUserAttributeCountry]) {
    [appboyInstance.user setCountry:value];
    } else if ([key isEqualToString:mParticleUserAttributeCity]) {
        [appboyInstance.user setHomeCity:value];
    } else if ([key isEqualToString:mParticleUserAttributeGender]) {
        [appboyInstance.user setGender:BRZUserGender.other];
        if ([value isEqualToString:mParticleGenderMale]) {
            [appboyInstance.user setGender:BRZUserGender.male];
        } else if ([value isEqualToString:mParticleGenderFemale]) {
            [appboyInstance.user setGender:BRZUserGender.female];
        } else if ([value isEqualToString:mParticleGenderNotAvailable]) {
            [appboyInstance.user setGender:BRZUserGender.notApplicable];
        }
    } else if ([key isEqualToString:mParticleUserAttributeMobileNumber] || [key isEqualToString:@"$MPUserMobile"]) {
        [appboyInstance.user setPhoneNumber:value];
    } else if ([key isEqualToString:mParticleUserAttributeZip]){
        [appboyInstance.user setCustomAttributeWithKey:@"Zip" stringValue:value];
    } else if ([key isEqualToString:brazeUserAttributeEmailSubscribe]) {
        if([value isEqualToString:@"opted_in"]) {
            [appboyInstance.user setEmailSubscriptionState:BRZUserSubscriptionStateOptedIn];
        } else if ([value isEqualToString:@"unsubscribed"]) {
            [appboyInstance.user setEmailSubscriptionState:BRZUserSubscriptionStateUnsubscribed];
        } else if ([value isEqualToString:@"subscribed"]) {
            [appboyInstance.user setEmailSubscriptionState:BRZUserSubscriptionStateSubscribed];
        } else {
            NSLog(@"mParticle -> Invalid email_subscribe value: %@", value);
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
            return execStatus;
        }
    } else if ([key isEqualToString:brazeUserAttributePushSubscribe]) {
        if([value isEqualToString:@"opted_in"]) {
            [appboyInstance.user setPushNotificationSubscriptionState:BRZUserSubscriptionStateOptedIn];
        } else if ([value isEqualToString:@"unsubscribed"]) {
            [appboyInstance.user setPushNotificationSubscriptionState:BRZUserSubscriptionStateUnsubscribed];
        } else if ([value isEqualToString:@"subscribed"]) {
            [appboyInstance.user setPushNotificationSubscriptionState:BRZUserSubscriptionStateSubscribed];
        } else {
            NSLog(@"mParticle -> Invalid push_subscribe value: %@", value);
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
            return execStatus;
        }
    } else if (subscriptionGroupDictionary[key]){
        NSString *subscriptionGroupId = subscriptionGroupDictionary[key];
        if ([value isEqualToString:@"1"]) {
            [appboyInstance.user addToSubscriptionGroupWithGroupId:subscriptionGroupId];
        } else if ([value isEqualToString:@"0"]) {
            [appboyInstance.user removeFromSubscriptionGroupWithGroupId:subscriptionGroupId];
        } else {
            NSLog(@"mParticle -> Invalid value type for subscriptionGroupId mapped user attribute key: %@, expected value should be of type BOOL", key);
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
            return execStatus;
        }
    } else {
        key = [self stripCharacter:@"$" fromString:key];
        
        if (!_enableTypeDetection) {
            [appboyInstance.user setCustomAttributeWithKey:key stringValue:value];
        } else {
            NSDictionary *tempConversionDictionary = @{key: value};
            tempConversionDictionary = [self simplifiedDictionary:tempConversionDictionary];
            id obj = tempConversionDictionary[key];
            if ([obj isKindOfClass:[NSString class]]) {
                [appboyInstance.user setCustomAttributeWithKey:key stringValue:obj];
            } else if ([obj isKindOfClass:[NSNumber class]]) {
                if ([self isBoolNumber:obj]) {
                    [appboyInstance.user setCustomAttributeWithKey:key boolValue:((NSNumber *)obj).boolValue];
                } else if ([self isInteger:value]) {
                    [appboyInstance.user setCustomAttributeWithKey:key intValue:((NSNumber *)obj).intValue];
                } else if ([self isFloat:value]) {
                    [appboyInstance.user setCustomAttributeWithKey:key doubleValue:((NSNumber *)obj).doubleValue];
                }
            } else if ([obj isKindOfClass:[NSDate class]]) {
                [appboyInstance.user setCustomAttributeWithKey:key dateValue:obj];
            }
        }
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key values:(nonnull NSArray<NSString *> *)values {
    MPKitExecStatus *execStatus;
    
    if (!values) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
    } else {
        [appboyInstance.user setCustomAttributeArrayWithKey:key array:values];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    }
    
    return execStatus;
}

- (nonnull MPKitExecStatus *)onIdentifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request.userIdentities];
}

- (nonnull MPKitExecStatus *)onLoginComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request.userIdentities];
}

- (nonnull MPKitExecStatus *)onLogoutComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request.userIdentities];
}

- (nonnull MPKitExecStatus *)onModifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request.userIdentities];
}

- (nonnull MPKitExecStatus *)updateUser:(FilteredMParticleUser *)user request:(NSDictionary<NSNumber *,NSString *> *)userIdentities {
    MPKitExecStatus *execStatus = nil;
    
    if (userIdentities) {
        NSMutableDictionary *userIDsCopy = [userIdentities copy];
        NSString *userId;
        
        if (_configuration[userIdTypeKey]) {
            NSString *userIdKey = _configuration[userIdTypeKey];
            if ([userIdKey isEqualToString:userIdValueOther]) {
                if (userIDsCopy[@(MPUserIdentityOther)]) {
                    userId = userIDsCopy[@(MPUserIdentityOther)];
                }
            } else if ([userIdKey isEqualToString:userIdValueOther2]) {
                    if (userIDsCopy[@(MPUserIdentityOther2)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther2)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther3]) {
                    if (userIDsCopy[@(MPUserIdentityOther3)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther3)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther4]) {
                    if (userIDsCopy[@(MPUserIdentityOther4)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther4)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther5]) {
                    if (userIDsCopy[@(MPUserIdentityOther5)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther5)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther6]) {
                    if (userIDsCopy[@(MPUserIdentityOther6)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther6)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther7]) {
                    if (userIDsCopy[@(MPUserIdentityOther7)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther7)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther8]) {
                    if (userIDsCopy[@(MPUserIdentityOther8)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther8)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther9]) {
                    if (userIDsCopy[@(MPUserIdentityOther9)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther9)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueOther10]) {
                    if (userIDsCopy[@(MPUserIdentityOther10)]) {
                        userId = userIDsCopy[@(MPUserIdentityOther10)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueCustomerId]) {
                    if (userIDsCopy[@(MPUserIdentityCustomerId)]) {
                        userId = userIDsCopy[@(MPUserIdentityCustomerId)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueFacebook]) {
                    if (userIDsCopy[@(MPUserIdentityFacebook)]) {
                        userId = userIDsCopy[@(MPUserIdentityFacebook)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueTwitter]) {
                    if (userIDsCopy[@(MPUserIdentityTwitter)]) {
                        userId = userIDsCopy[@(MPUserIdentityTwitter)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueGoogle]) {
                    if (userIDsCopy[@(MPUserIdentityGoogle)]) {
                        userId = userIDsCopy[@(MPUserIdentityGoogle)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueMicrosoft]) {
                    if (userIDsCopy[@(MPUserIdentityMicrosoft)]) {
                        userId = userIDsCopy[@(MPUserIdentityMicrosoft)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueYahoo]) {
                    if (userIDsCopy[@(MPUserIdentityYahoo)]) {
                        userId = userIDsCopy[@(MPUserIdentityYahoo)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueEmail]) {
                    if (userIDsCopy[@(MPUserIdentityEmail)]) {
                        userId = userIDsCopy[@(MPUserIdentityEmail)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueAlias]) {
                    if (userIDsCopy[@(MPUserIdentityAlias)]) {
                        userId = userIDsCopy[@(MPUserIdentityAlias)];
                    }
            } else if ([userIdKey isEqualToString:userIdValueMPID]) {
                    if (user != nil) {
                        userId = user.userId.stringValue;
                    }
            } else {
                    if (userIDsCopy[@(MPUserIdentityCustomerId)]) {
                        userId = userIDsCopy[@(MPUserIdentityCustomerId)];
                    }
            }
        }
        
        if (userId && ![userId isKindOfClass: [NSNull class]]) {
            void (^changeUser)(void) = ^ {
                [self->appboyInstance changeUser:userId];
            };
            
            if ([NSThread isMainThread]) {
                changeUser();
            } else {
                dispatch_async(dispatch_get_main_queue(), changeUser);
            }
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
        }
        
        NSString *userEmail;
        
        if (_configuration[emailIdTypeKey]) {
            NSString *emailIdKey = _configuration[emailIdTypeKey];
            if ([emailIdKey isEqualToString:userIdValueOther]) {
                if (userIDsCopy[@(MPUserIdentityOther)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther2]) {
                if (userIDsCopy[@(MPUserIdentityOther2)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther2)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther3]) {
                if (userIDsCopy[@(MPUserIdentityOther3)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther3)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther4]) {
                if (userIDsCopy[@(MPUserIdentityOther4)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther4)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther5]) {
                if (userIDsCopy[@(MPUserIdentityOther5)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther5)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther6]) {
                if (userIDsCopy[@(MPUserIdentityOther6)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther6)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther7]) {
                if (userIDsCopy[@(MPUserIdentityOther7)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther7)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther8]) {
                if (userIDsCopy[@(MPUserIdentityOther8)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther8)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther9]) {
                if (userIDsCopy[@(MPUserIdentityOther9)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther9)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueOther10]) {
                if (userIDsCopy[@(MPUserIdentityOther10)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityOther10)];
                }
            } else if ([emailIdKey isEqualToString:userIdValueEmail]) {
                if (userIDsCopy[@(MPUserIdentityEmail)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityEmail)];
                }
            } else {
                if (userIDsCopy[@(MPUserIdentityEmail)]) {
                    userEmail = userIDsCopy[@(MPUserIdentityEmail)];
                }
            }
        }
        
        if (userEmail && ![userEmail isKindOfClass: [NSNull class]]) {
            [appboyInstance.user setEmail:userEmail];
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
        }
    }
    
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
}

#if TARGET_OS_IOS
- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center willPresentNotification:(nonnull UNNotification *)notification {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
        
    if (shouldDisableNotificationHandling) {
        return execStatus;
    }

    if (![appboyInstance.notifications handleBackgroundNotificationWithUserInfo:notification.request.content.userInfo fetchCompletionHandler:^(UIBackgroundFetchResult fetchResult) {}]) {
        NSLog(@"mParticle -> Invalid Braze remote notification: %@", notification.request.content.userInfo);
    }
    
    return execStatus;
}

- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response API_AVAILABLE(ios(10.0)) {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    
    if (shouldDisableNotificationHandling) {
        return execStatus;
    }

    if (![appboyInstance.notifications handleUserNotificationWithResponse:response withCompletionHandler:^{}]) {
        NSLog(@"mParticle -> Notification Response rejected by Braze: %@", response);
    }
    
    return execStatus;
}
#endif

- (MPKitExecStatus *)setATTStatus:(MPATTAuthorizationStatus)status withATTStatusTimestampMillis:(NSNumber *)attStatusTimestampMillis {
    BOOL isEnabled = status == MPATTAuthorizationStatusAuthorized;
    [appboyInstance setAdTrackingEnabled:isEnabled];
    return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)setConsentState:(nullable MPConsentState *)state {
    [self updateConsent];

    return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
}

- (void)updateConsent {
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    NSDictionary<NSString *, MPGDPRConsent *> *userConsentMap = currentUser.consentState.gdprConsentState;
    
    // Update from mParticle consent
    if (self.configuration && self.configuration[MPConsentMappingSDKKey]) {
        // Retrieve the array of Consent Map Dictionaries from the Config
        NSData *objectData = [self.configuration[MPConsentMappingSDKKey] dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *consentMappingArray = [NSJSONSerialization JSONObjectWithData:objectData
                                              options:NSJSONReadingMutableContainers
                                                error:nil];
        
        // For each valid Consent Map check if mParticle has a corresponding consent setting and, if so, send to Braze
        for (NSDictionary *consentMappingDict in consentMappingArray) {
            NSString *consentPurpose = consentMappingDict[MPMapKey];
            if (consentMappingDict[MPValueKey] && userConsentMap[consentPurpose.lowercaseString]) {
                NSString *brazeConsentName = consentMappingDict[MPValueKey];
                MPGDPRConsent *consent = userConsentMap[consentPurpose.lowercaseString];
                if ([brazeConsentName isEqualToString:MPGoogleAdUserDataKey]) {
                    [appboyInstance.user setCustomAttributeWithKey:BGoogleAdUserDataKey boolValue:consent.consented];
                } else if ([brazeConsentName isEqualToString:MPGoogleAdPersonalizationKey]) {
                    [appboyInstance.user setCustomAttributeWithKey:BGoogleAdPersonalizationKey boolValue:consent.consented];
                }
            }
        }
    }
}

#pragma mark Configuration Dictionary

- (NSMutableDictionary *)simplifiedDictionary:(NSDictionary *)originalDictionary {
    __block NSMutableDictionary *transformedDictionary = [[NSMutableDictionary alloc] init];
    
    [originalDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if ([value isKindOfClass:[NSString class]]) {
            NSString *stringValue = (NSString *)value;
            NSDate *dateValue = [MPKitAPI dateFromStringRFC3339:stringValue];
            if (dateValue) {
                transformedDictionary[key] = dateValue;
            } else if ([self isInteger:stringValue]) {
                transformedDictionary[key] = [NSNumber numberWithInteger:[stringValue integerValue]];
            } else if ([self isFloat:stringValue]) {
                transformedDictionary[key] = [NSNumber numberWithFloat:[stringValue floatValue]];
            } else if ([stringValue caseInsensitiveCompare:@"true"] == NSOrderedSame) {
                transformedDictionary[key] = @YES;
            } else if ([stringValue caseInsensitiveCompare:@"false"] == NSOrderedSame) {
                transformedDictionary[key] = @NO;
            }
            else {
                transformedDictionary[key] = stringValue;
            }
        } else if ([value isKindOfClass:[NSNumber class]]) {
            transformedDictionary[key] = (NSNumber *)value;
        } else if ([value isKindOfClass:[NSDate class]]) {
            transformedDictionary[key] = (NSDate *)value;
        }
    }];
    
    return transformedDictionary;
}

- (BOOL) isInteger:(NSString *)string {
    NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];

    if([string hasPrefix:@"-"]) {
        NSString *absoluteString = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
        NSRange r = [absoluteString rangeOfCharacterFromSet: nonNumbers];
        
        return r.location == NSNotFound && absoluteString.length > 0;
    } else {
        NSRange r = [string rangeOfCharacterFromSet: nonNumbers];
        
        return r.location == NSNotFound && string.length > 0;
    }
}

- (BOOL) isFloat:(NSString *)string {
    NSArray *numList = [string componentsSeparatedByString:@"."];
    
    if (numList.count == 2) {
        if ([self isInteger:numList[0]] && [self isInteger:numList[1]]) {
            return true;
        }
    }
    
    return false;
}

- (BOOL) isBoolNumber:(NSNumber *)num {
   CFTypeID boolID = CFBooleanGetTypeID();
   CFTypeID numID = CFGetTypeID((__bridge CFTypeRef)(num));
   return numID == boolID;
}

- (void)setEnableTypeDetection:(BOOL)enableTypeDetection {
    _enableTypeDetection = enableTypeDetection;
}

- (NSArray *)getProductListParameters:(NSArray<MPProduct *> *)products {
    NSMutableArray *productArray = [[NSMutableArray alloc] init];
    for (MPProduct *product in products) {
        // Add attributes from the products themselves
        NSMutableDictionary *productDictionary = [[product beautifiedDictionaryRepresentation] mutableCopy];
        
        if (product.userDefinedAttributes.count > 0) {
            [productDictionary removeObjectsForKeys:[product.userDefinedAttributes allKeys]];
            [productDictionary setValue:product.userDefinedAttributes forKey:attributesKey];
        }
                        
        // Adds the product dictionary to the product array being supplied to Braze
        if (productDictionary) {
            [productArray addObject:productDictionary];
        }
    }
    return productArray;
}

- (NSArray *)getPromotionListParameters:(NSArray<MPPromotion *> *)promotions {
    NSMutableArray *promotionArray = [[NSMutableArray alloc] init];
    for (MPPromotion *promotion in promotions) {
        // Add attributes from the promotions themselves
        NSMutableDictionary *promotionDictionary = [[NSMutableDictionary alloc] init];
        promotionDictionary[@"Creative"] = promotion.creative;
        promotionDictionary[@"Name"] = promotion.name;
        promotionDictionary[@"Position"] = promotion.position;
        promotionDictionary[@"Id"] = promotion.promotionId;
                        
        // Adds the promotion dictionary to the promotion array being supplied to Braze
        [promotionArray addObject:promotionDictionary];
    }
    return promotionArray;
}

- (NSArray *)getImpressionListParameters:(NSDictionary<NSString *, __kindof NSSet<MPProduct *> *> *)impressions {
    NSMutableArray *impressionArray = [[NSMutableArray alloc] init];
    for (NSString *impressionName in impressions.allKeys) {
        // Add attributes from the products themselves
        NSMutableDictionary *impressionDictionary = [[NSMutableDictionary alloc] init];
        impressionDictionary[@"Product Impression List"] = impressionName;
        NSArray<MPProduct *> *impressionProducts = [[impressions[impressionName] allObjects] copy];
        impressionDictionary[productKey] = [self getProductListParameters:impressionProducts];

        // Adds the impression dictionary to the impression array being supplied to Braze
        [impressionArray addObject:impressionDictionary];
    }
    return impressionArray;
}

- (NSString *)eventNameForAction:(MPCommerceEventAction)action {
    NSArray *actionNames = @[@"add_to_cart", @"remove_from_cart", @"add_to_wishlist", @"remove_from_wishlist", @"checkout", @"checkout_option", @"click", @"view_detail", @"purchase", @"refund"];
    
    if (action >= actionNames.count) {
        return @"unknown";
    }
    
    return actionNames[(NSUInteger)action];
}

- (NSString *)eventNameForPromotionAction:(MPPromotionAction)action {
    NSArray *actionNames = @[@"click", @"view"];
    
    if (action >= actionNames.count) {
        return @"unknown";
    }
    
    return actionNames[(NSUInteger)action];
}

@end
