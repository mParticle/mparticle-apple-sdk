#import "MPKitUrbanAirship.h"
#if SWIFT_PACKAGE
    @import AirshipCore;
    @import AirshipObjectiveC;
#else
    #if __has_include("AirshipLib.h")
        #import "AirshipLib.h"
    #elif __has_include(<AirshipKit/AirshipKit.h>)
        @import AirshipKit;
    #else
        @import AirshipObjectiveC;
    #endif
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#import <UserNotifications/UNUserNotificationCenter.h>
#endif

NSString * const UAIdentityEmail = @"email";
NSString * const UAIdentityFacebook = @"facebook_id";
NSString * const UAIdentityTwitter = @"twitter_id";
NSString * const UAIdentityGoogle = @"google_id";
NSString * const UAIdentityMicrosoft = @"microsoft_id";
NSString * const UAIdentityYahoo = @"yahoo_id";
NSString * const UAIdentityFacebookCustomAudienceId = @"facebook_custom_audience_id";
NSString * const UAIdentityCustomer = @"customer_id";

NSString * const UAConfigAppKey = @"applicationKey";
NSString * const UAConfigAppSecret = @"applicationSecret";
NSString * const UAConfigCustomDomainProxyUrl = @"customDomainProxyUrl";
NSString * const UAConfigEnableTags = @"enableTags";
NSString * const UAConfigIncludeUserAttributes = @"includeUserAttributes";
NSString * const UAConfigNamedUserId = @"namedUserIdField";

// Possible values for UAConfigNamedUserId
NSString * const UAConfigNamedUserIdEmail = @"email";
NSString * const UAConfigNamedUserIdCustomerdId = @"customerId";
NSString * const UAConfigNamedUserIdOther = @"other";
NSString * const UAConfigNamedUserIdNone = @"none";

NSString * const UAChannelIdIntegrationKey = @"com.urbanairship.channel_id";

NSString * const kMPUAEventTagKey = @"eventUserTags";
NSString * const kMPUAEventAttributeTagKey = @"eventAttributeUserTags";
NSString * const kMPUAMapTypeEventClass = @"EventClass.Id";
NSString * const kMPUAMapTypeEventClassDetails = @"EventClassDetails.Id";
NSString * const kMPUAMapTypeEventAttributeClass = @"EventAttributeClass.Id";
NSString * const kMPUAMapTypeEventAttributeClassDetails = @"EventAttributeClassDetails.Id";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#pragma mark - MPUATagMapping
@interface MPUATagMapping : NSObject

@property (nonatomic, strong, readonly) NSString *mapType;
@property (nonatomic, strong, readonly) NSString *value;
@property (nonatomic, strong, readonly) NSString *mapHash;

- (instancetype)initWithConfiguration:(NSDictionary<NSString *, NSString *> *)configuration;

@end

@implementation MPUATagMapping

- (instancetype)initWithConfiguration:(NSDictionary<NSString *, NSString *> *)configuration {
    self = [super init];
    if (self) {
        _mapType = configuration[@"maptype"];
        _value = configuration[@"value"];
        _mapHash = configuration[@"map"];
    }
    
    if (!_mapType || (NSNull *)_mapType == [NSNull null] ||
        !_value || (NSNull *)_value == [NSNull null] ||
        !_mapHash || (NSNull *)_mapHash == [NSNull null])
    {
        return nil;
    } else {
        return self;
    }
}

@end


#pragma mark - MPKitUrbanAirship
@interface MPKitUrbanAirship()

@property (nonatomic, strong) NSMutableArray<MPUATagMapping *> *eventTagsMapping;
@property (nonatomic, strong) NSMutableArray<MPUATagMapping *> *eventAttributeTagsMapping;
@property (nonatomic, unsafe_unretained) BOOL enableTags;
@property (nonatomic, unsafe_unretained) BOOL includeUserAttributes;

@end


@implementation MPKitUrbanAirship

+ (NSNumber *)kitCode {
    return @25;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Urban Airship"
                                                           className:@"MPKitUrbanAirship"];
    [MParticle registerExtension:kitRegister];
}

