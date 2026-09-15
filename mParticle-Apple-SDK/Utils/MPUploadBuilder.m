#import "MPUploadBuilder.h"
#import "MPIConstants.h"
#import "MPEnums.h"
@import mParticle_Apple_SDK_Swift;

@interface MPUploadBuilder() {
    NSMutableDictionary<NSString *, id> *_uploadDictionary;
    BOOL _containsOptOutMessage;
    NSString *_dPId;
    NSNumber *_dPVersion;
    NSObject *_uploadSettings;
    MPUploadBuilderContext *_context;
}

@end

@implementation MPUploadBuilder

- (nonnull instancetype)initWithMpid:(nonnull NSNumber *)mpid sessionId:(nullable NSNumber *)sessionId messages:(nonnull NSArray<MPMessage *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion uploadSettings:(id)uploadSettings context:(MPUploadBuilderContext *)context {
    self = [super init];
    if (!self || !messages || messages.count == 0) {
        return nil;
    }
    
    _uploadSettings = uploadSettings;
    _context = context;
    _sessionId = sessionId;

    MPPreparedMessages *preparedMessages = [MPUploadBuilderFields preparedMessagesFrom:messages];
    NSArray *messageDictionaries = preparedMessages.messageDictionaries;
    _preparedMessageIds = [preparedMessages.preparedMessageIds mutableCopy];
    _containsOptOutMessage = preparedMessages.containsOptOutMessage;
    
    NSNumber *ltv = context.lifetimeValue(mpid);
    MPStateMachine_PRIVATE *stateMachine = context.stateMachine();

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
    MPStateMachine_PRIVATE *stateMachine = _context.stateMachine();

    NSDictionary *headerFields = [MPUploadBuilderFields headerFieldsWithMessageId:_context.messageID()
                                                                       timestampMs:_context.timestamp()
                                                                        sdkVersion:_context.sdkVersion
                                                                            apiKey:stateMachine.apiKey];
    [_uploadDictionary addEntriesFromDictionary:headerFields];
    
    NSDictionary *appAndDeviceInfoDict = (_sessionId ? [_context.persistence() appAndDeviceInfoForSessionId:_sessionId] : @{});
    
    NSDictionary *appInfoDict = appAndDeviceInfoDict[MPApplicationKeys.kMPApplicationInformationKey];
    if (appInfoDict) {
        _uploadDictionary[MPApplicationKeys.kMPApplicationInformationKey] = appInfoDict;
    } else {
        _uploadDictionary[MPApplicationKeys.kMPApplicationInformationKey] = _context.applicationInfo(stateMachine);
    }
    
    NSDictionary *deviceInfoDict = appAndDeviceInfoDict[kMPDeviceInformationKey];
    if (deviceInfoDict) {
        _uploadDictionary[kMPDeviceInformationKey] = deviceInfoDict;
    } else {
        _uploadDictionary[kMPDeviceInformationKey] = _context.deviceInfo(_uploadDictionary[kMPRemoteConfigMPIDKey]);
    }
    
    // Update the IDFA if it changed after the session was created/saved (the IDFA changed or the ATTStatus has been set to authorized)
    NSNumber *authStatus = _context.stateMachine().attAuthorizationStatus;
    NSNumber *mpid = _uploadDictionary[kMPRemoteConfigMPIDKey];
    NSString *advertiserId = _context.advertiserID(mpid);
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
    
    id<MPUploadEnrichmentPersistence> persistence = _context.persistence();
    NSArray<MPForwardRecordPRIVATE *> *forwardRecords = [persistence fetchForwardRecords];

    if (forwardRecords) {
        NSMutableArray *dataDictionaries = [NSMutableArray arrayWithCapacity:forwardRecords.count];
        NSMutableArray<NSNumber *> *recordIds = [NSMutableArray arrayWithCapacity:forwardRecords.count];
        for (MPForwardRecordPRIVATE *forwardRecord in forwardRecords) {
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
    
    NSDictionary *consentStateDictionary = _context.consent(_uploadDictionary[kMPRemoteConfigMPIDKey]);
    if (consentStateDictionary) {
        _uploadDictionary[kMPConsentState] = consentStateDictionary;
    }

    id updatedDictionary = _context.transformBatch(_uploadDictionary);
    if (updatedDictionary == nil) {
        [_context.logger() warning:@"Not uploading batch due to 'onCreateBatch' handler returning 'nil'"];
        return;
    } else if ([updatedDictionary isKindOfClass:[NSDictionary class]] && ![updatedDictionary isEqual:_uploadDictionary]) {
        [_context.logger() warning:@"Replacing batch with mutated version from 'onCreateBatch' handler"];
        _uploadDictionary = [updatedDictionary mutableCopy];
        _uploadDictionary[@"mb"] = @YES;
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
