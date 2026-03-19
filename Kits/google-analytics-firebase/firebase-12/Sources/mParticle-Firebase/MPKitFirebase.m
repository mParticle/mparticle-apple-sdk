#import "MPKitFirebase.h"
#if SWIFT_PACKAGE
    @import Firebase;
#else
    #if __has_include(<FirebaseCore/FirebaseCore.h>)
        #import <FirebaseCore/FirebaseCore.h>
        #import <FirebaseAnalytics/FIRAnalytics.h>
        #import <FirebaseAnalytics/FIRAnalytics+Consent.h>
    #else
        #import "FirebaseCore/FirebaseCore.h"
        #import "FirebaseAnalytics/FIRAnalytics.h"
        #import "FirebaseAnalytics/FIRAnalytics+Consent.h"
    #endif
#endif

@implementation NSString(PRIVATE)

- (NSNumber*)isGranted {
    if ([self isEqualToString:@"Granted"]) {
        return @(YES);
    } else if ([self isEqualToString:@"Denied"]) {
        return @(NO);
    }
    return nil;
}

@end

@interface MPKitFirebase () <MPKitProtocol> {
    BOOL forwardRequestsServerSide;
}

@end

@implementation MPKitFirebase

static NSString *const kMPFIRUserIdValueCustomerID = @"customerId";
static NSString *const kMPFIRUserIdValueMPID = @"mpid";
static NSString *const kMPFIRUserIdValueOther = @"Other";
static NSString *const kMPFIRUserIdValueOther2 = @"Other2";
static NSString *const kMPFIRUserIdValueOther3 = @"Other3";
static NSString *const kMPFIRUserIdValueOther4 = @"Other4";
static NSString *const kMPFIRUserIdValueOther5 = @"Other5";
static NSString *const kMPFIRUserIdValueOther6 = @"Other6";
static NSString *const kMPFIRUserIdValueOther7 = @"Other7";
static NSString *const kMPFIRUserIdValueOther8 = @"Other8";
static NSString *const kMPFIRUserIdValueOther9 = @"Other9";
static NSString *const kMPFIRUserIdValueOther10 = @"Other10";
static NSString *const kMPFIRUserIdValueDeviceStamp = @"DeviceApplicationStamp";

static NSString *const reservedPrefixOne = @"firebase_";
static NSString *const reservedPrefixTwo = @"google_";
static NSString *const reservedPrefixThree = @"ga_";
static NSString *const firebaseAllowedCharacters = @"_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
static NSString *const aToZCharacters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
static NSString *const instanceIdIntegrationKey = @"app_instance_id";

// Consent Mapping Keys
static NSString *const kMPFIRGAAdStorageKey = @"ad_storage";
static NSString *const kMPFIRGAAdUserDataKey = @"ad_user_data";
static NSString *const kMPFIRGAAdPersonalizationKey = @"ad_personalization";
static NSString *const kMPFIRGAAnalyticsStorageKey = @"analytics_storage";

// Default Consent Keys (from mParticle UI)
static NSString *const kMPFIRGA4DefaultAdStorageKey = @"defaultAdStorageConsentSDK";
static NSString *const kMPFIRGA4DefaultAdUserDataKey = @"defaultAdUserDataConsentSDK";
static NSString *const kMPFIRGA4DefaultAdPersonalizationKey = @"defaultAdPersonalizationConsentSDK";
static NSString *const kMPFIRGA4DefaultAnalyticsStorageKey = @"defaultAnalyticsStorageConsentSDK";

const NSInteger FIR_MAX_CHARACTERS_EVENT_NAME_INDEX = 39;
const NSInteger FIR_MAX_CHARACTERS_IDENTITY_NAME_INDEX = 23;
const NSInteger FIR_MAX_CHARACTERS_EVENT_ATTR_VALUE_INDEX = 99;
const NSInteger FIR_MAX_CHARACTERS_IDENTITY_ATTR_VALUE_INDEX = 35;

#pragma mark Static Methods

+ (NSNumber *)kitCode {
    return @243;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Google Analytics for Firebase" className:@"MPKitFirebase"];
    [MParticle registerExtension:kitRegister];
}


