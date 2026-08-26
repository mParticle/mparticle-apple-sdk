//
//  MPIdentityDTO.m
//

#import "MPIdentityDTO.h"
#import "mParticle.h"
#import "MPNotificationController.h"
#import "MPPersistenceController.h"
#import "MPConsumerInfo.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@interface MPIdentityHTTPIdentities ()
@property (nonatomic, strong) MPIdentityHTTPIdentitiesPRIVATE *implementation;
@end

@interface MPIdentityHTTPIdentityChange ()
@property (nonatomic, strong) MPIdentityHTTPIdentityChangePRIVATE *implementation;
@end

static NSString *MPIdentityEnvironmentString(void) {
    return [MParticle sharedInstance].environment == MPEnvironmentProduction ? @"production" : @"development";
}

@implementation MPIdentityHTTPBaseRequest

- (NSDictionary *)dictionaryRepresentation {
    return [MPIdentityHTTPRequestBuilderPRIVATE baseDictionaryWithSdkVersion:kMParticleSDKVersion
                                                                 environment:MPIdentityEnvironmentString()];
}

@end

@implementation MPIdentifyHTTPRequest

- (instancetype)initWithIdentityApiRequest:(MPIdentityApiRequest *)apiRequest {
    self = [super init];
    if (self) {
        _knownIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:apiRequest.identities];

        NSNumber *mpid = [MPPersistenceController_PRIVATE mpId];
        if (mpid.longLongValue != 0) {
            _previousMPID = mpid.stringValue;
        }
        MParticle *mparticle = MParticle.sharedInstance;
        MPLog *logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
        logger.customLogger = mparticle.customLogger;
        MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
        MPDevice *device = [[MPDevice alloc] initWithStateMachine:(id<MPStateMachineMPDeviceProtocol>)mparticle.stateMachine
                                                     userDefaults:(id<MPIdentityApiMPUserDefaultsProtocol>)userDefaults
                                                         identity:(id<MPIdentityApiMPDeviceProtocol>)mparticle.identity
                                                           logger:logger];

        NSString *vendorId = device.vendorId;
        if (vendorId) {
            _knownIdentities.vendorId = vendorId;
        }

        NSString *deviceApplicationStamp = [MParticle sharedInstance].stateMachine.consumerInfo.deviceApplicationStamp;
        if (deviceApplicationStamp) {
            _knownIdentities.deviceApplicationStamp = deviceApplicationStamp;
        }

#if TARGET_OS_IOS == 1
        if (![MPStateMachine_PRIVATE isAppExtension]) {
            MPNotificationController_PRIVATE *notificationController = [[MPNotificationController_PRIVATE alloc] init];
            NSData *deviceTokenData = [notificationController deviceToken];
            if (deviceTokenData) {
                NSString *deviceTokenString = [MPUserDefaults stringFromDeviceToken:deviceTokenData];
                if (deviceTokenString && [deviceTokenString length] > 0) {
                    _knownIdentities.pushToken = deviceTokenString;
                }
            }
        }
#endif
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    return [MPIdentityHTTPRequestBuilderPRIVATE identifyDictionaryWithSdkVersion:kMParticleSDKVersion
                                                                     environment:MPIdentityEnvironmentString()
                                                                    previousMPID:_previousMPID
                                                                      identities:[_knownIdentities dictionaryRepresentation]];
}

@end

@implementation MPIdentityHTTPClientSDK

+ (NSDictionary *)clientSDKDictionaryWithVersion:(NSString *)sdkVersion {
    return [MPIdentityHTTPRequestBuilderPRIVATE clientSDKDictionaryWithVersion:sdkVersion];
}

@end

@implementation MPIdentityHTTPModifyRequest

