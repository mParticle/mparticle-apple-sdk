#import "MPUploadBuilder.h"
#import "MPMessage.h"
#import "MPSession.h"
#import "MPUpload.h"
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPCustomModule.h"
#import "MPConsumerInfo.h"
#import "MPApplication.h"
#import "MPForwardRecord.h"
#import "MPIntegrationAttributes.h"
#import "MPConsentState.h"
#import "MPConsentSerialization.h"
#import "mParticle.h"
#import "MPILogger.h"
#import "MParticleSwift.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong, nonnull) MParticleOptions *options;

@end

@interface MPUploadBuilder() {
    NSMutableDictionary<NSString *, id> *_uploadDictionary;
    BOOL _containsOptOutMessage;
    NSString *_dPId;
    NSNumber *_dPVersion;
    MPUploadSettings *_uploadSettings;
}

@end

@implementation MPUploadBuilder

- (nonnull instancetype)initWithMpid:(nonnull NSNumber *)mpid sessionId:(nullable NSNumber *)sessionId messages:(nonnull NSArray<MPMessage *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion uploadSettings:(id)uploadSettings {
    self = [super init];
    if (!self || !messages || messages.count == 0) {
        return nil;
    }
    
    _uploadSettings = uploadSettings;
    _sessionId = sessionId;
    _containsOptOutMessage = NO;
    
    NSUInteger numberOfMessages = messages.count;
    NSMutableArray *messageDictionaries = [[NSMutableArray alloc] initWithCapacity:numberOfMessages];
    _preparedMessageIds = [[NSMutableArray alloc] initWithCapacity:numberOfMessages];

    [messages enumerateObjectsUsingBlock:^(MPMessage *message, NSUInteger idx, BOOL *stop) {
        if (message != nil && (NSNull *)message != [NSNull null]) {
            if ([message.messageType isEqualToString:kMPMessageTypeStringOptOut]) {
                self->_containsOptOutMessage = YES;
            }
            
            [self->_preparedMessageIds addObject:@(message.messageId)];
            
            NSDictionary *messageDictionaryRepresentation = [message dictionaryRepresentation];
            if (messageDictionaryRepresentation) {
                [messageDictionaries addObject:messageDictionaryRepresentation];
            }
        }
    }];
    
    NSNumber *ltv;
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    ltv = [userDefaults mpObjectForKey:kMPLifeTimeValueKey userId:mpid];
    if (ltv == nil) {
        ltv = @0;
    }
    
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    _uploadDictionary = [@{
        kMPOptOutKey:@(stateMachine.optOut),
        kMPUploadIntervalKey:@(uploadInterval),
        kMPLifeTimeValueKey:ltv
    } mutableCopy];
    
    if (dataPlanId != nil) {
        NSMutableDictionary<NSString *, id> *dataPlanDictionary = [@{
        } mutableCopy];
        
        dataPlanDictionary[kMPDataPlanIdKey] = dataPlanId;
        _dPId = dataPlanId;
        
        if (dataPlanVersion != nil) {
            dataPlanDictionary[kMPDataPlanVersionKey] = dataPlanVersion;
            _dPVersion = dataPlanVersion;
        }
        
        _uploadDictionary[kMPContextKey] = @{kMPDataPlanKey:dataPlanDictionary};
    }

    if (messageDictionaries.count > 0) {
        _uploadDictionary[kMPMessagesKey] = messageDictionaries;
    }

    if (sessionTimeout > 0) {
        _uploadDictionary[kMPSessionTimeoutKey] = @(sessionTimeout);
    }
    
    if (stateMachine.customModules) {
        NSMutableDictionary *customModulesDictionary = [[NSMutableDictionary alloc] initWithCapacity:stateMachine.customModules.count];
        
        for (MPCustomModule *customModule in stateMachine.customModules) {
            customModulesDictionary[[customModule.customModuleId stringValue]] = [customModule dictionaryRepresentation];
        }
        
        _uploadDictionary[kMPRemoteConfigCustomModuleSettingsKey] = customModulesDictionary;
    }
    
    _uploadDictionary[kMPRemoteConfigMPIDKey] = mpid;
    
    return self;
}

- (NSString *)description {
    NSString *description;
    
    if (_sessionId != nil) {
        description = [NSString stringWithFormat:@"MPUploadBuilder\n Session Id: %lld\n UploadDictionary: %@", self.sessionId.longLongValue, _uploadDictionary];
    } else {
        description = [NSString stringWithFormat:@"MPUploadBuilder\n UploadDictionary: %@", _uploadDictionary];
    }
    
    return description;
}

#pragma mark Public instance methods
- (void)build:(void (^)(MPUpload *upload))completionHandler {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    _uploadDictionary[kMPMessageTypeKey] = kMPMessageTypeRequestHeader;
    _uploadDictionary[kMPmParticleSDKVersionKey] = kMParticleSDKVersion;
    _uploadDictionary[kMPMessageIdKey] = [[NSUUID UUID] UUIDString];
    _uploadDictionary[kMPTimestampKey] = MPMilliseconds([[NSDate date] timeIntervalSince1970]);
    _uploadDictionary[kMPApplicationKey] = stateMachine.apiKey;
    
    NSDictionary *appAndDeviceInfoDict = [[MParticle sharedInstance].persistenceController appAndDeviceInfoForSessionId:_sessionId];
    
    NSDictionary *appInfoDict = appAndDeviceInfoDict[kMPApplicationInformationKey];
    if (appInfoDict) {
        _uploadDictionary[kMPApplicationInformationKey] = appInfoDict;
    } else {
        // If the info wasn't saved in the session, use the old behavior and grab it now
        // NOTE: This should only ever happen the first time after upgrading to the new schema if there are old sessions left
        MPApplication_PRIVATE *application = [[MPApplication_PRIVATE alloc] init];
        _uploadDictionary[kMPApplicationInformationKey] = [application dictionaryRepresentation];
    }
    
    NSDictionary *deviceInfoDict = appAndDeviceInfoDict[kMPDeviceInformationKey];
    if (deviceInfoDict) {
        _uploadDictionary[kMPDeviceInformationKey] = deviceInfoDict;
    } else {
        // If the info wasn't saved in the session, use the old behavior and grab it now
        // NOTE: This should only ever happen the first time after upgrading to the new schema if there are old sessions left
        MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];
        NSNumber *mpid = _uploadDictionary[kMPRemoteConfigMPIDKey];
        _uploadDictionary[kMPDeviceInformationKey] = [device dictionaryRepresentationWithMpid:mpid];
    }
    
    // Update the IDFA if it changed after the session was created/saved (the IDFA changed or the ATTStatus has been set to authorized)
    NSNumber *authStatus = [MParticle sharedInstance].stateMachine.attAuthorizationStatus;
    NSNumber *mpid = _uploadDictionary[kMPRemoteConfigMPIDKey];
    NSDictionary *userIdentities = [[[MParticle sharedInstance] identity] getUser:mpid].identities;
    NSString *advertiserId = userIdentities[@(MPIdentityIOSAdvertiserId)];

    if (authStatus && advertiserId && authStatus.intValue == MPATTAuthorizationStatusAuthorized) {
        NSMutableDictionary *deviceInfoDictCopy = [_uploadDictionary[kMPDeviceInformationKey] mutableCopy];
        deviceInfoDictCopy[kMPDeviceAdvertiserIdKey] = advertiserId;
        _uploadDictionary[kMPDeviceInformationKey] = [deviceInfoDictCopy copy];
    }
    
    MPConsumerInfo *consumerInfo = stateMachine.consumerInfo;
    
    NSDictionary *cookies = [consumerInfo cookiesDictionaryRepresentation];
    if (cookies) {
        _uploadDictionary[kMPRemoteConfigCookiesKey] = cookies;
    }
    
    NSString *deviceApplicationStamp = consumerInfo.deviceApplicationStamp;
    if (deviceApplicationStamp) {
        _uploadDictionary[kMPDeviceApplicationStampKey] = deviceApplicationStamp;
    }
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSArray<MPForwardRecord *> *forwardRecords = [persistence fetchForwardRecords];
    NSMutableArray<NSNumber *> *forwardRecordsIds = nil;
    
    if (forwardRecords) {
        NSUInteger numberOfRecords = forwardRecords.count;
        NSMutableArray *fsr = [[NSMutableArray alloc] initWithCapacity:numberOfRecords];
        forwardRecordsIds = [[NSMutableArray alloc] initWithCapacity:numberOfRecords];
        
        for (MPForwardRecord *forwardRecord in forwardRecords) {
            if (forwardRecord.dataDictionary) {
                [fsr addObject:forwardRecord.dataDictionary];
                [forwardRecordsIds addObject:@(forwardRecord.forwardRecordId)];
            }
        }
        
        if (fsr.count > 0) {
            _uploadDictionary[kMPForwardStatsRecord] = fsr;
            [persistence deleteForwardRecordsIds:forwardRecordsIds];
        }
    }
    
    NSArray<MPIntegrationAttributes *> *integrationAttributesArray = [persistence fetchIntegrationAttributes];
    if (integrationAttributesArray) {
        NSMutableDictionary *integrationAttributesDictionary = [[NSMutableDictionary alloc] initWithCapacity:integrationAttributesArray.count];
        
        for (MPIntegrationAttributes *integrationAttributes in integrationAttributesArray) {
            [integrationAttributesDictionary addEntriesFromDictionary:[integrationAttributes dictionaryRepresentation]];
        }
        
        _uploadDictionary[MPIntegrationAttributesKey] = integrationAttributesDictionary;
    }
    
    MPConsentState *consentState = [MPPersistenceController_PRIVATE consentStateForMpid:_uploadDictionary[kMPRemoteConfigMPIDKey]];
    if (consentState) {
        NSDictionary *consentStateDictionary = [MPConsentSerialization serverDictionaryFromConsentState:consentState];
        if (consentStateDictionary) {
            _uploadDictionary[kMPConsentState] = consentStateDictionary;
        }
    }
    
    if (MParticle.sharedInstance.options.onCreateBatch != NULL) {
        NSDictionary *updatedDictionary = MParticle.sharedInstance.options.onCreateBatch(_uploadDictionary);
        if (updatedDictionary == nil) {
            MPILogWarning(@"Not uploading batch due to 'onCreateBatch' handler returning 'nil'");
            return;
        } else if ([updatedDictionary isKindOfClass:[NSDictionary class]] && ![updatedDictionary isEqual:_uploadDictionary]) {
            MPILogWarning(@"Replacing batch with mutated version from 'onCreateBatch' handler");
            _uploadDictionary = [updatedDictionary mutableCopy];
            _uploadDictionary[@"mb"] = @YES;
        }
    }
    
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:_sessionId
                                          uploadDictionary:_uploadDictionary
                                                dataPlanId:_dPId
                                           dataPlanVersion:_dPVersion
                                            uploadSettings:_uploadSettings];
    upload.containsOptOutMessage = _containsOptOutMessage;
    completionHandler(upload);
}