+ (NSSet *)defaultCategories {
    return [UANotificationCategories defaultCategories];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;
    
    self.configuration = configuration;
    
    NSString *auxString = configuration[UAConfigEnableTags];
    _enableTags = auxString ? [auxString boolValue] : NO;
    
    auxString = configuration[UAConfigIncludeUserAttributes];
    _includeUserAttributes = auxString ? [auxString boolValue] : NO;
    
    [self start];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)start {
    static dispatch_once_t kitPredicate;
    
    dispatch_once(&kitPredicate, ^{
        self->_started = YES;
        
        NSError *error = nil;
        UAConfig *config = [UAConfig config];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *pListPath = @"AirshipConfig.plist";
        if ([fileManager fileExistsAtPath:pListPath]) {
            config = [UAConfig fromPlistWithContentsOfFile:pListPath error:&error];
            if (error) {
                NSLog(@"Airship config failed to initialize based off AirshipConfig.plist: %@", error);
                NSLog(@"mParticle will attempt to manually construct UA Config based off your Connection Settings");
                config = [UAConfig config];
            }
        }
        
        config.isAutomaticSetupEnabled = NO;
        
        // Enable passive APNS registration
        config.requestAuthorizationToUseNotifications = NO;

        // Enable custom domain proxy if provided
        if (self.configuration[UAConfigCustomDomainProxyUrl]) {
            config.initialConfigURL = self.configuration[UAConfigCustomDomainProxyUrl];
            config.URLAllowList = [config.URLAllowList arrayByAddingObject:self.configuration[UAConfigCustomDomainProxyUrl]];
        }
        
        if ([MParticle sharedInstance].environment == MPEnvironmentDevelopment) {
            config.developmentAppKey = self.configuration[UAConfigAppKey];
            config.developmentAppSecret = self.configuration[UAConfigAppSecret];
            config.inProduction = @NO;
        } else {
            config.productionAppKey = self.configuration[UAConfigAppKey];
            config.productionAppSecret = self.configuration[UAConfigAppSecret];
            config.inProduction = @YES;
        }
        
        [UAirship takeOff:config launchOptions:_launchOptions error:&error];
        if (error) {
            NSLog(@"Airship.takeOff failed: %@", error);
        }
        
        UAirship.push.userPushNotificationsEnabled = YES;
        
        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter postNotificationName:mParticleKitDidBecomeActiveNotification
                                          object:nil
                                        userInfo:userInfo];
        
        [notificationCenter addObserver:self
                               selector:@selector(updateChannelIntegration)
                                   name:@"com.urbanairship.channel.channel_created" // https://github.com/mparticle-integrations/mparticle-apple-integration-urbanairship/pull/31#discussion_r2003658925
                                 object:nil];
        
        [self updateChannelIntegration];
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id const)providerKitInstance {
    // Urban Airship no longer provides a shared instance. Instead their API's now all work as class methods on UAirship
    return nil;
}

- (void)setConfiguration:(NSDictionary *)configuration {
    _configuration = configuration;
    
    // Configure event tags mapping
    
    NSString *tagMappingStr;
    NSData *tagMappingData;
    
    if (configuration && configuration[kMPUAEventTagKey] != [NSNull null]) {
        tagMappingStr = [configuration[kMPUAEventAttributeTagKey] stringByRemovingPercentEncoding];
        tagMappingData = [tagMappingStr dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSError *error = nil;
    NSArray<NSDictionary<NSString *, NSString *> *> *tagMappingConfig = nil;
    
    @try {
        tagMappingConfig = [NSJSONSerialization JSONObjectWithData:tagMappingData options:kNilOptions error:&error];
    } @catch (NSException *exception) {
    }
    
    if (tagMappingConfig && !error) {
        [self configureEventTagsMapping:tagMappingConfig];
    }
    
    // Configure event attribute tags mapping
    if (configuration && configuration[kMPUAEventAttributeTagKey] != [NSNull null]) {
        tagMappingStr = [configuration[kMPUAEventAttributeTagKey] stringByRemovingPercentEncoding];
        tagMappingData = [tagMappingStr dataUsingEncoding:NSUTF8StringEncoding];
    }
    error = nil;
    tagMappingConfig = nil;
    
    @try {
        tagMappingConfig = [NSJSONSerialization JSONObjectWithData:tagMappingData options:kNilOptions error:&error];
    } @catch (NSException *exception) {
    }
    
    if (tagMappingConfig && !error) {
        [self configureEventAttributeTagsMapping:tagMappingConfig];
    }
}

- (NSMutableArray<MPUATagMapping *> *)eventTagsMapping {
    if (!_eventTagsMapping) {
        _eventTagsMapping = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    return _eventTagsMapping;
}

- (NSMutableArray<MPUATagMapping *> *)eventAttributeTagsMapping {
    if (!_eventAttributeTagsMapping) {
        _eventAttributeTagsMapping = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    return _eventAttributeTagsMapping;
}

#pragma mark e-Commerce

- (MPKitExecStatus *)routeCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                                                returnCode:MPKitReturnCodeSuccess forwardCount:0];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventClassDetails];
    NSArray<MPUATagMapping *> *eventTagMappings = [self.eventTagsMapping filteredArrayUsingPredicate:predicate];
    
    predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventAttributeClassDetails];
    NSArray<MPUATagMapping *> *eventAttributeTagMappings = [self.eventAttributeTagsMapping filteredArrayUsingPredicate:predicate];
    
    if ([self logAirshipRetailEventFromCommerceEvent:commerceEvent]) {
        [self setTagMappings:eventTagMappings forCommerceEvent:commerceEvent];
        [self setTagMappings:eventAttributeTagMappings forAttributesInCommerceEvent:commerceEvent];
        
        [execStatus incrementForwardCount];
    } else {
        for (MPCommerceEventInstruction *commerceEventInstruction in [commerceEvent expandedInstructions]) {
            [self logUrbanAirshipEvent:commerceEventInstruction.event];
            
            NSNumber *eventType = @(commerceEventInstruction.event.type);
            [self setTagMappings:eventTagMappings forEvent:commerceEventInstruction.event eventType:eventType];
            [self setTagMappings:eventAttributeTagMappings forAttributesInEvent:commerceEventInstruction.event eventType:eventType];
            
            [execStatus incrementForwardCount];
        }
    }
    
    return execStatus;
}

- (MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(MPEvent *)event {
    UACustomEvent *customEvent = [[UACustomEvent alloc] initWithName:event.name value:increaseAmount];
    
    [customEvent track];
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}


#pragma mark Events

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        return [self routeCommerceEvent:(MPCommerceEvent *)event];
    } else {
        return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode] returnCode:MPKitReturnCodeUnavailable];
    }
}

