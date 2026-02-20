#import "MPKitFirebaseGA4.h"
#import <FirebaseAnalytics/FirebaseAnalytics.h>
#if __has_include(<FirebaseAnalytics/FIRAnalytics+Consent.h>)
    #import <FirebaseAnalytics/FIRAnalytics+Consent.h>
#endif

static NSString* (^customNameStandardization)(NSString* name) = nil;

@implementation NSString(MPFIRGA4PRIVATE)

- (NSNumber*)isGranted {
    if ([self isEqualToString:@"Granted"]) {
        return @(YES);
    } else if ([self isEqualToString:@"Denied"]) {
        return @(NO);
    }
    return nil;
}

@end

@interface MPKitFirebaseGA4 () <MPKitProtocol> {
    BOOL forwardRequestsServerSide;
}

@end

@implementation MPKitFirebaseGA4

static NSString *const kMPFIRUserIdValueCustomerID = @"CustomerId";
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

static NSString *const reservedPrefixOne = @"firebase_";
static NSString *const reservedPrefixTwo = @"google_";
static NSString *const reservedPrefixThree = @"ga_";
static NSString *const firebaseAllowedCharacters = @"_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
static NSString *const aToZCharacters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
static NSString *const instanceIdIntegrationKey = @"app_instance_id";
static NSString *const invalidFirebaseKey = @"invalid_ga4_key";

// Consent Mapping Keys
static NSString *const kMPFIRGA4AdStorageKey = @"ad_storage";
static NSString *const kMPFIRGA4AdUserDataKey = @"ad_user_data";
static NSString *const kMPFIRGA4AdPersonalizationKey = @"ad_personalization";
static NSString *const kMPFIRGA4AnalyticsStorageKey = @"analytics_storage";

// Default Consent Keys (from mParticle UI)
static NSString *const kMPFIRGA4DefaultAdStorageKey = @"defaultAdStorageConsentSDK";
static NSString *const kMPFIRGA4DefaultAdUserDataKey = @"defaultAdUserDataConsentSDK";
static NSString *const kMPFIRGA4DefaultAdPersonalizationKey = @"defaultAdPersonalizationConsentSDK";
static NSString *const kMPFIRGA4DefaultAnalyticsStorageKey = @"defaultAnalyticsStorageConsentSDK";

// Following limits are based off Google Analytics 360 limits
const NSInteger FIR_MAX_CHARACTERS_EVENT_NAME = 40;
const NSInteger FIR_MAX_CHARACTERS_IDENTITY_NAME = 24;
const NSInteger FIR_MAX_CHARACTERS_EVENT_ATTR_VALUE = 500;
const NSInteger FIR_MAX_CHARACTERS_IDENTITY_ATTR_VALUE = 36;
const NSInteger FIR_MAX_EVENT_PARAMETERS_PROPERTIES = 100;
const NSInteger FIR_MAX_ITEM_PARAMETERS = 25;

#pragma mark Static Methods

+ (NSNumber *)kitCode {
    return @(MPKitInstanceGoogleAnalyticsFirebaseGA4);
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"GA4 for Firebase" className:@"MPKitFirebaseGA4"];
    [MParticle registerExtension:kitRegister];
}

+ (void)setCustomNameStandardization:(NSString * _Nonnull (^_Nullable)(NSString * _Nonnull name))standardization {
    customNameStandardization = standardization;
}

