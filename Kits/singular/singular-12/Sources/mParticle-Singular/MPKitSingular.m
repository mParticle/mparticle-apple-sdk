#import "MPKitSingular.h"
#import <Singular/Singular.h>
#import <Singular/SingularConfig.h>

NSUInteger MPKitInstanceSingularKitId = 119;

@implementation MPKitSingular

@synthesize kitApi = _kitApi;

#define API_KEY @"apiKey"
#define SECRET_KEY @"secret"
#define DDL_TIMEOUT @"ddlTimeout"
#define TOTAL_PRODUCT_AMOUNT @"Total Product Amount"
#define USER_GENDER_MALE @"m"
#define USER_GENDER_FEMALE @"f"
#define INIT_WITH_NAME @"Singular"
#define KIT_CLASS_NAME @"MPKitSingular"
#define DEFAULT_CURRENCY @"USD"

// Wrapper Consts
#define MPARTICLE_WRAPPER_NAME @"mParticle"
#define MPARTICLE_WRAPPER_VERSION @"1.2.0"


NSString *apiKey;
NSString *secret;
int ddlTimeout = 60;
void (^singularLinkHandler) (SingularLinkParams*);
typedef void (^sdidAccessorHandler)(NSString*);

static bool isSKANEnabled = NO;
static bool isManualMode = NO;
static void(^conversionValueUpdatedCallback)(NSInteger);
static int waitForTrackingAuthorizationWithTimeoutInterval = 0;
static bool isInitialized = NO;
static NSString* customSDID;
static sdidAccessorHandler sdidReceiveHandler;
static sdidAccessorHandler didSetSdidHandler;

static void(^deviceAttributionCallback)(NSDictionary *);
/*
 mParticle will supply a unique kit code for you. Please contact our team
 */
+ (NSNumber *)kitCode {
    return @119;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:INIT_WITH_NAME
                                                           className:KIT_CLASS_NAME];

    [MParticle registerExtension:kitRegister];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {

    [self extractDataFromConfiguration:configuration];

    // If the app key wasn't initialized, error code must be returned to alert mParticle
    if (!apiKey) {
        return [[MPKitExecStatus alloc]
                initWithSDKCode:[[self class] kitCode]
                returnCode:MPKitReturnCodeRequirementsNotMet];
    }

    _configuration = configuration;

    [self start];

    return [[MPKitExecStatus alloc]
            initWithSDKCode:[[self class] kitCode]
            returnCode:MPKitReturnCodeSuccess];
}

- (void)extractDataFromConfiguration:(NSDictionary * _Nonnull)configuration {
    if(configuration[API_KEY] != nil){
        apiKey = configuration[API_KEY];
    }

    if(configuration[SECRET_KEY] != nil){
        secret = configuration[SECRET_KEY];
    }

    if(configuration[DDL_TIMEOUT] != nil){
        ddlTimeout = [configuration[DDL_TIMEOUT] intValue];
        [Singular setDeferredDeepLinkTimeout:ddlTimeout];
    }
}

- (void)start{
    static dispatch_once_t kitPredicate;
    dispatch_once(&kitPredicate, ^{
        /*
         Start your SDK here. The configuration dictionary can be retrieved from self.configuration
         */
        [Singular setWrapperName:MPARTICLE_WRAPPER_NAME andVersion:MPARTICLE_WRAPPER_VERSION];

        singularLinkHandler = ^(SingularLinkParams * params) {
            NSMutableDictionary *linkInfo = [[NSMutableDictionary alloc]init];

            if ([params getDeepLink] != nil) {
                [linkInfo setObject:[params getDeepLink] forKey:SINGULAR_DEEPLINK_KEY];
            }

            if ([params getPassthrough] != nil) {
                [linkInfo setObject:[params getPassthrough] forKey:SINGULAR_PASSTHROUGH_KEY];
            }

            if ([params getUrlParameters] != nil) {
                [linkInfo setObject:[params getUrlParameters] forKey:SINGULAR_QUERY_PARAMS];
            }

            [linkInfo setObject:[NSNumber numberWithBool:[params isDeferred]] forKey:SINGULAR_IS_DEFERRED_KEY];

            MPAttributionResult *attributionResult = [[MPAttributionResult alloc] init];
            attributionResult.linkInfo = linkInfo;

            [self->_kitApi onAttributionCompleteWithResult:attributionResult error:nil];
        };

        SingularConfig* config = [self buildSingularConfig];
        config.launchOptions = self.launchOptions;

        [Singular start:config];

        isInitialized = YES;

        self->_started = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

            [[NSNotificationCenter defaultCenter]
             postNotificationName:mParticleKitDidBecomeActiveNotification
             object:nil
             userInfo:userInfo];
        });
    });
}

/*
 It's not clear what's going on here, but still to scared to change it...
 */
