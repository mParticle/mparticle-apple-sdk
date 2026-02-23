#import "MPKitAppsFlyer.h"
#if defined(__has_include) && __has_include(<AppsFlyerLib/AppsFlyerLib.h>)
#import <AppsFlyerLib/AppsFlyerLib.h>
#else
#import "AppsFlyerLib.h"
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#import <UserNotifications/UNUserNotificationCenter.h>
#endif

NSString *const MPKitAppsFlyerConversionResultKey = @"mParticle-AppsFlyer Attribution Result";
NSString *const MPKitAppsFlyerAttributionResultKey = @"mParticle-AppsFlyer Attribution Result";
NSString *const MPKitAppsFlyerAppOpenResultKey = @"mParticle-AppsFlyer App Open Result";
NSString *const MPKitAppsFlyerErrorKey = @"mParticle-AppsFlyer Error";
NSString *const MPKitAppsFlyerErrorDomain = @"mParticle-AppsFlyer";

NSString *const afAppleAppId = @"appleAppId";
NSString *const afDevKey = @"devKey";
NSString *const afAppsFlyerIdIntegrationKey = @"appsflyer_id_integration_setting";
NSString *const kMPKAFCustomerUserId = @"af_customer_user_id";

// Consent Mapping Keys
NSString *const kMPAFAdStorageKey = @"ad_storage";
NSString *const kMPAFAdUserDataKey = @"ad_user_data";
NSString *const kMPAFAdPersonalizationKey = @"ad_personalization";

// Default Consent Keys (from mParticle UI)
NSString *const kMPAFDefaultAdStorageKey = @"defaultAdStorageConsent";
NSString *const kMPAFDefaultAdUserDataKey = @"defaultAdUserDataConsent";
NSString *const kMPAFDefaultAdPersonalizationKey = @"defaultAdPersonalizationConsent";

static AppsFlyerLib *appsFlyerTracker = nil;
static id<AppsFlyerLibDelegate> temporaryDelegate = nil;

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

@interface MPKitAppsFlyer() <AppsFlyerLibDelegate, AppsFlyerDeepLinkDelegate>
@end

@implementation MPKitAppsFlyer

@synthesize kitApi = _kitApi;

- (id)providerKitInstance {
    return appsFlyerTracker;
}

- (void)setProviderKitInstance:(id)tracker {
    appsFlyerTracker = tracker;
}

+ (void)setDelegate:(id)delegate {
    if (appsFlyerTracker) {
        if (appsFlyerTracker.delegate) {
            NSLog(@"Warning: AppsFlyer delegate can not be set because it is already in use by kit. \
                  If you'd like to set your own delegate, please do so before you initialize mParticle.\
                  Note: When setting your own delegate, you will not be able to use \
                  `onAttributionComplete`.");
            return;
        }
        
        appsFlyerTracker.delegate = (id<AppsFlyerLibDelegate>)delegate;
    }
    else {
        temporaryDelegate = (id<AppsFlyerLibDelegate>)delegate;
    }
}

+ (NSNumber *)kitCode {
    return @92;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyer"];
    [MParticle registerExtension:kitRegister];
}

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;
    NSString *appleAppId = configuration[afAppleAppId];
    NSString *devKey = configuration[afDevKey];
    if (!appleAppId || !devKey) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
    appsFlyerTracker = [AppsFlyerLib shared];
    appsFlyerTracker.appleAppID = appleAppId;
    appsFlyerTracker.appsFlyerDevKey = devKey;
    if (temporaryDelegate) {
        appsFlyerTracker.delegate = temporaryDelegate;
        temporaryDelegate = nil;
    }
    else {
        appsFlyerTracker.delegate = self;
    }
    
    appsFlyerTracker.deepLinkDelegate = self;
    
    _configuration = configuration;

    [self updateConsent];
    [appsFlyerTracker waitForATTUserAuthorizationWithTimeoutInterval:60];
    [self start];
    
    BOOL alreadyActive = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (alreadyActive) {
            [self didBecomeActive];
        }

        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
    
    NSString *appsFlyerUID = (NSString *) [appsFlyerTracker getAppsFlyerUID];
    if (appsFlyerUID){
        NSDictionary<NSString *, NSString *> *integrationAttributes = @{afAppsFlyerIdIntegrationKey:appsFlyerUID};
        [[MParticle sharedInstance] setIntegrationAttributes:integrationAttributes forKit:[[self class] kitCode]];
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)start {
    self->_started = YES;
}