- (MPKitExecStatus *)routeEvent:(MPEvent *)event {
    [self logUrbanAirshipEvent:event];
    
    // Event class tags
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventClass];
    NSArray<MPUATagMapping *> *tagMappings = [self.eventTagsMapping filteredArrayUsingPredicate:predicate];
    NSNumber *eventType = @(event.type);
    [self setTagMappings:tagMappings forEvent:event eventType:eventType];
    
    // Event attribute class tags
    predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventAttributeClass];
    tagMappings = [self.eventAttributeTagsMapping filteredArrayUsingPredicate:predicate];
    [self setTagMappings:tagMappings forAttributesInEvent:event eventType:eventType];
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    [UAirship.analytics trackScreen:event.name];
    
    // Event class detail tags
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventClassDetails];
    NSArray<MPUATagMapping *> *tagMappings = [self.eventTagsMapping filteredArrayUsingPredicate:predicate];
    NSNumber *eventType = @0; // logScreen does not have a corresponding event type
    [self setTagMappings:tagMappings forEvent:event eventType:eventType];
    
    // Event attribute class detail tags
    predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventAttributeClassDetails];
    tagMappings = [self.eventAttributeTagsMapping filteredArrayUsingPredicate:predicate];
    [self setTagMappings:tagMappings forAttributesInEvent:event eventType:eventType];
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