- (id const)providerKitInstance {
    if (![self started]) {
        return nil;
    }
    /*
     If your company SDK instance is available and is applicable (Please return nil if your SDK is based on class methods)
     */
    BOOL kitInstanceAvailable = NO;
    if (kitInstanceAvailable) {
        /* Return an instance of your company's SDK (if applicable) */
        return nil;
    } else {
        return nil;
    }
}

#pragma mark Application
- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [Singular registerDeviceTokenForUninstall:deviceToken];
    return [self execSuccess];
}

/*
 Implement this method if your SDK handles continueUserActivity method from the App Delegate
 */
- (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity
                               restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler {

    SingularConfig* config = [self buildSingularConfig];
    config.userActivity = userActivity;

    [Singular start:config];

    // Returning success to the mParticle Kit
    return [self execSuccess];
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {

    // Checking if the user attribute is age
    if ([key isEqualToString:mParticleUserAttributeAge]) {

        // Trying to parse and set the age
        @try {
            NSInteger age = [value integerValue];
            [Singular setAge:[NSString stringWithFormat:@"%ld",(long)age]];

        } @catch (NSException *exception) {
            NSLog(@"mParticle -> Invalid age: %@", value);
            return [[MPKitExecStatus alloc]
                    initWithSDKCode:@(MPKitInstanceSingularKitId)
                    returnCode:MPKitReturnCodeFail];;
        }
    } else if ([key isEqualToString:mParticleUserAttributeGender]) {
        [Singular setGender:mParticleGenderMale ? USER_GENDER_MALE : USER_GENDER_FEMALE];
    }

    // Returning success to the mParticle Kit
    return [self execSuccess];
}

#pragma mark e-Commerce

/*
 This method is called when the user has purchased something
 */
- (MPKitExecStatus *)singularCommerceEvent:(MPCommerceEvent *)commerceEvent {

    MPKitExecStatus *execStatus = [self execSuccess];

    if (commerceEvent.action == MPCommerceEventActionPurchase){
        [self handleRevenueEvents:commerceEvent execStatus:execStatus];
    }else{
        [self handleEvents:commerceEvent execStatus:execStatus];
    }

    return execStatus;
}

- (void)handleEvents:(MPCommerceEvent * _Nonnull)commerceEvent
          execStatus:(MPKitExecStatus *)execStatus {

    for (MPCommerceEventInstruction *commerceEventInstruction in [commerceEvent expandedInstructions]) {
        [self logBaseEvent:commerceEventInstruction.event];
        [execStatus incrementForwardCount];
    }
}

- (void)handleRevenueEvents:(MPCommerceEvent * _Nonnull)commerceEvent
                 execStatus:(MPKitExecStatus *)execStatus {

    NSMutableDictionary *productAttributes = [[NSMutableDictionary alloc] init];
    NSDictionary *transactionAttributes = [commerceEvent.transactionAttributes beautifiedDictionaryRepresentation];

    if (transactionAttributes) {
        [productAttributes addEntriesFromDictionary:transactionAttributes];
    }

    NSDictionary *commerceEventAttributes = [commerceEvent beautifiedAttributes];
    NSArray *keys = @[kMPExpCECheckoutOptions,
                      kMPExpCECheckoutStep,
                      kMPExpCEProductListName,
                      kMPExpCEProductListSource];

    for (NSString *key in keys) {
        if (commerceEventAttributes[key]) {
            productAttributes[key] = commerceEventAttributes[key];
        }
    }

    for (MPProduct *product in commerceEvent.products) {

        // Sending a revenue event for each of the products that was purchased
        [self sendRevenueEvent:productAttributes
                      currency:commerceEvent.currency ? : DEFAULT_CURRENCY
                    execStatus:execStatus
                          keys:&keys
                       product:product];
    }
}

- (void)sendRevenueEvent:(NSMutableDictionary *)productAttributes
                currency:(NSString *)currency
              execStatus:(MPKitExecStatus *)execStatus
                    keys:(NSArray **)keys
                 product:(MPProduct *)product {

    // Add relevant attributes from the commerce event
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    if (productAttributes.count > 0) {
        [properties addEntriesFromDictionary:productAttributes];
    }

    // Add attributes from the product itself
    NSDictionary *productDictionary = [product beautifiedDictionaryRepresentation];
    if (productDictionary) {
        [properties addEntriesFromDictionary:productDictionary];
    }

    // Strips key/values already being passed to Appboy, plus key/values initialized to default values
    *keys = @[kMPExpProductSKU,
              kMPProductCurrency,
              kMPExpProductUnitPrice,
              kMPExpProductQuantity,
              kMPProductAffiliation,
              kMPExpProductCategory,
              kMPExpProductName];

    [properties removeObjectsForKeys:*keys];

    //get the amount
    NSNumber *totalProductAmount = nil;
    if(properties != nil && [properties valueForKey:TOTAL_PRODUCT_AMOUNT]){
        totalProductAmount = [properties valueForKey:TOTAL_PRODUCT_AMOUNT];
    }

    // Sending the event
    [Singular revenue:currency
               amount:[totalProductAmount doubleValue]
           productSKU:product.sku
          productName:product.name
      productCategory:product.category
      productQuantity:[product.quantity intValue]
         productPrice:[product.price doubleValue]];

    [execStatus incrementForwardCount];
}

- (nonnull MPKitExecStatus *)setConsentState:(nullable MPConsentState *)state{
    if (state && [state ccpaConsentState]){
        [Singular limitDataSharing:[[state ccpaConsentState] consented]];
    }

    return [self execSuccess];
}

#pragma mark Events
/*
 This method is called when an event is fired
 */

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self singularEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        return [self singularCommerceEvent:(MPCommerceEvent *)event];
    } else {
        return [[MPKitExecStatus alloc]
                initWithSDKCode:[[self class] kitCode]
                returnCode:MPKitReturnCodeUnavailable];;
    }
}

