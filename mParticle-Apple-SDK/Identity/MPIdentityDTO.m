//
//  MPIdentityDTO.m
//

#import "MPIdentityDTO.h"
#import "mParticle.h"
#import "MPNotificationController.h"
#import "MPPersistenceController.h"
#import "MPConsumerInfo.h"
#import "mParticleSwift.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@implementation MPIdentityHTTPBaseRequest

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    NSDictionary *clientSDKDictionary = [MPIdentityHTTPClientSDK clientSDKDictionaryWithVersion:kMParticleSDKVersion];
    if (clientSDKDictionary) {
        dictionary[@"client_sdk"] = clientSDKDictionary;
    }
    
    NSString *environment = [MParticle sharedInstance].environment == MPEnvironmentProduction ? @"production" : @"development";
    if (environment) {
        dictionary[@"environment"] = environment;
    }
    
    NSString *requestId = [NSUUID UUID].UUIDString;
    if (requestId) {
        dictionary[@"request_id"] = requestId;
    }
    
    NSNumber *requestTimestamp = @(floor([NSDate date].timeIntervalSince1970*1000));
    if (requestTimestamp != nil) {
        dictionary[@"request_timestamp_ms"] = @(requestTimestamp.longLongValue);
    }
    
    return dictionary;
}

@end

@implementation MPIdentifyHTTPRequest

- (instancetype)initWithIdentityApiRequest:(MPIdentityApiRequest *)apiRequest {
    self = [super init];
    if (self) {
        _knownIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:apiRequest.identities];
        
        NSNumber *mpid = [MPPersistenceController_PRIVATE mpId];
        if (mpid.longLongValue != 0) {
            _previousMPID = [MPPersistenceController_PRIVATE mpId].stringValue;
        }
        
        MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];

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
            NSData *deviceTokenData = [MPNotificationController_PRIVATE deviceToken];
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
    NSMutableDictionary *dictionary = [[super dictionaryRepresentation] mutableCopy];
    
    if (_previousMPID) {
        dictionary[@"previous_mpid"] = _previousMPID;
    }
    
    NSDictionary *identitiesDictionary = [_knownIdentities dictionaryRepresentation];
    
    if (identitiesDictionary) {
        dictionary[@"known_identities"] = identitiesDictionary;
    }
    
    return dictionary;
}

@end

@implementation MPIdentityHTTPClientSDK

+ (NSDictionary *)clientSDKDictionaryWithVersion:(NSString *)sdkVersion {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    

    NSString *platform = @"ios";
    #if TARGET_OS_TV == 1
    platform = @"tvos";
    #endif
    
    dictionary[@"platform"] = platform;
    dictionary[@"sdk_vendor"] = @"mparticle";
    
    if (sdkVersion) {
        dictionary[@"sdk_version"] = sdkVersion;
    }
    
    return dictionary;
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
    NSMutableDictionary *dictionary = [[super dictionaryRepresentation] mutableCopy];
    
    NSMutableArray *identityChanges = [NSMutableArray array];
    [_identityChanges enumerateObjectsUsingBlock:^(MPIdentityHTTPIdentityChange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *changeDictionary = [obj dictionaryRepresentation];
        [identityChanges addObject:changeDictionary];
    }];
    
    if (identityChanges) {
        dictionary[@"identity_changes"] = identityChanges;
    }
    
    return dictionary;
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
    NSMutableDictionary *dictionary = [[super dictionaryRepresentation] mutableCopy];
    [dictionary removeObjectForKey:@"client_sdk"];
    [dictionary removeObjectForKey:@"request_timestamp_ms"];
    
    dictionary[@"request_type"] = @"alias";
    
    dictionary[@"api_key"] = MParticle.sharedInstance.stateMachine.apiKey;
    
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    
    if (_sourceMPID != nil) {
        dataDictionary[@"source_mpid"] = _sourceMPID;
    }
    
    if (_destinationMPID != nil) {
        dataDictionary[@"destination_mpid"] = _destinationMPID;
    }
    
    if (_startTime) {
        NSNumber *requestTimestamp = @(floor(_startTime.timeIntervalSince1970*1000));
        if (requestTimestamp != nil) {
            dataDictionary[@"start_unixtime_ms"] = @(requestTimestamp.longLongValue);
        }
    }
    
    if (_endTime) {
        NSNumber *requestTimestamp = @(floor(_endTime.timeIntervalSince1970*1000));
        if (requestTimestamp != nil) {
            dataDictionary[@"end_unixtime_ms"] = @(requestTimestamp.longLongValue);
        }
    }
    
    NSString *deviceApplicationStamp = [MParticle sharedInstance].stateMachine.consumerInfo.deviceApplicationStamp;
    if (deviceApplicationStamp) {
        dataDictionary[@"device_application_stamp"] = deviceApplicationStamp;
    }
    
    dictionary[@"data"] = dataDictionary;
    
    return dictionary;
}