- (MPKitExecStatus *)execStatus:(MPKitReturnCode)returnCode {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.class.kitCode returnCode:returnCode];
}

#pragma mark MPKitInstanceProtocol methods
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    return [self didFinishLaunchingWithConfiguration:configuration withConsentState:currentUser.consentState];
}

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration withConsentState:(MPConsentState *)consentState {
    _configuration = configuration;

    if ([FIRApp defaultApp] == nil) {
        NSAssert(NO, @"There is no instance of Firebase. Check the docs and review your code.");
        return [self execStatus:MPKitReturnCodeFail];
    } else {
        if ([self.configuration[kMPFIRForwardRequestsServerSide] isEqualToString: @"True"]) {
            forwardRequestsServerSide = true;
            [self updateInstanceIDIntegration];
        }

        [self updateConsent: consentState];

        _started = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    }

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (id const)providerKitInstance {
    return [self started] ? self : nil;
}

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if (forwardRequestsServerSide) {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }

    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        return [self routeCommerceEvent:(MPCommerceEvent *)event];
    } else {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }
}

- (MPKitExecStatus *)routeCommerceEvent:(MPCommerceEvent *)commerceEvent {
    NSDictionary<NSString *, id> *parameters;
    NSString *eventName;
    if (commerceEvent.promotionContainer) {
        if (commerceEvent.promotionContainer.action == MPPromotionActionClick) {
            eventName = kFIREventSelectPromotion;
        } else if (commerceEvent.promotionContainer.action == MPPromotionActionView) {
            eventName = kFIREventViewPromotion;
        }
        for (MPPromotion *promotion in commerceEvent.promotionContainer.promotions) {
            parameters = [self getParameterForPromotion:promotion commerceEvent:commerceEvent];

            [FIRAnalytics logEventWithName:eventName parameters:parameters];
        }
    } else if (commerceEvent.impressions) {
        eventName = kFIREventViewItemList;
        for (NSString *impressionKey in commerceEvent.impressions) {
            parameters = [self getParameterForImpression:impressionKey commerceEvent:commerceEvent products:commerceEvent.impressions[impressionKey]];

            [FIRAnalytics logEventWithName:eventName parameters:parameters];
        }
    } else {
        parameters = [self getParameterForCommerceEvent:commerceEvent];
        eventName = [self getEventNameForCommerceEvent:commerceEvent parameters:parameters];
        if (!eventName) {
            return [self execStatus:MPKitReturnCodeFail];
        }

        [FIRAnalytics logEventWithName:eventName parameters:parameters];
    }

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    if (forwardRequestsServerSide) {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }

    if (!event || !event.name) {
        return [self execStatus:MPKitReturnCodeFail];
    }

    NSMutableDictionary *screenParameters = [self getParametersForScreen:event];
    [FIRAnalytics logEventWithName:kFIREventScreenView parameters:screenParameters];

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)routeEvent:(MPEvent *)event {
    if (!event || !event.name) {
        return [self execStatus:MPKitReturnCodeFail];
    }

    NSString *standardizedFirebaseEventName = [self standardizeNameOrKey:event.name forEvent:YES];
    event.customAttributes = [self standardizeValues:event.customAttributes forEvent:YES];
    [FIRAnalytics logEventWithName:standardizedFirebaseEventName parameters:event.customAttributes];

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (NSString *)standardizeNameOrKey:(NSString *)nameOrKey forEvent:(BOOL)forEvent {
    NSCharacterSet *whitespacesSet = [NSCharacterSet whitespaceCharacterSet];
    NSMutableCharacterSet *firebaseAllowedCharacterSet = [NSMutableCharacterSet characterSetWithCharactersInString:firebaseAllowedCharacters];
    [firebaseAllowedCharacterSet formUnionWithCharacterSet:whitespacesSet];
    NSCharacterSet *notAllowedChars = [firebaseAllowedCharacterSet invertedSet];
    NSString* allowedNameOrKey = [[nameOrKey componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"  +" options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *trimmedString = [regex stringByReplacingMatchesInString:allowedNameOrKey options:0 range:NSMakeRange(0, [allowedNameOrKey length]) withTemplate:@" "];

    NSString *standardizedString = [trimmedString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if (standardizedString.length > reservedPrefixOne.length && [standardizedString hasPrefix:reservedPrefixOne]) {
        standardizedString = [standardizedString substringFromIndex:reservedPrefixOne.length];
    } else if (standardizedString.length > reservedPrefixTwo.length && [standardizedString hasPrefix:reservedPrefixTwo]) {
        standardizedString = [standardizedString substringFromIndex:reservedPrefixTwo.length];
    } else if (standardizedString.length > reservedPrefixThree.length && [standardizedString hasPrefix:reservedPrefixThree]) {
        standardizedString = [standardizedString substringFromIndex:reservedPrefixThree.length];
    }

    NSCharacterSet *letterSet = [NSCharacterSet characterSetWithCharactersInString:aToZCharacters];

    while (![letterSet characterIsMember:[standardizedString characterAtIndex:0]] && standardizedString.length > 1) {
        standardizedString = [standardizedString substringFromIndex:1];
    }

    if (forEvent) {
        if (standardizedString.length > FIR_MAX_CHARACTERS_EVENT_NAME_INDEX) {
            standardizedString = [standardizedString substringToIndex:FIR_MAX_CHARACTERS_EVENT_NAME_INDEX];
        }
    } else {
        if (standardizedString.length > FIR_MAX_CHARACTERS_IDENTITY_NAME_INDEX) {
            standardizedString = [standardizedString substringToIndex:FIR_MAX_CHARACTERS_IDENTITY_NAME_INDEX];
        }
    }

    return standardizedString;
}

- (id)standardizeValue:(id)value forEvent:(BOOL)forEvent {
    id standardizedValue = value;
    if ([value isKindOfClass:[NSString class]]) {
        if (forEvent) {
            if (((NSString *)standardizedValue).length > FIR_MAX_CHARACTERS_EVENT_ATTR_VALUE_INDEX) {
                standardizedValue = [(NSString *)value substringToIndex:FIR_MAX_CHARACTERS_EVENT_ATTR_VALUE_INDEX];
            }
        } else {
            if (((NSString *)standardizedValue).length > FIR_MAX_CHARACTERS_IDENTITY_ATTR_VALUE_INDEX) {
                standardizedValue = [(NSString *)value substringToIndex:FIR_MAX_CHARACTERS_IDENTITY_ATTR_VALUE_INDEX];
            }
        }
    }

    return standardizedValue;
}

- (NSMutableDictionary<NSString *, id> *)standardizeValues:(NSDictionary<NSString *, id> *)values forEvent:(BOOL)forEvent {
    NSMutableDictionary<NSString *, id>  *standardizedValue = [[NSMutableDictionary alloc] init];

    for (NSString *key in values.allKeys) {
        NSString *standardizedKey = [self standardizeNameOrKey:key forEvent:forEvent];
        standardizedValue[standardizedKey] = [self standardizeValue:values[key] forEvent:forEvent];
    }

    return standardizedValue;
}

- (NSMutableDictionary<NSString *, id> *)getParametersForScreen:(MPEvent *)screenEvent {
    NSMutableDictionary *standardizedScreenParameters = [self standardizeValues:screenEvent.customAttributes forEvent:YES];
    NSString *standardizedFirebaseEventName = [self standardizeNameOrKey:screenEvent.name forEvent:YES];
    standardizedScreenParameters[kFIRParameterScreenName] = standardizedFirebaseEventName;
    return standardizedScreenParameters;
}

- (MPKitExecStatus *)onLoginComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    if (forwardRequestsServerSide) {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }

    NSString *userId = [self userIdForFirebase:user];
    if (userId) {
        [FIRAnalytics setUserID:userId];
        [self logUserAttributes:user.userAttributes];
        return [self execStatus:MPKitReturnCodeSuccess];
    } else {
        return [self execStatus:MPKitReturnCodeFail];
    }
}

- (MPKitExecStatus *)onIdentifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    if (forwardRequestsServerSide) {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }

    NSString *userId = [self userIdForFirebase:user];
    if (userId) {
        [FIRAnalytics setUserID:userId];
        [self logUserAttributes:user.userAttributes];
        return [self execStatus:MPKitReturnCodeSuccess];
    } else {
        return [self execStatus:MPKitReturnCodeFail];
    }
}

- (MPKitExecStatus *)onModifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    if (forwardRequestsServerSide) {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }

    NSString *userId = [self userIdForFirebase:user];
    if (userId) {
        [FIRAnalytics setUserID:userId];
        [self logUserAttributes:user.userAttributes];
        return [self execStatus:MPKitReturnCodeSuccess];
    } else {
        return [self execStatus:MPKitReturnCodeFail];
    }
}

- (MPKitExecStatus *)onLogoutComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    if (forwardRequestsServerSide) {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }

    NSString *userId = [self userIdForFirebase:user];
    if (userId) {
        [FIRAnalytics setUserID:userId];
        return [self execStatus:MPKitReturnCodeSuccess];
    } else {
        return [self execStatus:MPKitReturnCodeFail];
    }
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    if (forwardRequestsServerSide) {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }

    [FIRAnalytics setUserPropertyString:nil forName:[self standardizeNameOrKey:key forEvent:NO]];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(id)value {
    if (forwardRequestsServerSide) {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }

    [FIRAnalytics setUserPropertyString:[NSString stringWithFormat:@"%@", [self standardizeValue:value forEvent:NO]] forName:[self standardizeNameOrKey:key forEvent:NO]];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    if (forwardRequestsServerSide) {
        return [self execStatus:MPKitReturnCodeUnavailable];
    }

    NSString *userId = [self userIdForFirebase:[self.kitApi getCurrentUserWithKit:self]];
    if (userId) {
        [FIRAnalytics setUserID:userId];
        return [self execStatus:MPKitReturnCodeSuccess];
    } else {
        return [self execStatus:MPKitReturnCodeFail];
    }
}

- (void)logUserAttributes:(NSDictionary<NSString *, id> *)userAttributes {
    NSDictionary<NSString *, id> *standardizedUserAttributes = [self standardizeValues:userAttributes forEvent:NO];
    NSArray *userAttributesKeys = standardizedUserAttributes.allKeys;
    for (NSString *attributeKey in userAttributesKeys) {
        [FIRAnalytics setUserPropertyString:standardizedUserAttributes[attributeKey] forName:attributeKey];
    }
}

- (MPKitExecStatus *)setConsentState:(nullable MPConsentState *)state {
    [self updateConsent: state];

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (void)updateConsent:(MPConsentState *)consentState {
    NSArray<NSDictionary *> *mappings = [self mappingForKey: @"consentMappingSDK"];
    NSDictionary<NSString *, NSString *> *mappingsConfig;
    if (mappings != nil) {
        mappingsConfig = [self convertToKeyValuePairs: mappings];
    }

    NSDictionary<NSString *, MPGDPRConsent *> *gdprConsents = consentState.gdprConsentState;

    NSNumber *adStorage = [self resolvedConsentForMappingKey:kMPFIRGAAdStorageKey
                                                  defaultKey:kMPFIRGA4DefaultAdStorageKey
                                                gdprConsents:gdprConsents
                                                     mapping:mappingsConfig];

    NSNumber *adUserData = [self resolvedConsentForMappingKey:kMPFIRGAAdUserDataKey
                                                   defaultKey:kMPFIRGA4DefaultAdUserDataKey
                                                 gdprConsents:gdprConsents
                                                      mapping:mappingsConfig];

    NSNumber *analyticsStorage = [self resolvedConsentForMappingKey:kMPFIRGAAnalyticsStorageKey
                                                         defaultKey:kMPFIRGA4DefaultAnalyticsStorageKey
                                                       gdprConsents:gdprConsents
                                                            mapping:mappingsConfig];

    NSNumber *adPersonalization = [self resolvedConsentForMappingKey:kMPFIRGAAdPersonalizationKey
                                                          defaultKey:kMPFIRGA4DefaultAdPersonalizationKey
                                                        gdprConsents:gdprConsents
                                                             mapping:mappingsConfig];

    NSMutableDictionary *uploadDict = [NSMutableDictionary dictionary];

    if (adStorage != nil) {
        uploadDict[FIRConsentTypeAdStorage] = adStorage.boolValue ? FIRConsentStatusGranted : FIRConsentStatusDenied;
    }
    if (adUserData != nil) {
        uploadDict[FIRConsentTypeAdUserData] = adUserData.boolValue ? FIRConsentStatusGranted : FIRConsentStatusDenied;
    }
    if (analyticsStorage != nil) {
        uploadDict[FIRConsentTypeAnalyticsStorage] = analyticsStorage.boolValue ? FIRConsentStatusGranted : FIRConsentStatusDenied;
    }
    if (adPersonalization != nil) {
        uploadDict[FIRConsentTypeAdPersonalization] = adPersonalization.boolValue ? FIRConsentStatusGranted : FIRConsentStatusDenied;
    }


    // Update consent state with FIRAnalytics
    [FIRAnalytics setConsent:uploadDict];
}

- (NSString *)getEventNameForCommerceEvent:(MPCommerceEvent *)commerceEvent parameters:(NSDictionary<NSString *, id> *)parameters {
    switch (commerceEvent.action) {
        case MPCommerceEventActionAddToCart:
            return kFIREventAddToCart;
        case MPCommerceEventActionRemoveFromCart:
            return kFIREventRemoveFromCart;
        case MPCommerceEventActionAddToWishList:
            return kFIREventAddToWishlist;
        case MPCommerceEventActionCheckout:
            return kFIREventBeginCheckout;
        case MPCommerceEventActionCheckoutOptions: {
            NSArray *firebaseCommerceEventType = commerceEvent.customFlags[kMPFIRCommerceEventType];
            if (firebaseCommerceEventType) {
                if ([firebaseCommerceEventType containsObject:kFIREventAddShippingInfo]) {
                    return kFIREventAddShippingInfo;
                } else if ([firebaseCommerceEventType containsObject:kFIREventAddPaymentInfo]) {
                    return kFIREventAddPaymentInfo;
                }
            }
        }
        case MPCommerceEventActionClick:
            return kFIREventSelectItem;
        case MPCommerceEventActionViewDetail:
            return kFIREventViewItem;
        case MPCommerceEventActionPurchase:
            return kFIREventPurchase;
        case MPCommerceEventActionRefund:
            return kFIREventRefund;
        default:
            return nil;
    }
}

- (NSDictionary<NSString *, id> *)getParameterForPromotion:(MPPromotion *)promotion commerceEvent:(MPCommerceEvent *)commerceEvent {
    NSMutableDictionary<NSString *, id> *parameters = [[self standardizeValues:commerceEvent.customAttributes forEvent:YES] mutableCopy];


    if (promotion.promotionId) {
        [parameters setObject:promotion.promotionId forKey:kFIRParameterPromotionID];
    }
    if (promotion.creative) {
        [parameters setObject:promotion.creative forKey:kFIRParameterCreativeName];
    }
    if (promotion.name) {
        [parameters setObject:promotion.name forKey:kFIRParameterPromotionName];
    }
    if (promotion.position) {
        [parameters setObject:promotion.position forKey:kFIRParameterCreativeSlot];
    }

    return parameters;
}

- (NSDictionary<NSString *, id> *)getParameterForImpression:(NSString *)impressionKey  commerceEvent:(MPCommerceEvent *)commerceEvent products:(NSSet<MPProduct *> *)products {
    NSMutableDictionary<NSString *, id> *parameters = [[self standardizeValues:commerceEvent.customAttributes forEvent:YES] mutableCopy];

    [parameters setObject:impressionKey forKey:kFIRParameterItemListID];
    [parameters setObject:impressionKey forKey:kFIRParameterItemListName];

    if (products.count > 0) {
        NSMutableArray *itemArray = [[NSMutableArray alloc] init];
        for (MPProduct *product in products) {
            NSMutableDictionary<NSString *, id> *productParameters = [[NSMutableDictionary alloc] init];

            if (product.quantity) {
                [productParameters setObject:product.quantity forKey:kFIRParameterQuantity];
            }
            if (product.sku) {
                [productParameters setObject:product.sku forKey:kFIRParameterItemID];
            }
            if (product.name) {
                [productParameters setObject:product.name forKey:kFIRParameterItemName];
            }
            if (product.category) {
                [productParameters setObject:product.category forKey:kFIRParameterItemCategory];
            }
            if (product.price) {
                [productParameters setObject:product.price forKey:kFIRParameterPrice];
            }

            [itemArray addObject:productParameters];
        }

        if (itemArray.count > 0) {
            [parameters setObject:itemArray forKey:kFIRParameterItems];
        }
    }

    return parameters;
}

- (NSDictionary<NSString *, id> *)getParameterForCommerceEvent:(MPCommerceEvent *)commerceEvent {
    NSMutableDictionary<NSString *, id> *parameters = [[self standardizeValues:commerceEvent.customAttributes forEvent:YES] mutableCopy];

    NSMutableArray *itemArray = [[NSMutableArray alloc] init];
    for (MPProduct *product in commerceEvent.products) {
        NSMutableDictionary<NSString *, id> *productParameters = [[NSMutableDictionary alloc] init];

        if (product.quantity) {
            [productParameters setObject:product.quantity forKey:kFIRParameterQuantity];
        }
        if (product.sku) {
            [productParameters setObject:product.sku forKey:kFIRParameterItemID];
        }
        if (product.name) {
            [productParameters setObject:product.name forKey:kFIRParameterItemName];
        }
        if (product.category) {
            [productParameters setObject:product.category forKey:kFIRParameterItemCategory];
        }
        if (product.price) {
            [productParameters setObject:product.price forKey:kFIRParameterPrice];
        }

        [itemArray addObject:productParameters];
    }

    if (itemArray.count > 0) {
        [parameters setObject:itemArray forKey:kFIRParameterItems];
    }

    NSString *currency = commerceEvent.currency;
    if (!currency) {
        NSLog(@"Warning: Currency field required by Firebase was not set, defaulting to 'USD'");
        currency = @"USD";
    }
    [parameters setObject:currency forKey:kFIRParameterCurrency];

    if (commerceEvent.transactionAttributes.revenue) {
        [parameters setObject:commerceEvent.transactionAttributes.revenue forKey:kFIRParameterValue];
    }
    if (commerceEvent.transactionAttributes.transactionId) {
        [parameters setObject:commerceEvent.transactionAttributes.transactionId forKey:kFIRParameterTransactionID];
    }
    if (commerceEvent.transactionAttributes.tax) {
        [parameters setObject:commerceEvent.transactionAttributes.tax forKey:kFIRParameterTax];
    }
    if (commerceEvent.transactionAttributes.shipping) {
        [parameters setObject:commerceEvent.transactionAttributes.shipping forKey:kFIRParameterShipping];
    }
    if (commerceEvent.transactionAttributes.couponCode) {
        [parameters setObject:commerceEvent.transactionAttributes.couponCode forKey:kFIRParameterCoupon];
    }

    if (commerceEvent.action == MPCommerceEventActionClick) {
        [parameters setObject:@"product" forKey:kFIRParameterContentType];
    }

    NSArray *firebaseCommerceEventType = commerceEvent.customFlags[kMPFIRCommerceEventType];
    if (firebaseCommerceEventType) {
        if ([firebaseCommerceEventType containsObject:kFIREventAddShippingInfo]) {
            NSArray *shippingTier = commerceEvent.customFlags[kMPFIRShippingTier];
            if (shippingTier.count > 0) {
                [parameters setObject:shippingTier[0] forKey:kFIRParameterShippingTier];
            }
        }
        if ([firebaseCommerceEventType containsObject:kFIREventAddPaymentInfo]) {
            NSArray *paymentInfo = commerceEvent.customFlags[kMPFIRPaymentType];
            if (paymentInfo.count > 0) {
                [parameters setObject:paymentInfo[0] forKey:kFIRParameterPaymentType];
            }
        }
    }

    return parameters;
}

- (NSString * _Nullable)userIdForFirebase:(FilteredMParticleUser *)currentUser {
    NSString *userId;
    if (currentUser != nil && self.configuration[kMPFIRExternalUserIdentityType] != nil) {
        NSString *externalUserIdentityType = self.configuration[kMPFIRExternalUserIdentityType];

        if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueCustomerID] && currentUser.userIdentities[@(MPUserIdentityCustomerId)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityCustomerId)];
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueMPID] && currentUser.userId != nil) {
            userId = currentUser.userId != 0 ? [currentUser.userId stringValue] : nil;
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueOther] && currentUser.userIdentities[@(MPUserIdentityOther)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther)];
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueOther2] && currentUser.userIdentities[@(MPUserIdentityOther2)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther2)];
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueOther3] && currentUser.userIdentities[@(MPUserIdentityOther3)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther3)];
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueOther4] && currentUser.userIdentities[@(MPUserIdentityOther4)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther4)];
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueOther5] && currentUser.userIdentities[@(MPUserIdentityOther5)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther5)];
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueOther6] && currentUser.userIdentities[@(MPUserIdentityOther6)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther6)];
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueOther7] && currentUser.userIdentities[@(MPUserIdentityOther7)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther7)];
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueOther8] && currentUser.userIdentities[@(MPUserIdentityOther8)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther8)];
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueOther9] && currentUser.userIdentities[@(MPUserIdentityOther9)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther9)];
        } else if ([externalUserIdentityType isEqualToString: kMPFIRUserIdValueOther10] && currentUser.userIdentities[@(MPUserIdentityOther10)] != nil) {
            userId = currentUser.userIdentities[@(MPUserIdentityOther10)];
        } else if ([externalUserIdentityType isEqualToString:kMPFIRUserIdValueDeviceStamp]) {
            userId = [[[MParticle sharedInstance] identity] deviceApplicationStamp];
        }
    }

    if (userId) {
        if ([self.configuration[kMPFIRShouldHashUserId] isEqualToString: @"True"]) {
            userId = [MPKitAPI hashString:[userId lowercaseString]];
        }
    } else {
        NSLog(@"External identity type of %@ not set on the user", self.configuration[kMPFIRExternalUserIdentityType]);
    }
    return userId;
}