- (MPKitExecStatus *)singularEvent:(MPEvent *)event {
    if (event.customAttributes.count > 0) {
        [Singular event:event.name withArgs:event.customAttributes];
    } else {
        [Singular event:event.name];
    }

    return [self execSuccess];
}

- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url
                   sourceApplication:(nullable NSString *)sourceApplication
                          annotation:(nullable id)annotation {
    [self handleOpenURLEvent:url];

    return [[MPKitExecStatus alloc]
            initWithSDKCode:@(MPKitInstanceBranchMetrics)
            returnCode:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url
                             options:(nullable NSDictionary<NSString *, id> *)options {
    [self handleOpenURLEvent:url];
    return [self execSuccess];
}

- (nonnull MPKitExecStatus *) execSuccess{
    return [[MPKitExecStatus alloc]
            initWithSDKCode:@(MPKitInstanceSingularKitId)
            returnCode:MPKitReturnCodeSuccess];
}

- (void) handleOpenURLEvent:(nonnull NSURL *)url{
    if(url){
        SingularConfig* config = [self buildSingularConfig];
        config.openUrl = url;

        [Singular start:config];
    }
}

- (SingularConfig*)buildSingularConfig {
    SingularConfig* config = [[SingularConfig alloc] initWithApiKey:apiKey andSecret:secret];

    config.singularLinksHandler = singularLinkHandler;

    config.customSdid = customSDID;
    config.sdidReceivedHandler = sdidReceiveHandler;
    config.didSetSdidHandler = didSetSdidHandler;

    config.deviceAttributionCallback = deviceAttributionCallback;

    config.skAdNetworkEnabled = isSKANEnabled;
    config.manualSkanConversionManagement = isManualMode;
    config.conversionValueUpdatedCallback = conversionValueUpdatedCallback;
    config.waitForTrackingAuthorizationWithTimeoutInterval = waitForTrackingAuthorizationWithTimeoutInterval;

    return config;
}

+ (void)setSKANOptions:(BOOL)skAdNetworkEnabled isManualSkanConversionManagementMode:(BOOL)manualMode withWaitForTrackingAuthorizationWithTimeoutInterval:(NSNumber* _Nullable)waitTrackingAuthorizationWithTimeoutInterval withConversionValueUpdatedHandler:(void(^_Nullable)(NSInteger))conversionValueUpdatedHandler {
    if (isInitialized) {
        NSLog(@"Singular Warning: setSKANOptions should be called before init");
    }

    isSKANEnabled = skAdNetworkEnabled;
    isManualMode = manualMode;
    conversionValueUpdatedCallback = conversionValueUpdatedHandler;
    waitForTrackingAuthorizationWithTimeoutInterval = waitTrackingAuthorizationWithTimeoutInterval ? [waitTrackingAuthorizationWithTimeoutInterval intValue] : 0;
}

+ (void)setCustomSDID:(NSString *)customSdid sdidReceivedHandler:(void(^_Nullable)(NSString *))sdidReceivedHandler didSetSdidHandler:(void(^_Nullable)(NSString *))setSdidHandler {
    if (isInitialized) {
        NSLog(@"Singular Warning: setCustomSDID should be called before init");
    }

    customSDID = customSdid;
    sdidReceiveHandler = sdidReceivedHandler;
    didSetSdidHandler = setSdidHandler;
}

+ (void)setDeviceAttributionCallback:(void(^_Nullable)(NSDictionary*))deviceAttributionHandler {
    if (isInitialized) {
        NSLog(@"Singular Warning: setDeviceAttributionHandler should be called before init");
    }

    deviceAttributionCallback = deviceAttributionHandler;
}

@end