+ (NSString * _Nonnull (^_Nullable)(NSString * _Nonnull name))customNameStandardization {
    return customNameStandardization;
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
        if ([self.configuration[kMPFIRGA4ForwardRequestsServerSide] isEqualToString: @"True"]) {
            forwardRequestsServerSide = true;
        }

        [self updateInstanceIDIntegration];
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
    NSString *initialValue = [nameOrKey copy];
    if ([MPKitFirebaseGA4 customNameStandardization]) {
        initialValue = [MPKitFirebaseGA4 customNameStandardization](initialValue);
    }

    NSMutableCharacterSet *firebaseAllowedCharacterSet = [NSMutableCharacterSet characterSetWithCharactersInString:firebaseAllowedCharacters];
    NSCharacterSet *notAllowedChars = [firebaseAllowedCharacterSet invertedSet];
    NSString* truncatedString = initialValue;
    NSCharacterSet *aTozCharacterSet = [NSCharacterSet characterSetWithCharactersInString:aToZCharacters];

    // Remove any non-alphabetic characters from the beginning of the string
    NSString* standardizedString = truncatedString;
    if (forEvent) {
        while (truncatedString.length > 0 && ![aTozCharacterSet characterIsMember:[truncatedString characterAtIndex:0]]) {
            truncatedString = [truncatedString substringFromIndex:1];
        }

        // Replace all invalid characters with an underscore
        standardizedString = [[truncatedString componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@"_"];
    }

    // Ensure no Firebase reserved prefix's are being used
    if (standardizedString.length > reservedPrefixOne.length && [standardizedString hasPrefix:reservedPrefixOne]) {
        standardizedString = [standardizedString substringFromIndex:reservedPrefixOne.length];
    } else if (standardizedString.length > reservedPrefixTwo.length && [standardizedString hasPrefix:reservedPrefixTwo]) {
        standardizedString = [standardizedString substringFromIndex:reservedPrefixTwo.length];
    } else if (standardizedString.length > reservedPrefixThree.length && [standardizedString hasPrefix:reservedPrefixThree]) {
        standardizedString = [standardizedString substringFromIndex:reservedPrefixThree.length];
    }

    // Truncate to max characters allowed by GA4
    if (forEvent) {
        if (standardizedString.length > FIR_MAX_CHARACTERS_EVENT_NAME) {
            standardizedString = [standardizedString substringToIndex:FIR_MAX_CHARACTERS_EVENT_NAME];
        }
    } else {
        if (standardizedString.length > FIR_MAX_CHARACTERS_IDENTITY_NAME) {
            standardizedString = [standardizedString substringToIndex:FIR_MAX_CHARACTERS_IDENTITY_NAME];
        }
    }

    // If empty set to invalid GA4 key constant
    if (standardizedString.length == 0) {
        standardizedString = invalidFirebaseKey;
    }

    return standardizedString;
}

- (NSString *)standardizeValue:(id)value forEvent:(BOOL)forEvent {
    NSString *finalValue = value;
    if ([value isKindOfClass:[NSString class]]) {
        if (forEvent) {
            if (((NSString *)value).length > FIR_MAX_CHARACTERS_EVENT_ATTR_VALUE) {
                finalValue = [(NSString *)value substringToIndex:FIR_MAX_CHARACTERS_EVENT_ATTR_VALUE];
            }
        } else {
            if (((NSString *)value).length > FIR_MAX_CHARACTERS_IDENTITY_ATTR_VALUE) {
                finalValue = [(NSString *)value substringToIndex:FIR_MAX_CHARACTERS_IDENTITY_ATTR_VALUE];
            }
        }
    }

    return finalValue;
}

- (NSMutableDictionary<NSString *, id> *)standardizeValues:(NSDictionary<NSString *, id> *)values forEvent:(BOOL)forEvent {
    NSMutableDictionary<NSString *, id>  *standardizedValue = [[NSMutableDictionary alloc] init];

    for (NSString *key in values.allKeys) {
        NSString *standardizedKey = [self standardizeNameOrKey:key forEvent:forEvent];
        standardizedValue[standardizedKey] = [self standardizeValue:values[key] forEvent:forEvent];
    }

    [self limitDictionary:standardizedValue maxCount:FIR_MAX_EVENT_PARAMETERS_PROPERTIES];
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

    NSNumber *adStorage = [self resolvedConsentForMappingKey:kMPFIRGA4AdStorageKey
                                                  defaultKey:kMPFIRGA4DefaultAdStorageKey
                                                gdprConsents:gdprConsents
                                                     mapping:mappingsConfig];

    NSNumber *adUserData = [self resolvedConsentForMappingKey:kMPFIRGA4AdUserDataKey
                                                   defaultKey:kMPFIRGA4DefaultAdUserDataKey
                                                 gdprConsents:gdprConsents
                                                      mapping:mappingsConfig];

    NSNumber *analyticsStorage = [self resolvedConsentForMappingKey:kMPFIRGA4AnalyticsStorageKey
                                                         defaultKey:kMPFIRGA4DefaultAnalyticsStorageKey
                                                       gdprConsents:gdprConsents
                                                            mapping:mappingsConfig];

    NSNumber *adPersonalization = [self resolvedConsentForMappingKey:kMPFIRGA4AdPersonalizationKey
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
            NSArray *ga4CommerceEventType = commerceEvent.customFlags[kMPFIRGA4CommerceEventType];
            if (ga4CommerceEventType) {
                if ([ga4CommerceEventType containsObject:kFIREventAddShippingInfo]) {
                    return kFIREventAddShippingInfo;
                } else if ([ga4CommerceEventType containsObject:kFIREventAddPaymentInfo]) {
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

    [self limitDictionary:parameters maxCount:FIR_MAX_EVENT_PARAMETERS_PROPERTIES];
    return parameters;
}

- (NSMutableArray *)getParametersForProducts:(id)products {
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
        if (product.brand) {
            [productParameters setObject:product.brand forKey:kFIRParameterItemBrand];
        }
        if (product.price) {
            [productParameters setObject:product.price forKey:kFIRParameterPrice];
        }
        if (product.position >= 0) {
            id indexParameter = @(product.position);
            [productParameters setObject:indexParameter forKey:kFIRParameterIndex];
        }
        if (product.userDefinedAttributes) {
            for (NSString *productCustomAttribute in product.userDefinedAttributes) {
                [productParameters setObject:product.userDefinedAttributes[productCustomAttribute] forKey:productCustomAttribute];
            }
        }

        [self limitDictionary:productParameters maxCount:FIR_MAX_ITEM_PARAMETERS];
        [itemArray addObject:productParameters];
    }

    return itemArray;
}

- (NSDictionary<NSString *, id> *)getParameterForImpression:(NSString *)impressionKey commerceEvent:(MPCommerceEvent *)commerceEvent products:(NSSet<MPProduct *> *)products {
    NSMutableDictionary<NSString *, id> *parameters = [[self standardizeValues:commerceEvent.customAttributes forEvent:YES] mutableCopy];

    [parameters setObject:impressionKey forKey:kFIRParameterItemListID];
    [parameters setObject:impressionKey forKey:kFIRParameterItemListName];

    if (products.count > 0) {
        NSMutableArray *itemArray = [self getParametersForProducts:products];

        if (itemArray.count > 0) {
            [parameters setObject:itemArray forKey:kFIRParameterItems];
        }
    }

    [self limitDictionary:parameters maxCount:FIR_MAX_EVENT_PARAMETERS_PROPERTIES];
    return parameters;
}

- (NSDictionary<NSString *, id> *)getParameterForCommerceEvent:(MPCommerceEvent *)commerceEvent {
    NSMutableDictionary<NSString *, id> *parameters = [[self standardizeValues:commerceEvent.customAttributes forEvent:YES] mutableCopy];

    NSMutableArray *itemArray = [self getParametersForProducts:commerceEvent.products];

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

    NSArray *ga4CommerceEventType = commerceEvent.customFlags[kMPFIRGA4CommerceEventType];
    if (ga4CommerceEventType) {
        if ([ga4CommerceEventType containsObject:kFIREventAddShippingInfo]) {
            NSArray *shippingTier = commerceEvent.customFlags[kMPFIRGA4ShippingTier];
            if (shippingTier.count > 0) {
                [parameters setObject:shippingTier[0] forKey:kFIRParameterShippingTier];
            }
        }
        if ([ga4CommerceEventType containsObject:kFIREventAddPaymentInfo]) {
            NSArray *paymentInfo = commerceEvent.customFlags[kMPFIRGA4PaymentType];
            if (paymentInfo.count > 0) {
                [parameters setObject:paymentInfo[0] forKey:kFIRParameterPaymentType];
            }
        }
    }

    [self limitDictionary:parameters maxCount:FIR_MAX_EVENT_PARAMETERS_PROPERTIES];
    return parameters;
}

- (NSString * _Nullable)userIdForFirebase:(FilteredMParticleUser *)currentUser {
    NSString *userId;
    if (currentUser != nil && self.configuration[kMPFIRGA4ExternalUserIdentityType] != nil) {
        NSString *externalUserIdentityType = self.configuration[kMPFIRGA4ExternalUserIdentityType];

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
        }
    }

    if (userId) {
        if ([self.configuration[kMPFIRGA4ShouldHashUserId] isEqualToString: @"True"]) {
            userId = [MPIHasher hashString:[userId lowercaseString]];
        }
    } else {
        NSLog(@"External identity type of %@ not set on the user", self.configuration[kMPFIRGA4ExternalUserIdentityType]);
    }
    return userId;
}

- (void)updateInstanceIDIntegration {
    NSString *appInstanceID = [FIRAnalytics appInstanceID];

    if (appInstanceID.length) {
        NSDictionary<NSString *, NSString *> *integrationAttributes = @{instanceIdIntegrationKey:appInstanceID};
        [[MParticle sharedInstance] setIntegrationAttributes:integrationAttributes forKit:[[self class] kitCode]];
    }
}

- (void)limitDictionary:(NSMutableDictionary *)dictionary maxCount:(int)maxCount {
    if ([dictionary count] > maxCount) {
        NSMutableArray *dictionaryKeys = [dictionary.allKeys mutableCopy];
        [dictionaryKeys sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        for (int i = maxCount; i < dictionaryKeys.count; i++) {
            [dictionary removeObjectForKey:dictionaryKeys[i]];
        }
    }
}

#pragma mark - Helpers

- (NSNumber * _Nullable)resolvedConsentForMappingKey:(NSString *)mappingKey
                                          defaultKey:(NSString *)defaultKey
                                        gdprConsents:(NSDictionary<NSString *, MPGDPRConsent *> *)gdprConsents
                                             mapping:(NSDictionary<NSString *, NSString*> *)mapping {

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

- (NSDictionary*)convertToKeyValuePairs:(NSArray<NSDictionary *>*)mappings {
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