- (instancetype)initWithIdentityChanges:(NSArray *)identityChanges {
    self = [super init];
    if (self) {
        _identityChanges = identityChanges;
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableArray *identityChanges = [NSMutableArray array];
    [_identityChanges enumerateObjectsUsingBlock:^(MPIdentityHTTPIdentityChange *_Nonnull obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *changeDictionary = [obj dictionaryRepresentation];
        [identityChanges addObject:changeDictionary];
    }];
    return [MPIdentityHTTPRequestBuilderPRIVATE modifyDictionaryWithSdkVersion:kMParticleSDKVersion
                                                                   environment:MPIdentityEnvironmentString()
                                                               identityChanges:identityChanges];
}

@end

@implementation MPIdentityHTTPAliasRequest

- (id)initWithIdentityApiAliasRequest:(MPAliasRequest *)aliasRequest {
    if (self = [super init]) {
        _sourceMPID = aliasRequest.sourceMPID;
        _destinationMPID = aliasRequest.destinationMPID;
        _startTime = aliasRequest.startTime;
        _endTime = aliasRequest.endTime;
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    return [MPIdentityHTTPRequestBuilderPRIVATE aliasDictionaryWithSdkVersion:kMParticleSDKVersion
                                                                  environment:MPIdentityEnvironmentString()
                                                                       apiKey:MParticle.sharedInstance.stateMachine.apiKey
                                                                   sourceMPID:_sourceMPID
                                                              destinationMPID:_destinationMPID
                                                                    startTime:_startTime
                                                                      endTime:_endTime
                                                       deviceApplicationStamp:[MParticle sharedInstance].stateMachine.consumerInfo.deviceApplicationStamp];
}

@end

@implementation MPIdentityHTTPIdentities

- (instancetype)init {
    self = [super init];
    if (self) {
        _implementation = [[MPIdentityHTTPIdentitiesPRIVATE alloc] init];
    }
    return self;
}

- (instancetype)initWithIdentities:(NSDictionary *)identities {
    self = [super init];
    if (self) {
        _implementation = [[MPIdentityHTTPIdentitiesPRIVATE alloc] initWithIdentities:identities
                                                               attAuthorizationStatus:[MParticle sharedInstance].stateMachine.attAuthorizationStatus];
    }
    return self;
}

- (NSString *)advertiserId { return self.implementation.advertiserId; }
- (void)setAdvertiserId:(NSString *)advertiserId { self.implementation.advertiserId = advertiserId; }
- (NSString *)vendorId { return self.implementation.vendorId; }
- (void)setVendorId:(NSString *)vendorId { self.implementation.vendorId = vendorId; }
- (NSString *)deviceApplicationStamp { return self.implementation.deviceApplicationStamp; }
- (void)setDeviceApplicationStamp:(NSString *)deviceApplicationStamp { self.implementation.deviceApplicationStamp = deviceApplicationStamp; }
- (NSString *)pushToken { return self.implementation.pushToken; }
- (void)setPushToken:(NSString *)pushToken { self.implementation.pushToken = pushToken; }
- (NSString *)customerId { return self.implementation.customerId; }
- (void)setCustomerId:(NSString *)customerId { self.implementation.customerId = customerId; }
- (NSString *)email { return self.implementation.email; }
- (void)setEmail:(NSString *)email { self.implementation.email = email; }
- (NSString *)facebook { return self.implementation.facebook; }
- (void)setFacebook:(NSString *)facebook { self.implementation.facebook = facebook; }
- (NSString *)facebookCustomAudienceId { return self.implementation.facebookCustomAudienceId; }
- (void)setFacebookCustomAudienceId:(NSString *)facebookCustomAudienceId { self.implementation.facebookCustomAudienceId = facebookCustomAudienceId; }
- (NSString *)google { return self.implementation.google; }
- (void)setGoogle:(NSString *)google { self.implementation.google = google; }
- (NSString *)microsoft { return self.implementation.microsoft; }
- (void)setMicrosoft:(NSString *)microsoft { self.implementation.microsoft = microsoft; }
- (NSString *)other { return self.implementation.other; }
- (void)setOther:(NSString *)other { self.implementation.other = other; }
- (NSString *)twitter { return self.implementation.twitter; }
- (void)setTwitter:(NSString *)twitter { self.implementation.twitter = twitter; }
- (NSString *)yahoo { return self.implementation.yahoo; }
- (void)setYahoo:(NSString *)yahoo { self.implementation.yahoo = yahoo; }
- (NSString *)other2 { return self.implementation.other2; }
- (void)setOther2:(NSString *)other2 { self.implementation.other2 = other2; }
- (NSString *)other3 { return self.implementation.other3; }
- (void)setOther3:(NSString *)other3 { self.implementation.other3 = other3; }
- (NSString *)other4 { return self.implementation.other4; }
- (void)setOther4:(NSString *)other4 { self.implementation.other4 = other4; }
- (NSString *)other5 { return self.implementation.other5; }
- (void)setOther5:(NSString *)other5 { self.implementation.other5 = other5; }
- (NSString *)other6 { return self.implementation.other6; }
- (void)setOther6:(NSString *)other6 { self.implementation.other6 = other6; }
- (NSString *)other7 { return self.implementation.other7; }
- (void)setOther7:(NSString *)other7 { self.implementation.other7 = other7; }
- (NSString *)other8 { return self.implementation.other8; }
- (void)setOther8:(NSString *)other8 { self.implementation.other8 = other8; }
- (NSString *)other9 { return self.implementation.other9; }
- (void)setOther9:(NSString *)other9 { self.implementation.other9 = other9; }
- (NSString *)other10 { return self.implementation.other10; }
- (void)setOther10:(NSString *)other10 { self.implementation.other10 = other10; }
- (NSString *)mobileNumber { return self.implementation.mobileNumber; }
- (void)setMobileNumber:(NSString *)mobileNumber { self.implementation.mobileNumber = mobileNumber; }
- (NSString *)phoneNumber2 { return self.implementation.phoneNumber2; }
- (void)setPhoneNumber2:(NSString *)phoneNumber2 { self.implementation.phoneNumber2 = phoneNumber2; }
- (NSString *)phoneNumber3 { return self.implementation.phoneNumber3; }
- (void)setPhoneNumber3:(NSString *)phoneNumber3 { self.implementation.phoneNumber3 = phoneNumber3; }

- (NSDictionary *)dictionaryRepresentation {
    return [self.implementation dictionaryRepresentation];
}

+ (NSString *)stringForIdentityType:(MPIdentity)identityType {
    return [MPIdentityHTTPIdentitiesPRIVATE stringForIdentityType:(NSInteger)identityType];
}

+ (NSNumber *)identityTypeForString:(NSString *)identityString {
    return [MPIdentityHTTPIdentitiesPRIVATE identityTypeForString:identityString];
}

@end

@implementation MPIdentityHTTPIdentityChange

- (instancetype)initWithOldValue:(NSString *)oldValue value:(NSString *)value identityType:(NSString *)identityType {
    self = [super init];
    if (self) {
        _implementation = [[MPIdentityHTTPIdentityChangePRIVATE alloc] initWithOldValue:oldValue value:value identityType:identityType];
    }
    return self;
}

- (NSString *)oldValue { return self.implementation.oldValue; }
- (void)setOldValue:(NSString *)oldValue { self.implementation.oldValue = oldValue; }
- (NSString *)value { return self.implementation.value; }
- (void)setValue:(NSString *)value { self.implementation.value = value; }
- (NSString *)identityType { return self.implementation.identityType; }
- (void)setIdentityType:(NSString *)identityType { self.implementation.identityType = identityType; }

- (NSMutableDictionary *)dictionaryRepresentation {
    return [self.implementation dictionaryRepresentation];
}

@end

@implementation MPIdentityHTTPSuccessResponse

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSDictionary *fields = [MPIdentityHTTPRequestBuilderPRIVATE successFieldsFrom:dictionary];
        _context = fields[@"context"];
        _mpid = fields[@"mpid"];
        _isEphemeral = [fields[@"is_ephemeral"] boolValue];
        _isLoggedIn = [fields[@"is_logged_in"] boolValue];
    }
    return self;
}

@end

@implementation MPIdentityHTTPBaseSuccessResponse

@end

@implementation MPIdentityHTTPModifySuccessResponse

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary {
    self = [super initWithJsonObject:dictionary];
    if (self) {
        NSDictionary *fields = [MPIdentityHTTPRequestBuilderPRIVATE successFieldsFrom:dictionary];
        _changeResults = fields[@"change_results"];
    }
    return self;
}

@end