#pragma mark User attributes and identities
- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    MPKitReturnCode returnCode;
    
    if (_enableTags && _includeUserAttributes) {
        NSString *uaTag = nil;
        
        BOOL keyValid = key && (NSNull *)key != [NSNull null] && ![key isEqualToString:@""];
        BOOL valueValid = value && (NSNull *)value != [NSNull null] && ![value isEqualToString:@""];
        
        if (keyValid && valueValid) {
            uaTag = [NSString stringWithFormat:@"%@-%@", key, value];
        }
        
        if (uaTag) {
            UATagEditor *editor = [UAirship.channel editTags];
            [editor addTag:uaTag];
            [editor apply];
            returnCode = MPKitReturnCodeSuccess;
        } else {
            returnCode = MPKitReturnCodeRequirementsNotMet;
        }
    } else {
        returnCode = MPKitReturnCodeCannotExecute;
    }
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode] returnCode:returnCode];
}

- (MPKitExecStatus *)setUserTag:(NSString *)tag {
    MPKitReturnCode returnCode;
    
    if (_enableTags) {
        NSString *uaTag = nil;
        
        if (tag && (NSNull *)tag != [NSNull null] && ![tag isEqualToString:@""]) {
            uaTag = tag;
        }
        
        if (uaTag) {
            UATagEditor *editor = [UAirship.channel editTags];
            [editor addTag:uaTag];
            [editor apply];
            returnCode = MPKitReturnCodeSuccess;
        } else {
            returnCode = MPKitReturnCodeRequirementsNotMet;
        }
    } else {
        returnCode = MPKitReturnCodeCannotExecute;
    }
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode] returnCode:returnCode];
}

- (nonnull MPKitExecStatus *)removeUserAttribute:(nonnull NSString *)key {
    MPKitReturnCode returnCode;
    
    if (_enableTags) {
        NSString *uaTag = nil;
        
        if (key && (NSNull *)key != [NSNull null] && ![key isEqualToString:@""]) {
            uaTag = key;
        }
        
        if (uaTag) {
            UATagEditor *editor = [UAirship.channel editTags];
            [editor removeTag:uaTag];
            [editor apply];
            returnCode = MPKitReturnCodeSuccess;
        } else {
            returnCode = MPKitReturnCodeRequirementsNotMet;
        }
    } else {
        returnCode = MPKitReturnCodeCannotExecute;
    }
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode] returnCode:returnCode];
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    BOOL namedUserSet = [self setNamedUser:identityString identityType:identityType];
    BOOL associatedIdentifierSet = [self setAssociatedIdentifier:identityString identityType:identityType];
    
    if (namedUserSet || associatedIdentifierSet) {
        return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                             returnCode:MPKitReturnCodeSuccess];
    }
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeUnavailable];
}

#pragma mark Assorted

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    if(!optOut) {
        UAirship.privacyManager.enabledFeatures = UAFeature.all;
    } else {
        UAirship.privacyManager.enabledFeatures = UAFeature.none;
    }
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

#pragma mark Helpers



/**
 * Sets the named user.
 * @param identityString The identifier.
 * @param identityType The mParticle identifier type.
 * @return `YES` if the named user was set, otherwise `NO`.
 */
- (BOOL)setNamedUser:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    NSString *namedUserConfig = self.configuration[UAConfigNamedUserId];
    if (!namedUserConfig || [namedUserConfig isEqualToString:UAConfigNamedUserIdNone]) {
        return NO;
    }
    
    MPUserIdentity mappedType;
    if ([namedUserConfig isEqualToString:UAConfigNamedUserIdEmail]) {
        mappedType = MPUserIdentityEmail;
    } else if ([namedUserConfig isEqualToString:UAConfigNamedUserIdOther]) {
        mappedType = MPUserIdentityOther;
    } else if ([namedUserConfig isEqualToString:UAConfigNamedUserIdCustomerdId]) {
        mappedType = MPUserIdentityCustomerId;;
    } else {
        return NO;
    }
    
    if (mappedType != identityType) {
        return NO;
    }
    
    [UAirship.contact identify:identityString];
    return YES;
}