- (nonnull MPKitExecStatus *)didBecomeActive {
    [appsFlyerTracker start];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options {
    [appsFlyerTracker handleOpenUrl:url options:options];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [appsFlyerTracker handleOpenURL:url sourceApplication:sourceApplication withAnnotation:annotation];
#pragma clang diagnostic pop
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler API_AVAILABLE(ios(9.0)){
    [appsFlyerTracker continueUserActivity:userActivity restorationHandler:restorationHandler];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)receivedUserNotification:(nonnull NSDictionary *)userInfo {
    [appsFlyerTracker handlePushNotification:userInfo];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center willPresentNotification:(nonnull UNNotification *)notification API_AVAILABLE(ios(10.0)){
    [appsFlyerTracker handlePushNotification:notification.request.content.userInfo];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response API_AVAILABLE(ios(10.0)){
    [appsFlyerTracker handlePushNotification:response.notification.request.content.userInfo];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}
#endif

- (nonnull MPKitExecStatus *)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType {
    MPKitExecStatus *execStatus;
    if (identityType == MPUserIdentityCustomerId) {
        [appsFlyerTracker setCustomerUserID:identityString];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    } else if (identityType == MPUserIdentityEmail) {
        if (identityString) {
            [appsFlyerTracker setUserEmails:@[identityString] withCryptType:EmailCryptTypeNone];
        }
        else {
            [appsFlyerTracker setUserEmails:nil withCryptType:EmailCryptTypeNone];
        }
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    } else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeFail];
    }
    return execStatus;
}

+ (NSString * _Nullable)generateProductIdList:(nullable MPCommerceEvent *)event {
    NSString *csvString = nil;
    if (event != nil) {
        NSArray *products = event.products;
        if (products != nil && products.count > 0) {
            NSMutableArray *productSkuArray = [NSMutableArray array];
            for (int i = 0; i < products.count; i += 1) {
                MPProduct *product = products[i];
                NSString *sku = product.sku;
                if (sku != nil && sku.length > 0) {
                    NSString *skuNoCommas = [sku stringByReplacingOccurrencesOfString:@"," withString:@"%2C"];
                    if (skuNoCommas) {
                        [productSkuArray addObject:skuNoCommas];
                    }
                }
            }
            if (productSkuArray.count > 0) {
                NSString *productsString = [productSkuArray componentsJoinedByString:@","];
                if (productsString) {
                    csvString = productsString;
                }
            }
        }
    }
    return csvString;
}

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        return [self routeCommerceEvent:(MPCommerceEvent *)event];
    } else {
        return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeUnavailable];
    }
}