@end


@implementation MPIdentityHTTPIdentities

- (instancetype)initWithIdentities:(NSDictionary *)identities {
    self = [super init];
    if (self) {
        [identities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            MPIdentity identityType = (MPIdentity)key.intValue;
            
            switch (identityType) {
                case MPIdentityCustomerId:
                    self->_customerId = obj;
                    break;
                    
                case MPIdentityEmail:
                    self->_email = obj;
                    break;
                    
                case MPIdentityFacebook:
                    self->_facebook = obj;
                    break;
                    
                case MPIdentityFacebookCustomAudienceId:
                    self->_facebookCustomAudienceId = obj;
                    break;
                    
                case MPIdentityGoogle:
                    self->_google = obj;
                    break;
                    
                case MPIdentityMicrosoft:
                    self->_microsoft = obj;
                    break;
                    
                case MPIdentityOther:
                    self->_other = obj;
                    break;
                    
                case MPIdentityTwitter:
                    self->_twitter = obj;
                    break;
                    
                case MPIdentityYahoo:
                    self->_yahoo = obj;
                    break;
                    
                case MPIdentityOther2:
                    self->_other2 = obj;
                    break;
                    
                case MPIdentityOther3:
                    self->_other3 = obj;
                    break;
                    
                case MPIdentityOther4:
                    self->_other4 = obj;
                    break;
                    
                case MPIdentityOther5:
                    self->_other5 = obj;
                    break;
                    
                case MPIdentityOther6:
                    self->_other6 = obj;
                    break;
                    
                case MPIdentityOther7:
                    self->_other7 = obj;
                    break;
                    
                case MPIdentityOther8:
                    self->_other8 = obj;
                    break;
                    
                case MPIdentityOther9:
                    self->_other9 = obj;
                    break;
                    
                case MPIdentityOther10:
                    self->_other10 = obj;
                    break;
                    
                case MPIdentityMobileNumber:
                    self->_mobileNumber = obj;
                    break;
                    
                case MPIdentityPhoneNumber2:
                    self->_phoneNumber2 = obj;
                    break;
                    
                case MPIdentityPhoneNumber3:
                    self->_phoneNumber3 = obj;
                    break;
                    
                case MPIdentityIOSAdvertiserId: {
                    NSNumber *currentStatus = [MParticle sharedInstance].stateMachine.attAuthorizationStatus;
                    if (currentStatus == nil || currentStatus.integerValue == MPATTAuthorizationStatusAuthorized) {
                        self->_advertiserId = obj;
                    }
                    break;
                }
                    
                case MPIdentityIOSVendorId:
                    self->_vendorId = obj;
                    break;
                    
                case MPIdentityPushToken:
                    self->_pushToken = obj;
                    break;
                    
                case MPIdentityDeviceApplicationStamp:
                    self->_deviceApplicationStamp = obj;
                    break;
                default:
                    break;
            }
        }];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (_advertiserId) {
        dictionary[@"ios_idfa"] = _advertiserId;
    }
    
    if (_vendorId) {
        dictionary[@"ios_idfv"] = _vendorId;
    }
    
    if (_deviceApplicationStamp) {
        dictionary[@"device_application_stamp"] = _deviceApplicationStamp;
    }
    
#if TARGET_OS_IOS == 1
    
    if (_pushToken) {
        dictionary[@"push_token"] = _pushToken;
    }
    
#endif
    
    if (_customerId) {
        dictionary[@"customerid"] = _customerId;
    }
    
    if (_email) {
        dictionary[@"email"] = _email;
    }
    
    if (_facebook) {
        dictionary[@"facebook"] = _facebook;
    }
    
    if (_facebookCustomAudienceId) {
        dictionary[@"facebookcustomaudienceid"] = _facebookCustomAudienceId;
    }
    
    if (_google) {
        dictionary[@"google"] = _google;
    }
    
    if (_microsoft) {
        dictionary[@"microsoft"] = _microsoft;
    }
    
    if (_other) {
        dictionary[@"other"] = _other;
    }
    
    if (_twitter) {
        dictionary[@"twitter"] = _twitter;
    }
    
    if (_yahoo) {
        dictionary[@"yahoo"] = _yahoo;
    }
    
    if (_other2) {
        dictionary[@"other2"] = _other2;
    }
    
    if (_other3) {
        dictionary[@"other3"] = _other3;
    }
    
    if (_other4) {
        dictionary[@"other4"] = _other4;
    }
    
    if (_other5) {
        dictionary[@"other5"] = _other5;
    }
    
    if (_other6) {
        dictionary[@"other6"] = _other6;
    }
    
    if (_other7) {
        dictionary[@"other7"] = _other7;
    }
    
    if (_other8) {
        dictionary[@"other8"] = _other8;
    }
    
    if (_other9) {
        dictionary[@"other9"] = _other9;
    }
    
    if (_other10) {
        dictionary[@"other10"] = _other10;
    }
    
    if (_mobileNumber) {
        dictionary[@"mobile_number"] = _mobileNumber;
    }
    
    if (_phoneNumber2) {
        dictionary[@"phone_number_2"] = _phoneNumber2;
    }

    if (_phoneNumber3) {
        dictionary[@"phone_number_3"] = _phoneNumber3;
    }
    
    
    return dictionary;
}