/**
 * Sets the associated identifier.
 * @param identityString The identifier.
 * @param identityType The mParticle identifier type.
 * @return `YES` if the identifier was set, otherwise `NO`.
 */
- (BOOL)setAssociatedIdentifier:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    NSString *key;
    switch (identityType) {
        case MPUserIdentityCustomerId:
            key = UAIdentityCustomer;
            break;
            
        case MPUserIdentityFacebook:
            key = UAIdentityFacebook;
            break;
            
        case MPUserIdentityTwitter:
            key = UAIdentityTwitter;
            break;
            
        case MPUserIdentityGoogle:
            key = UAIdentityGoogle;
            break;
            
        case MPUserIdentityMicrosoft:
            key = UAIdentityMicrosoft;
            break;
            
        case MPUserIdentityYahoo:
            key = UAIdentityYahoo;
            break;
            
        case MPUserIdentityEmail:
            key = UAIdentityEmail;
            break;
            
        case MPUserIdentityFacebookCustomAudienceId:
            key = UAIdentityFacebookCustomAudienceId;
            break;
            
        default:
            return false;
    }
    
    UAAssociatedIdentifiers *identifiers = [UAirship.analytics currentAssociatedDeviceIdentifiers];
    [identifiers setWithIdentifier:identityString key:key];
    [UAirship.analytics associateDeviceIdentifier:identifiers];
    
    return YES;
}

- (void)logUrbanAirshipEvent:(MPEvent *)event {
    UACustomEvent *customEvent = [[UACustomEvent alloc] initWithName:event.name];
    NSError *error = nil;
    [customEvent setProperties:event.customAttributes error:&error];
    if (error) {
        NSLog(@"Failed to set properties: %@\non Event: %@\n failed: %@", event.customAttributes, event.name, error);
    }
    
    [customEvent track];
}

- (BOOL)logAirshipRetailEventFromCommerceEvent:(MPCommerceEvent *)commerceEvent {
    if (commerceEvent.products < 0) {
        return NO;
    }
    
    switch (commerceEvent.action) {
        case MPCommerceEventActionPurchase:
            
            for (id product in commerceEvent.products) {
                UACustomEventRetailTemplate *template = [UACustomEventRetailTemplate purchased];
                UACustomEvent *customEvent = [self populateRetailEventTemplate:template commerceEvent:commerceEvent product:product];
                
                NSString *transactionId = commerceEvent.transactionAttributes.transactionId;
                customEvent.transactionID = transactionId;
                
                [customEvent track];
            }
            
            return YES;
            
        case MPCommerceEventActionAddToCart:
            
            for (id product in commerceEvent.products) {
                UACustomEventRetailTemplate *template = [UACustomEventRetailTemplate addedToCart];
                UACustomEvent *customEvent = [self populateRetailEventTemplate:template commerceEvent:commerceEvent product:product];

                [customEvent track];
            }
            
            return YES;
            
        case MPCommerceEventActionClick:
            
            for (id product in commerceEvent.products) {
                UACustomEventRetailTemplate *template = [UACustomEventRetailTemplate browsed];
                UACustomEvent *customEvent = [self populateRetailEventTemplate:template commerceEvent:commerceEvent product:product];

                [customEvent track];
            }
            
            return YES;
            
        case MPCommerceEventActionAddToWishList:
            
            for (id product in commerceEvent.products) {
                UACustomEventRetailTemplate *template = [UACustomEventRetailTemplate starred];
                UACustomEvent *customEvent = [self populateRetailEventTemplate:template commerceEvent:commerceEvent product:product];
                [customEvent track];
            }
            
            return YES;
            
        default:
            return NO;
    }
}