- (nonnull MPKitExecStatus *)routeCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus;
    
    // If a customer id is available, add it to the commerce event user defined attributes
    FilteredMParticleUser *user = [self currentUser];
    NSString *customerId = [user.userId stringValue];
    if (customerId.length) {
        MPCommerceEvent *surrogateCommerceEvent = [commerceEvent copy];
        NSMutableDictionary *mutableInfo = surrogateCommerceEvent.customAttributes ? [surrogateCommerceEvent.customAttributes mutableCopy] : [NSMutableDictionary dictionary];
        mutableInfo[kMPKAFCustomerUserId] = customerId;
        surrogateCommerceEvent.customAttributes = mutableInfo;
        commerceEvent = surrogateCommerceEvent;
    }
    
    MPCommerceEventAction action = commerceEvent.action;
    
    if (action == MPCommerceEventActionAddToCart ||
        action == MPCommerceEventActionAddToWishList ||
        action == MPCommerceEventActionCheckout ||
        action == MPCommerceEventActionPurchase)
    {
        NSMutableDictionary *values = commerceEvent.customAttributes ? [commerceEvent.customAttributes mutableCopy] : [NSMutableDictionary dictionary];
        if (commerceEvent.currency) {
            values[AFEventParamCurrency] = commerceEvent.currency;
        }
        
        NSString *customerUserId = commerceEvent.customAttributes[kMPKAFCustomerUserId];
        if (customerUserId) {
            values[kMPKAFCustomerUserId] = customerUserId;
        }
        
        NSString *appsFlyerEventName = nil;
        if (action == MPCommerceEventActionAddToCart || action == MPCommerceEventActionAddToWishList) {
            NSArray<MPProduct *> *products = commerceEvent.products;
            NSMutableDictionary *productValues = nil;
            NSUInteger initialForwardCount = [products count] > 0 ? 0 : 1;
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess forwardCount:initialForwardCount];
            appsFlyerEventName = action == MPCommerceEventActionAddToCart ? AFEventAddToCart : AFEventAddToWishlist;
            
            for (MPProduct *product in products) {
                productValues = [values mutableCopy];
                if (product.price) {
                    productValues[AFEventParamPrice] = product.price;
                }
                
                if (product.quantity) {
                    productValues[AFEventParamQuantity] = product.quantity;
                }
                
                if (product.sku) {
                    productValues[AFEventParamContentId] = product.sku;
                }
                
                if (product.category) {
                    productValues[AFEventParamContentType] = product.category;
                }
                
                [appsFlyerTracker logEvent:appsFlyerEventName withValues:productValues ? productValues : values];
                [execStatus incrementForwardCount];
            }
        } else {
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
            appsFlyerEventName = action == MPCommerceEventActionCheckout ? AFEventInitiatedCheckout : AFEventPurchase;
            NSNumber *quantity = [MPKitAppsFlyer computeProductQuantity:commerceEvent];
            if (quantity != nil) {
                values[AFEventParamQuantity] = quantity;
            }
            
            NSString *csvString = [MPKitAppsFlyer generateProductIdList:commerceEvent];
            if (csvString != nil) {
                values[AFEventParamContentId] = csvString;
            }
            
            MPTransactionAttributes *transactionAttributes = commerceEvent.transactionAttributes;
            if (transactionAttributes.revenue.intValue) {
                if (action == MPCommerceEventActionPurchase) {
                    values[AFEventParamRevenue] = transactionAttributes.revenue;
                    if (transactionAttributes.transactionId.length) {
                        values[AFEventParamOrderId] = transactionAttributes.transactionId;
                    }
                } else {
                    values[AFEventParamPrice] = transactionAttributes.revenue;
                }
            }
            
            [appsFlyerTracker logEvent:appsFlyerEventName withValues:values];
        }
    }
    else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess forwardCount:0];
        NSArray *expandedInstructions = [commerceEvent expandedInstructions];
        for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
            [self logBaseEvent:commerceEventInstruction.event];
            [execStatus incrementForwardCount];
        }
    }
    return execStatus;
}

+ (nonnull NSNumber *) computeProductQuantity: (nullable MPCommerceEvent *) event {
    int quantity = 0;
    if ([event.products count] > 0) {
        for (MPProduct *product in event.products) {
            if ([product.quantity intValue] > 0){
                quantity += [product.quantity intValue];
            } else {
                quantity += 1;
            }
        }
    } else {
        quantity = 1;
    }
    return [NSNumber numberWithInt:quantity];
}