+ (NSString *)stringForIdentityType:(MPIdentity)identityType {
    switch (identityType) {
        case MPIdentityCustomerId:
            return @"customerid";
            
        case MPIdentityEmail:
            return @"email";
            
        case MPIdentityFacebook:
            return @"facebook";
            
        case MPIdentityFacebookCustomAudienceId:
            return @"facebookcustomaudienceid";
            
        case MPIdentityGoogle:
            return @"google";
            
        case MPIdentityMicrosoft:
            return @"microsoft";
            
        case MPIdentityOther:
            return @"other";
            
        case MPIdentityTwitter:
            return @"twitter";
            
        case MPIdentityYahoo:
            return @"yahoo";
            
        case MPIdentityOther2:
            return @"other2";
            
        case MPIdentityOther3:
            return @"other3";
            
        case MPIdentityOther4:
            return @"other4";
            
        case MPIdentityOther5:
            return @"other5";
            
        case MPIdentityOther6:
            return @"other6";
            
        case MPIdentityOther7:
            return @"other7";
            
        case MPIdentityOther8:
            return @"other8";
            
        case MPIdentityOther9:
            return @"other9";
            
        case MPIdentityOther10:
            return @"other10";
            
        case MPIdentityMobileNumber:
            return @"mobile_number";
            
        case MPIdentityPhoneNumber2:
            return @"phone_number_2";
            
        case MPIdentityPhoneNumber3:
            return @"phone_number_3";
            
        case MPIdentityIOSAdvertiserId:
            return @"ios_idfa";
            
        case MPIdentityIOSVendorId:
            return @"ios_idfv";
            
        case MPIdentityPushToken:
            return @"push_token";
            
        case MPIdentityDeviceApplicationStamp:
            return @"device_application_stamp";
            
        default:
            return nil;
    }
}

