#import "MPUploadBuilder.h"
#include <vector>
#import "MPMessage.h"
#import "MPSession.h"
#import "MPUpload.h"
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import "MPIUserDefaults.h"
#import "MPPersistenceController.h"
#import "MPCustomModule.h"
#import "MPConsumerInfo.h"
#import "MPApplication.h"
#import "MPDevice.h"
#import "MPForwardRecord.h"
#import "MPIntegrationAttributes.h"
#import "MPConsentState.h"
#import "MPConsentSerialization.h"
#import "mParticle.h"
#import "MPILogger.h"

using namespace std;

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;
@property (nonatomic, strong, nonnull) MParticleOptions *options;

@end

@interface MPUploadBuilder() {
    NSMutableDictionary<NSString *, id> *uploadDictionary;
    BOOL containsOptOutMessage;
    NSString *dPId;
    NSNumber *dPVersion;
}

@end

@implementation MPUploadBuilder

- (nonnull instancetype)initWithMpid: (nonnull NSNumber *) mpid sessionId:(nullable NSNumber *)sessionId messages:(nonnull NSArray<MPMessage *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion {
    self = [super init];
    if (!self || !messages || messages.count == 0) {
        return nil;
    }
    
    _sessionId = sessionId;
    containsOptOutMessage = NO;
    
    NSUInteger numberOfMessages = messages.count;
    NSMutableArray *messageDictionaries = [[NSMutableArray alloc] initWithCapacity:numberOfMessages];
    _preparedMessageIds = [[NSMutableArray alloc] initWithCapacity:numberOfMessages];

    [messages enumerateObjectsUsingBlock:^(MPMessage *message, NSUInteger idx, BOOL *stop) {
        if (message != nil && (NSNull *)message != [NSNull null]) {
            if ([message.messageType isEqualToString:kMPMessageTypeStringOptOut]) {
                self->containsOptOutMessage = YES;
            }
            
            [self->_preparedMessageIds addObject:@(message.messageId)];
            
            NSDictionary *messageDictionaryRepresentation = [message dictionaryRepresentation];
            if (messageDictionaryRepresentation) {
                [messageDictionaries addObject:messageDictionaryRepresentation];
            }
        }
    }];
    
    NSNumber *ltv;
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    ltv = [userDefaults mpObjectForKey:kMPLifeTimeValueKey userId:mpid];
    if (ltv == nil) {
        ltv = @0;
    }
    
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
    uploadDictionary = [@{
        kMPOptOutKey:@(stateMachine.optOut),
        kMPUploadIntervalKey:@(uploadInterval),
        kMPLifeTimeValueKey:ltv
    } mutableCopy];
    
    if (dataPlanId != nil) {
        NSMutableDictionary<NSString *, id> *dataPlanDictionary = [@{
        } mutableCopy];
        
        dataPlanDictionary[kMPDataPlanIdKey] = dataPlanId;
        dPId = dataPlanId;
        
        if (dataPlanVersion != nil) {
            dataPlanDictionary[kMPDataPlanVersionKey] = dataPlanVersion;
            dPVersion = dataPlanVersion;
        }
        
        uploadDictionary[kMPContextKey] = @{kMPDataPlanKey:dataPlanDictionary};
    }

    if (messageDictionaries.count > 0) {
        uploadDictionary[kMPMessagesKey] = messageDictionaries;
    }

    if (sessionTimeout > 0) {
        uploadDictionary[kMPSessionTimeoutKey] = @(sessionTimeout);
    }
    
    if (stateMachine.customModules) {
        NSMutableDictionary *customModulesDictionary = [[NSMutableDictionary alloc] initWithCapacity:stateMachine.customModules.count];
        
        for (MPCustomModule *customModule in stateMachine.customModules) {
            customModulesDictionary[[customModule.customModuleId stringValue]] = [customModule dictionaryRepresentation];
        }
        
        uploadDictionary[kMPRemoteConfigCustomModuleSettingsKey] = customModulesDictionary;
    }
    
    uploadDictionary[kMPRemoteConfigMPIDKey] = mpid;
    
    return self;
}

- (NSString *)description {
    NSString *description;
    
    if (_sessionId != nil) {
        description = [NSString stringWithFormat:@"MPUploadBuilder\n Session Id: %lld\n UploadDictionary: %@", self.sessionId.longLongValue, uploadDictionary];
    } else {
        description = [NSString stringWithFormat:@"MPUploadBuilder\n UploadDictionary: %@", uploadDictionary];
    }
    
    return description;
}

#pragma mark Public class methods
+ (nonnull MPUploadBuilder *)newBuilderWithMpid: (nonnull NSNumber *) mpid messages:(nonnull NSArray<MPMessage *> *)messages uploadInterval:(NSTimeInterval)uploadInterval dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion{
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithMpid:mpid sessionId:nil messages:messages sessionTimeout:0 uploadInterval:uploadInterval dataPlanId:dataPlanId dataPlanVersion:dataPlanVersion];
    return uploadBuilder;
}