- (UACustomEvent *)populateRetailEventTemplate:(UACustomEventRetailTemplate *)template
                      commerceEvent:(MPCommerceEvent *)commerceEvent
                            product:(MPProduct *)product {
    UACustomEventRetailProperties *properties = [[UACustomEventRetailProperties alloc] initWithId:product.sku category:product.category type:nil eventDescription:product.name isLTV:nil brand:product.brand isNewItem:nil currency:nil];
    
    UACustomEvent *customEvent = [[UACustomEvent alloc] initWithRetailTemplate:template properties:properties];

    NSDecimal eventValue;
    if (product.price == nil) {
        eventValue = [NSDecimalNumber zero].decimalValue;
    } else if (product.quantity == nil) {
        eventValue = [NSDecimalNumber decimalNumberWithDecimal:[product.price decimalValue]].decimalValue;
    } else {
        NSDecimalNumber *decimalPrice = [NSDecimalNumber decimalNumberWithDecimal:[product.price decimalValue]];
        NSDecimalNumber *decimalQuantity = [NSDecimalNumber decimalNumberWithDecimal:[product.quantity decimalValue]];
        eventValue = [decimalPrice decimalNumberByMultiplyingBy:decimalQuantity].decimalValue;
    }
    customEvent.eventValue = eventValue;
    
    return customEvent;
}

- (void)updateChannelIntegration  {
    NSString *channelID = [UAirship channel].identifier;
    
    if (channelID.length) {
        NSDictionary<NSString *, NSString *> *integrationAttributes = @{UAChannelIdIntegrationKey:channelID};
        [[MParticle sharedInstance] setIntegrationAttributes:integrationAttributes forKit:[[self class] kitCode]];
    }
}

- (void)configureEventTagsMapping:(NSArray<NSDictionary<NSString *, NSString *> *> *)config {
    [config enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPUATagMapping *tagMapping = [[MPUATagMapping alloc] initWithConfiguration:obj];
        
        if (tagMapping) {
            [self.eventTagsMapping addObject:tagMapping];
        }
    }];
}

- (void)configureEventAttributeTagsMapping:(NSArray<NSDictionary<NSString *, NSString *> *> *)config {
    [config enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPUATagMapping *tagMapping = [[MPUATagMapping alloc] initWithConfiguration:obj];
        
        if (tagMapping) {
            [self.eventAttributeTagsMapping addObject:tagMapping];
        }
    }];
}

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

- (void)setTagMappings:(NSArray<MPUATagMapping *> *)tagMappings forCommerceEvent:(MPCommerceEvent *)commerceEvent {
    if (!tagMappings) {
        return;
    }
    
    NSString *stringToHash = [[NSString stringWithFormat:@"%@", [@([commerceEvent type]) stringValue]] lowercaseString];
    NSString *hashedString = [MPKitAPI hashString:stringToHash];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapHash == %@", hashedString];
    NSArray<MPUATagMapping *> *matchTagMappings = [tagMappings filteredArrayUsingPredicate:predicate];
    
    if (matchTagMappings.count > 0) {
        [matchTagMappings enumerateObjectsUsingBlock:^(MPUATagMapping * _Nonnull tagMapping, NSUInteger idx, BOOL * _Nonnull stop) {
            UATagEditor *editor = [UAirship.channel editTags];
            [editor addTag:tagMapping.value];
            [editor apply];
        }];
    }
}

- (void)setTagMappings:(NSArray<MPUATagMapping *> *)tagMappings forEvent:(MPEvent *)event eventType:(NSNumber *)eventType {
    if (!tagMappings) {
        return;
    }
    
    NSString *stringToHash = [[NSString stringWithFormat:@"%@%@", [eventType stringValue], event.name] lowercaseString];
    NSString *hashedString = [MPKitAPI hashString:stringToHash];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapHash == %@", hashedString];
    NSArray<MPUATagMapping *> *matchTagMappings = [tagMappings filteredArrayUsingPredicate:predicate];
    
    if (matchTagMappings.count > 0) {
        [matchTagMappings enumerateObjectsUsingBlock:^(MPUATagMapping * _Nonnull tagMapping, NSUInteger idx, BOOL * _Nonnull stop) {
            UATagEditor *editor = [UAirship.channel editTags];
            [editor addTag:tagMapping.value];
            [editor apply];
        }];
    }
}

