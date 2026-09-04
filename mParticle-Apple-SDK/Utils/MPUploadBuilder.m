#import "MPUploadBuilder.h"
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPConsumerInfo.h"
#import "MPForwardRecord.h"
#import "MPIntegrationAttributes.h"
#import "MPConsentState.h"
#import "MPConsentSerialization.h"
#import "mParticle.h"
#import "MPILogger.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

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

    MPPreparedMessages *preparedMessages = [MPUploadBuilderFields preparedMessagesFrom:messages];
    NSArray *messageDictionaries = preparedMessages.messageDictionaries;
    _preparedMessageIds = [preparedMessages.preparedMessageIds mutableCopy];
    _containsOptOutMessage = preparedMessages.containsOptOutMessage;
    
    NSNumber *ltv;
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    ltv = [userDefaults mpObjectForKey:kMPLifeTimeValueKey userId:mpid];
    if (ltv == nil) {
        ltv = @0;
    }
    
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;

    _uploadDictionary = [[MPUploadBuilderFields seedDictionaryWithOptOut:stateMachine.optOut
                                                           uploadInterval:uploadInterval
                                                            lifetimeValue:ltv] mutableCopy];

    if (dataPlanId != nil) {
        _dPId = dataPlanId;
        if (dataPlanVersion != nil) {
            _dPVersion = dataPlanVersion;
        }

        NSDictionary *dataPlanContext = [MPUploadBuilderFields dataPlanDictionaryWithDataPlanId:dataPlanId dataPlanVersion:dataPlanVersion];
        _uploadDictionary[kMPContextKey] = dataPlanContext;
    }

    if (messageDictionaries.count > 0) {
        _uploadDictionary[kMPMessagesKey] = messageDictionaries;
    }

    if (sessionTimeout > 0) {
        _uploadDictionary[kMPSessionTimeoutKey] = @(sessionTimeout);
    }

    NSDictionary *customModulesDictionary = [MPUploadBuilderFields customModulesDictionaryFrom:stateMachine.customModules];
    if (customModulesDictionary) {
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

    NSDictionary *headerFields = [MPUploadBuilderFields headerFieldsWithMessageId:[[NSUUID UUID] UUIDString]
                                                                       timestampMs:MPMilliseconds([[NSDate date] timeIntervalSince1970])
                                                                        sdkVersion:kMParticleSDKVersion
                                                                            apiKey:stateMachine.apiKey];
    [_uploadDictionary addEntriesFromDictionary:headerFields];
    
    NSDictionary *appAndDeviceInfoDict = [[MParticle sharedInstance].persistenceController appAndDeviceInfoForSessionId:_sessionId];
    
    NSDictionary *appInfoDict = appAndDeviceInfoDict[MPApplicationKeys.kMPApplicationInformationKey];
    if (appInfoDict) {
        _uploadDictionary[MPApplicationKeys.kMPApplicationInformationKey] = appInfoDict;
    } else {
        // If the info wasn't saved in the session, use the old behavior and grab it now
        // NOTE: This should only ever happen the first time after upgrading to the new schema if there are old sessions left
        MPApplication_PRIVATE *application = [[MPApplication_PRIVATE alloc] initWithStateMachine:(id<MPApplicationStateMachineProtocol>)stateMachine
                                                                                   userDefaults:(id<MPApplicationMPUserDefaultsProtocol>)MPUserDefaultsConnector.userDefaults
                                                                                    environment:[MPStateMachine_PRIVATE environment]
                                                                               deploymentTarget:__IPHONE_OS_VERSION_MIN_REQUIRED
                                                                                       buildSDK:__IPHONE_OS_VERSION_MAX_ALLOWED];
        _uploadDictionary[MPApplicationKeys.kMPApplicationInformationKey] = [application dictionaryRepresentation];
    }
    
    NSDictionary *deviceInfoDict = appAndDeviceInfoDict[kMPDeviceInformationKey];
    if (deviceInfoDict) {
        _uploadDictionary[kMPDeviceInformationKey] = deviceInfoDict;
    } else {
        // If the info wasn't saved in the session, use the old behavior and grab it now
        // NOTE: This should only ever happen the first time after upgrading to the new schema if there are old sessions left
        MParticle* mparticle = MParticle.sharedInstance;
        MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
        logger.customLogger = mparticle.customLogger;
        MPUserDefaults* userDefaults = MPUserDefaultsConnector.userDefaults;
        MPDevice *device = [[MPDevice alloc] initWithStateMachine:(id<MPStateMachineMPDeviceProtocol>)mparticle.stateMachine
                                                     userDefaults:(id<MPIdentityApiMPUserDefaultsProtocol>)userDefaults
                                                         identity:(id<MPIdentityApiMPDeviceProtocol>)mparticle.identity
                                                           logger:logger];
        NSNumber *mpid = _uploadDictionary[kMPRemoteConfigMPIDKey];
        _uploadDictionary[kMPDeviceInformationKey] = [device dictionaryRepresentationWithMpid:mpid];
    }
    
    // Update the IDFA if it changed after the session was created/saved (the IDFA changed or the ATTStatus has been set to authorized)
    NSNumber *authStatus = [MParticle sharedInstance].stateMachine.attAuthorizationStatus;
    NSNumber *mpid = _uploadDictionary[kMPRemoteConfigMPIDKey];
    NSDictionary *userIdentities = [[[MParticle sharedInstance] identity] getUser:mpid].identities;
    NSString *advertiserId = userIdentities[@(MPIdentityIOSAdvertiserId)];
    BOOL isATTAuthorized = authStatus != nil && authStatus.intValue == MPATTAuthorizationStatusAuthorized;

    NSDictionary *updatedDeviceInfo = [MPUploadBuilderFields deviceInfoDictionaryByAddingAdvertiserId:advertiserId
                                                                                       isATTAuthorized:isATTAuthorized
                                                                                                    to:_uploadDictionary[kMPDeviceInformationKey]];
    if (updatedDeviceInfo) {
        _uploadDictionary[kMPDeviceInformationKey] = updatedDeviceInfo;
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

    if (forwardRecords) {
        NSMutableArray *dataDictionaries = [NSMutableArray arrayWithCapacity:forwardRecords.count];
        NSMutableArray<NSNumber *> *recordIds = [NSMutableArray arrayWithCapacity:forwardRecords.count];
        for (MPForwardRecord *forwardRecord in forwardRecords) {
            [dataDictionaries addObject:forwardRecord.dataDictionary ?: [NSNull null]];
            [recordIds addObject:@(forwardRecord.forwardRecordId)];
        }

        MPForwardRecordBatch *batch = [MPUploadBuilderFields forwardRecordBatchFromDataDictionaries:dataDictionaries recordIds:recordIds];
        if (batch.dataDictionaries.count > 0) {
            _uploadDictionary[kMPForwardStatsRecord] = batch.dataDictionaries;
            [persistence deleteForwardRecordsIds:batch.recordIds];
        }
    }

    NSArray<MPIntegrationAttributes *> *integrationAttributesArray = [persistence fetchIntegrationAttributes];
    if (integrationAttributesArray) {
        NSMutableArray<NSDictionary *> *integrationAttributesDictionaries = [NSMutableArray arrayWithCapacity:integrationAttributesArray.count];
        for (MPIntegrationAttributes *integrationAttributes in integrationAttributesArray) {
            [integrationAttributesDictionaries addObject:[integrationAttributes dictionaryRepresentation]];
        }

        _uploadDictionary[MPIntegrationAttributesKey] = [MPUploadBuilderFields mergedIntegrationAttributesDictionaryFrom:integrationAttributesDictionaries];
    }
    
    MPConsentState *consentState = [MPPersistenceController_PRIVATE effectiveConsentStateForMpid:_uploadDictionary[kMPRemoteConfigMPIDKey]];
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
    if (userAttributes.count > 0) {
        NSDictionary<NSString *, id> *stringifiedAttributes = [MPUploadBuilderFields stringifiedUserAttributes:userAttributes];
        if (stringifiedAttributes.count > 0) {
            _uploadDictionary[kMPUserAttributeKey] = stringifiedAttributes;
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