- (void)updateInstanceIDIntegration  {
    NSString *appInstanceID = [FIRAnalytics appInstanceID];

    if (appInstanceID.length) {
        NSDictionary<NSString *, NSString *> *integrationAttributes = @{instanceIdIntegrationKey:appInstanceID};
        [[MParticle sharedInstance] setIntegrationAttributes:integrationAttributes forKit:[[self class] kitCode]];
    }
}

#pragma mark - Helpers

- (NSNumber * _Nullable)resolvedConsentForMappingKey:(NSString *)mappingKey
                                          defaultKey:(NSString *)defaultKey
                                        gdprConsents:(NSDictionary<NSString *, MPGDPRConsent *> *)gdprConsents
                                             mapping:(NSDictionary<NSString *, NSString*> *) mapping {

    // Prefer mParticle Consent if available
    NSString *purpose = mapping[mappingKey];
    if (purpose) {
        MPGDPRConsent *consent = gdprConsents[purpose];
        if (consent) {
            return @(consent.consented);
        }
    }

    // Fallback to configuration defaults
    NSString *value = self->_configuration[defaultKey];
    return [value isGranted];
}

- (NSArray<NSDictionary *>*)mappingForKey:(NSString*)key {
    NSString *mappingJson = _configuration[key];
    if (![mappingJson isKindOfClass:[NSString class]]) {
        return nil;
    }

    NSData *jsonData = [mappingJson dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSArray *result = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    if (error) {
        NSLog(@"Failed to parse consent mapping JSON: %@", error.localizedDescription);
        return nil;
    }

    return result;
}

- (NSDictionary*)convertToKeyValuePairs: (NSArray<NSDictionary *>*) mappings {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSDictionary *entry in mappings) {
        NSString *value = entry[@"value"];
        NSString *purpose = [entry[@"map"] lowercaseString];
        if (value && purpose) {
            dict[value] = purpose;
        }
    }
    return dict;
}

@end