- (void)setTagMappings:(NSArray<MPUATagMapping *> *)tagMappings forAttributesInCommerceEvent:(MPCommerceEvent *)commerceEvent {
    if (!tagMappings) {
        return;
    }
    
    NSDictionary *beautifiedAtrributes = [commerceEvent beautifiedAttributes];
    NSDictionary *userDefinedAttributes = [commerceEvent customAttributes];
    NSMutableDictionary<NSString *, id> *commerceEventAttributes = [[NSMutableDictionary alloc] initWithCapacity:(beautifiedAtrributes.count + userDefinedAttributes.count)];
    
    if (beautifiedAtrributes.count > 0) {
        [commerceEventAttributes addEntriesFromDictionary:beautifiedAtrributes];
    }
    
    if (userDefinedAttributes.count > 0) {
        [commerceEventAttributes addEntriesFromDictionary:userDefinedAttributes];
    }
    
    [commerceEventAttributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *stringToHash = [[NSString stringWithFormat:@"%@%@", [@([commerceEvent type]) stringValue], key] lowercaseString];
        NSString *hashedString = [MPKitAPI hashString:stringToHash];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapHash == %@", hashedString];
        NSArray<MPUATagMapping *> *matchTagMappings = [tagMappings filteredArrayUsingPredicate:predicate];
        
        if (matchTagMappings.count > 0) {
            [matchTagMappings enumerateObjectsUsingBlock:^(MPUATagMapping * _Nonnull tagMapping, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *attributeString = [self stringRepresentation:obj];
                
                if (attributeString) {
                    NSString *tagPlusAttributeValue = [NSString stringWithFormat:@"%@-%@", tagMapping.value, attributeString];
                    UATagEditor *editor = [UAirship.channel editTags];
                    [editor addTag:tagPlusAttributeValue];
                    [editor addTag:tagMapping.value];
                    [editor apply];
                }
            }];
        }
    }];
}

- (void)setTagMappings:(NSArray<MPUATagMapping *> *)tagMappings forAttributesInEvent:(MPEvent *)event eventType:(NSNumber *)eventType {
    if (!tagMappings || event.customAttributes.count == 0) {
        return;
    }
    
    NSDictionary<NSString *, id> *eventInfo = event.customAttributes;
    
    [eventInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *stringToHash = [[NSString stringWithFormat:@"%@%@%@", [eventType stringValue], event.name, key] lowercaseString];
        NSString *hashedString = [MPKitAPI hashString:stringToHash];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapHash == %@", hashedString];
        NSArray<MPUATagMapping *> *matchTagMappings = [tagMappings filteredArrayUsingPredicate:predicate];
        
        if (matchTagMappings.count > 0) {
            [matchTagMappings enumerateObjectsUsingBlock:^(MPUATagMapping * _Nonnull tagMapping, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *attributeString = [self stringRepresentation:obj];
                
                if (attributeString) {
                    NSString *tagPlusAttributeValue = [NSString stringWithFormat:@"%@-%@", tagMapping.value, attributeString];
                    UATagEditor *editor = [UAirship.channel editTags];
                    [editor addTag:tagPlusAttributeValue];
                    [editor addTag:tagMapping.value];
                    [editor apply];
                }
            }];
        }
    }];
}

#pragma mark App Delegate Integration

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    // Check for UA identifiers
    if ([userInfo objectForKey:@"_"] || [userInfo objectForKey:@"com.urbanairship.metadata"]) {
        [UAAppIntegration application:[UIApplication sharedApplication] didReceiveRemoteNotification:userInfo
               fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
    }
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [UAAppIntegration application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center willPresentNotification:(nonnull UNNotification *)notification  API_AVAILABLE(ios(10.0)){
    [UAAppIntegration userNotificationCenter:center willPresentNotification:notification withCompletionHandler:^(UNNotificationPresentationOptions options) {}];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response  API_AVAILABLE(ios(10.0)){
    [UAAppIntegration userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:^{}];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

@end

#pragma clang diagnostic pop