- (nonnull MPKitExecStatus *)routeEvent:(nonnull MPEvent *)event {
    
    // If a customer id is available, add it to the event attributes
    FilteredMParticleUser *user = [self currentUser];
    NSString *customerId = [user.userId stringValue];
    if (customerId.length) {
        MPEvent *surrogateEvent = [event copy];
        NSMutableDictionary *mutableInfo = surrogateEvent.customAttributes ? [surrogateEvent.customAttributes mutableCopy] : [NSMutableDictionary dictionary];
        mutableInfo[kMPKAFCustomerUserId] = customerId;
        surrogateEvent.customAttributes = mutableInfo;
        event = surrogateEvent;
    }
    
    NSString *eventName = event.name;
    NSDictionary *eventValues = event.customAttributes ? [event.customAttributes mutableCopy] : [NSMutableDictionary dictionary];
    [appsFlyerTracker logEvent:eventName withValues:eventValues];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)setOptOut:(BOOL)optOut {
    appsFlyerTracker.isStopped = optOut;
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (NSError *)errorWithMessage:(NSString *)message {
    NSError *error = [NSError errorWithDomain:MPKitAppsFlyerErrorDomain code:0 userInfo:@{MPKitAppsFlyerErrorKey:message}];
    return error;
}

- (void)onConversionDataSuccess:(NSDictionary *)installData {
    if (!installData) {
        [_kitApi onAttributionCompleteWithResult:nil error:[self errorWithMessage:@"Received nil installData from AppsFlyer"]];
        return;
    }
    
    NSMutableDictionary *outerDictionary = [NSMutableDictionary dictionary];
    outerDictionary[MPKitAppsFlyerConversionResultKey] = installData;
    
    MPAttributionResult *attributionResult = [[MPAttributionResult alloc] init];
    attributionResult.linkInfo = outerDictionary;
    
    [_kitApi onAttributionCompleteWithResult:attributionResult error:nil];
}

- (void)onConversionDataFail:(NSError *)error {
    [_kitApi onAttributionCompleteWithResult:nil error:error];
}

- (void)onAppOpenAttribution:(NSDictionary *)attributionData {
    // do nothing, Appsflyer new UDL implementation will use new deep linking method with both
    // custom URI and appsflyer's Onelink
}

- (void)onAppOpenAttributionFailure:(NSError *)error {
    // do nothing, Appsflyer new UDL implementation will use new deep linking method with both
    // custom URI and appsflyer's Onelink
}

- (void)didResolveDeepLink:(AppsFlyerDeepLinkResult *)result {
    switch (result.status) {
        case AFSDKDeepLinkResultStatusFound:
        {
            NSLog(@"[AFSDK] Deep link found");
            
            if (result.deepLink == nil) {
                NSLog(@"[AFSDK] Could not extract deep link object");
                return;
            }
            
            NSMutableDictionary *outerDictionary = [NSMutableDictionary dictionary];
            outerDictionary[MPKitAppsFlyerAppOpenResultKey] = result.deepLink.clickEvent;
            
            MPAttributionResult *attributionResult = [[MPAttributionResult alloc] init];
            attributionResult.linkInfo = outerDictionary;
            
            [_kitApi onAttributionCompleteWithResult:attributionResult error:nil];
            break;
        }
        case AFSDKDeepLinkResultStatusNotFound:
        {
            NSLog(@"[AFSDK] Deep link not found");
            break;
        }
        default:
        {
            NSLog(@"Error %@", result.error);
            break;
        }
    }
}

- (MPKitAPI *)kitApi {
    if (_kitApi == nil) {
        _kitApi = [[MPKitAPI alloc] init];
    }
    
    return _kitApi;
}

- (MPKitExecStatus *)setConsentState:(nullable MPConsentState *)state {
    [self updateConsent];
    return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer)
                                         returnCode:MPKitReturnCodeSuccess];
}

- (void)updateConsent {
    NSArray<NSDictionary *> *mappings = [self mappingForKey: @"consentMapping"];
    NSDictionary<NSString *, NSString *> *mappingsConfig;
    if (mappings != nil) {
        mappingsConfig = [self convertToKeyValuePairs: mappings];
    }
    
    BOOL isUserSubjectToGDPR = NO;

    NSString *gdprValue = _configuration[@"gdprApplies"];
    if ([gdprValue isKindOfClass:[NSString class]]) {
        isUserSubjectToGDPR = [gdprValue boolValue];
    }

    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    NSDictionary<NSString *, MPGDPRConsent *> *gdprConsents = currentUser.consentState.gdprConsentState;

    if (gdprConsents.count > 0) {
        isUserSubjectToGDPR = YES;
    }
    
    NSNumber *dataUsage = [self resolvedConsentForMappingKey:kMPAFAdUserDataKey
                                                  defaultKey:kMPAFDefaultAdUserDataKey
                                                gdprConsents:gdprConsents
                                                     mapping:mappingsConfig];

    NSNumber *personalization = [self resolvedConsentForMappingKey:kMPAFAdPersonalizationKey
                                                        defaultKey:kMPAFDefaultAdPersonalizationKey
                                                      gdprConsents:gdprConsents
                                                           mapping:mappingsConfig];

    NSNumber *storage = [self resolvedConsentForMappingKey:kMPAFAdStorageKey
                                                defaultKey:kMPAFDefaultAdStorageKey
                                              gdprConsents:gdprConsents
                                                   mapping:mappingsConfig];


    AppsFlyerConsent *consentObj = [[AppsFlyerConsent alloc]
        initWithIsUserSubjectToGDPR:@(isUserSubjectToGDPR)
        hasConsentForDataUsage:isUserSubjectToGDPR ? dataUsage : nil
        hasConsentForAdsPersonalization:isUserSubjectToGDPR ? personalization : nil
        hasConsentForAdStorage:isUserSubjectToGDPR ? storage : nil];

    // Update consent state with AppsFlyer
    [appsFlyerTracker setConsentData:consentObj];
}

#pragma helper methods

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

- (FilteredMParticleUser *)currentUser {
    return [[self kitApi] getCurrentUserWithKit:self];
}

@end