- (MPUploadBuilder *)withUserAttributes:(NSDictionary<NSString *, id> *)userAttributes deletedUserAttributes:(NSSet<NSString *> *)deletedUserAttributes {
    if ([userAttributes count] > 0) {
        NSMutableDictionary<NSString *, id> *userAttributesCopy = [userAttributes mutableCopy];
        if (!userAttributesCopy) {
            return self;
        }
        
        NSArray *keys = [userAttributesCopy allKeys];
        Class numberClass = [NSNumber class];
        
        for (NSString *key in keys) {
            id currentValue = userAttributesCopy[key];
            NSString *newValue = [currentValue isKindOfClass:numberClass] ? [(NSNumber *)currentValue stringValue] : currentValue;
            
            if (newValue) {
                userAttributesCopy[key] = newValue;
            }
        }
        
        if (userAttributesCopy.count > 0) {
            _uploadDictionary[kMPUserAttributeKey] = userAttributesCopy;
        }
    }
    
    if (deletedUserAttributes.count > 0 && _sessionId) {
        _uploadDictionary[kMPUserAttributeDeletedKey] = [deletedUserAttributes allObjects];
    }
    
    return self;
}

- (MPUploadBuilder *)withUserIdentities:(NSArray<NSDictionary<NSString *, id> *> *)userIdentities {
    if (userIdentities.count > 0) {
        _uploadDictionary[kMPUserIdentityArrayKey] = userIdentities;
    }
    
    return self;
}

@end