+ (NSNumber *)identityTypeForString:(NSString *)identityString {
    if ([identityString isEqualToString:@"customerid"]){
        return @(MPIdentityCustomerId);
    } else if ([identityString isEqualToString:@"email"]){
        return @(MPIdentityEmail);
    } else if ([identityString isEqualToString:@"facebook"]){
        return @(MPIdentityFacebook);
    } else if ([identityString isEqualToString:@"facebookcustomaudienceid"]){
        return @(MPIdentityFacebookCustomAudienceId);
    } else if ([identityString isEqualToString:@"google"]){
        return @(MPIdentityGoogle);
    } else if ([identityString isEqualToString:@"microsoft"]){
        return @(MPIdentityMicrosoft);
    } else if ([identityString isEqualToString:@"other"]){
        return @(MPIdentityOther);
    } else if ([identityString isEqualToString:@"twitter"]){
        return @(MPIdentityTwitter);
    } else if ([identityString isEqualToString:@"yahoo"]){
        return @(MPIdentityYahoo);
    } else if ([identityString isEqualToString:@"other2"]){
        return @(MPIdentityOther2);
    } else if ([identityString isEqualToString:@"other3"]){
        return @(MPIdentityOther3);
    } else if ([identityString isEqualToString:@"other4"]){
        return @(MPIdentityOther4);
    } else if ([identityString isEqualToString:@"other5"]){
        return @(MPIdentityOther5);
    } else if ([identityString isEqualToString:@"other6"]){
        return @(MPIdentityOther6);
    } else if ([identityString isEqualToString:@"other7"]){
        return @(MPIdentityOther7);
    } else if ([identityString isEqualToString:@"other8"]){
        return @(MPIdentityOther8);
    } else if ([identityString isEqualToString:@"other9"]){
        return @(MPIdentityOther9);
    } else if ([identityString isEqualToString:@"other10"]){
        return @(MPIdentityOther10);
    } else if ([identityString isEqualToString:@"mobile_number"]){
        return @(MPIdentityMobileNumber);
    } else if ([identityString isEqualToString:@"phone_number_2"]){
        return @(MPIdentityPhoneNumber2);
    } else if ([identityString isEqualToString:@"phone_number_3"]){
        return @(MPIdentityPhoneNumber3);
    } else if ([identityString isEqualToString:@"ios_idfa"]){
        return @(MPIdentityIOSAdvertiserId);
    } else if ([identityString isEqualToString:@"ios_idfv"]){
        return @(MPIdentityIOSVendorId);
    } else if ([identityString isEqualToString:@"push_token"]){
        return @(MPIdentityPushToken);
    } else if ([identityString isEqualToString:@"device_application_stamp"]){
        return @(MPIdentityDeviceApplicationStamp);
    } else {
        return nil;
    }
}

@end

@implementation MPIdentityHTTPIdentityChange

- (instancetype)initWithOldValue:(NSString *)oldValue value:(NSString *)value identityType:(NSString *)identityType {
    self = [super init];
    if (self) {
        _oldValue = oldValue;
        _value = value;
        _identityType = identityType;
    }
    return self;
}

- (NSMutableDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (_oldValue) {
        dictionary[@"old_value"] = _oldValue;
    } else {
        dictionary[@"old_value"] = [NSNull null];
    }
    
    if (_value) {
        dictionary[@"new_value"] = _value;
    }
    else {
        dictionary[@"new_value"] = [NSNull null];
    }
    if (_identityType) {
        dictionary[@"identity_type"] = _identityType;
    }
    return dictionary;
}

@end

@implementation MPIdentityHTTPSuccessResponse

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _context = dictionary[kMPIdentityRequestKeyContext];
        NSString *mpidString = dictionary[kMPIdentityRequestKeyMPID];
        if (mpidString) {
            _mpid = [NSNumber numberWithLongLong:(long long)[mpidString longLongValue]];
        }
        _isEphemeral = [[dictionary objectForKey:kMPIdentityRequestKeyIsEphemeral] boolValue];
        _isLoggedIn =  [[dictionary objectForKey:kMPIdentityRequestKeyIsLoggedIn] boolValue];

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
        _changeResults = [dictionary objectForKey:kMPIdentityRequestKeyChangeResults];
    }
    return self;
}

@end