+ (nonnull MPUploadBuilder *)newBuilderWithMpid: (nonnull NSNumber *) mpid sessionId:(nullable NSNumber *)sessionId messages:(nonnull NSArray<MPMessage *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval dataPlanId:(nullable NSString *)dataPlanId dataPlanVersion:(nullable NSNumber *)dataPlanVersion {
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithMpid:mpid sessionId:sessionId messages:messages sessionTimeout:sessionTimeout uploadInterval:uploadInterval dataPlanId:dataPlanId dataPlanVersion:dataPlanVersion];
    return uploadBuilder;
}

#pragma mark Public instance methods
- (void)build:(void (^)(MPUpload *upload))completionHandler {
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
    uploadDictionary[kMPMessageTypeKey] = kMPMessageTypeRequestHeader;
    uploadDictionary[kMPmParticleSDKVersionKey] = kMParticleSDKVersion;
    uploadDictionary[kMPMessageIdKey] = [[NSUUID UUID] UUIDString];
    uploadDictionary[kMPTimestampKey] = MPMilliseconds([[NSDate date] timeIntervalSince1970]);
    uploadDictionary[kMPApplicationKey] = stateMachine.apiKey;
    
    NSDictionary *appAndDeviceInfoDict = [[MParticle sharedInstance].persistenceController appAndDeviceInfoForSessionId:_sessionId];
    
    NSDictionary *appInfoDict = appAndDeviceInfoDict[kMPApplicationInformationKey];
    if (appInfoDict) {
        uploadDictionary[kMPApplicationInformationKey] = appInfoDict;
    } else {
        // If the info wasn't saved in the session, use the old behavior and grab it now
        // NOTE: This should only ever happen the first time after upgrading to the new schema if there are old sessions left
        MPApplication *application = [[MPApplication alloc] init];
        uploadDictionary[kMPApplicationInformationKey] = [application dictionaryRepresentation];
    }
    
    NSDictionary *deviceInfoDict = appAndDeviceInfoDict[kMPDeviceInformationKey];
    if (deviceInfoDict) {
        uploadDictionary[kMPDeviceInformationKey] = deviceInfoDict;
    } else {
        // If the info wasn't saved in the session, use the old behavior and grab it now
        // NOTE: This should only ever happen the first time after upgrading to the new schema if there are old sessions left
        MPDevice *device = [[MPDevice alloc] init];
        NSNumber *mpid = uploadDictionary[kMPRemoteConfigMPIDKey];
        uploadDictionary[kMPDeviceInformationKey] = [device dictionaryRepresentationWithMpid:mpid];
    }
    
    // Update the IDFA if it changed after the session was created/saved (the IDFA changed or the ATTStatus has been set to authorized)
    NSNumber *authStatus = [MParticle sharedInstance].stateMachine.attAuthorizationStatus;
    NSMutableArray *userIdentities = uploadDictionary[kMPUserIdentityArrayKey];
    NSString *advertiserId;
    for (NSMutableDictionary *userIdentityDictionary in userIdentities) {
        NSNumber *identityTypeKey = userIdentityDictionary[kMPUserIdentityTypeKey];
        if ([identityTypeKey isEqualToNumber:@(MPIdentityIOSAdvertiserId)]) {
            advertiserId = userIdentityDictionary[kMPUserIdentityIdKey];
        }
    }

    if (authStatus && advertiserId && authStatus.intValue == MPATTAuthorizationStatusAuthorized) {
        NSMutableDictionary *deviceInfoDictCopy = [uploadDictionary[kMPDeviceInformationKey] mutableCopy];
        deviceInfoDictCopy[kMPDeviceAdvertiserIdKey] = advertiserId;
        uploadDictionary[kMPDeviceInformationKey] = [deviceInfoDictCopy copy];
    }
    
    MPConsumerInfo *consumerInfo = stateMachine.consumerInfo;
    
    NSDictionary *cookies = [consumerInfo cookiesDictionaryRepresentation];
    if (cookies) {
        uploadDictionary[kMPRemoteConfigCookiesKey] = cookies;
    }
    
    NSString *deviceApplicationStamp = consumerInfo.deviceApplicationStamp;
    if (deviceApplicationStamp) {
        uploadDictionary[kMPDeviceApplicationStampKey] = deviceApplicationStamp;
    }
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
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
            uploadDictionary[kMPForwardStatsRecord] = fsr;
            [persistence deleteForwardRecordsIds:forwardRecordsIds];
        }
    }
    
    NSArray<MPIntegrationAttributes *> *integrationAttributesArray = [persistence fetchIntegrationAttributes];
    if (integrationAttributesArray) {
        NSMutableDictionary *integrationAttributesDictionary = [[NSMutableDictionary alloc] initWithCapacity:integrationAttributesArray.count];
        
        for (MPIntegrationAttributes *integrationAttributes in integrationAttributesArray) {
            [integrationAttributesDictionary addEntriesFromDictionary:[integrationAttributes dictionaryRepresentation]];
        }
        
        uploadDictionary[MPIntegrationAttributesKey] = integrationAttributesDictionary;
    }
    
    MPConsentState *consentState = [MPPersistenceController consentStateForMpid:uploadDictionary[kMPRemoteConfigMPIDKey]];
    if (consentState) {
        NSDictionary *consentStateDictionary = [MPConsentSerialization serverDictionaryFromConsentState:consentState];
        if (consentStateDictionary) {
            uploadDictionary[kMPConsentState] = consentStateDictionary;
        }
    }
    
    if (MParticle.sharedInstance.options.onCreateBatch != NULL) {
        NSDictionary *updatedDictionary = MParticle.sharedInstance.options.onCreateBatch(uploadDictionary);
        if (updatedDictionary == nil) {
            MPILogWarning(@"Not uploading batch due to 'onCreateBatch' handler returning 'nil'");
            return;
        } else if ([updatedDictionary isKindOfClass:[NSDictionary class]] && ![updatedDictionary isEqual:uploadDictionary]) {
            MPILogWarning(@"Replacing batch with mutated version from 'onCreateBatch' handler");
            uploadDictionary = [updatedDictionary mutableCopy];
            uploadDictionary[@"mb"] = @YES;
        }
    }
    
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:_sessionId uploadDictionary:uploadDictionary dataPlanId:dPId dataPlanVersion:dPVersion];
    upload.containsOptOutMessage = containsOptOutMessage;
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
            uploadDictionary[kMPUserAttributeKey] = userAttributesCopy;
        }
    }
    
    if (deletedUserAttributes.count > 0 && _sessionId) {
        uploadDictionary[kMPUserAttributeDeletedKey] = [deletedUserAttributes allObjects];
    }
    
    return self;
}

- (MPUploadBuilder *)withUserIdentities:(NSArray<NSDictionary<NSString *, id> *> *)userIdentities {
    if (userIdentities.count > 0) {
        uploadDictionary[kMPUserIdentityArrayKey] = userIdentities;
    }
    
    return self;
}

@end
