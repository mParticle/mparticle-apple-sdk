//
//  MPUploadBuilder.mm
//  mParticle
//
//  Created by Dalmo Cirne on 5/7/15.
//  Copyright (c) 2015 mParticle. All rights reserved.
//

#import "MPUploadBuilder.h"
#import "MPApplication.h"
#import "MPBags.h"
#import "MPBags+Internal.h"
#import "MPConsumerInfo.h"
#import "MPCustomModule.h"
#import "MPDevice.h"
#import "MPForwardRecord.h"
#import "MPIConstants.h"
#import "MPIntegrationAttributes.h"
#import "MPIUserDefaults.h"
#import "MPMessage.h"
#import "MPPersistenceController.h"
#import "MPSession.h"
#import "MPStateMachine.h"
#import "MPUpload.h"
#include <vector>

using namespace std;

@interface MPUploadBuilder() {
    NSMutableDictionary<NSString *, id> *uploadDictionary;
}

@end

@implementation MPUploadBuilder

- (instancetype)initWithSession:(MPSession *)session messages:(nonnull NSArray<__kindof MPMessage *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval {
    NSAssert(messages, @"Messages cannot be nil.");
    
    self = [super init];
    if (!self || !messages) {
        return nil;
    }

    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    _session = session ? session : stateMachine.nullSession;
    
    NSUInteger numberOfMessages = messages.count;
    NSMutableArray *messageDictionaries = [[NSMutableArray alloc] initWithCapacity:numberOfMessages];
    _preparedMessageIds = [[NSMutableArray alloc] initWithCapacity:numberOfMessages];

    [messages enumerateObjectsUsingBlock:^(MPMessage *message, NSUInteger idx, BOOL *stop) {
        [_preparedMessageIds addObject:@(message.messageId)];
        
        NSDictionary *messageDictionaryRepresentation = [message dictionaryRepresentation];
        if (messageDictionaryRepresentation) {
            [messageDictionaries addObject:messageDictionaryRepresentation];
        }
    }];
    
    NSNumber *ltv;
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    ltv = userDefaults[kMPLifeTimeValueKey];
    if (!ltv) {
        ltv = @0;
    }
    
    uploadDictionary = [@{kMPOptOutKey:@(stateMachine.optOut),
                          kMPUploadIntervalKey:@(uploadInterval),
                          kMPLifeTimeValueKey:ltv}
                        mutableCopy];

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
    
    uploadDictionary[kMPRemoteConfigMPIDKey] = stateMachine.consumerInfo.mpId;
    
    return self;
}

#pragma mark Public class methods
+ (MPUploadBuilder *)newBuilderWithSession:(MPSession *)session messages:(nonnull NSArray<__kindof MPMessage *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval {
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithSession:session messages:messages sessionTimeout:sessionTimeout uploadInterval:uploadInterval];
    return uploadBuilder;
}

#pragma mark Public instance methods
- (nonnull MPUpload *)build {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    uploadDictionary[kMPMessageTypeKey] = kMPMessageTypeRequestHeader;
    uploadDictionary[kMPmParticleSDKVersionKey] = kMParticleSDKVersion;
    uploadDictionary[kMPMessageIdKey] = [[NSUUID UUID] UUIDString];
    uploadDictionary[kMPTimestampKey] = MPMilliseconds([[NSDate date] timeIntervalSince1970]);
    uploadDictionary[kMPApplicationKey] = stateMachine.apiKey;
    
    MPApplication *application = [[MPApplication alloc] init];
    uploadDictionary[kMPApplicationInformationKey] = [application dictionaryRepresentation];
    
    MPDevice *device = [[MPDevice alloc] init];
    uploadDictionary[kMPDeviceInformationKey] = [device dictionaryRepresentation];
    
    NSDictionary *cookies = [stateMachine.consumerInfo cookiesDictionaryRepresentation];
    if (cookies) {
        uploadDictionary[kMPRemoteConfigCookiesKey] = cookies;
    }
    
    NSDictionary *productBags = [stateMachine.bags dictionaryRepresentation];
    if (productBags) {
        uploadDictionary[kMPProductBagKey] = productBags;
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
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
    
#ifdef SERVER_ECHO
    uploadDictionary[@"echo"] = @true;
#endif
    
    MPUpload *upload = [[MPUpload alloc] initWithSession:_session uploadDictionary:uploadDictionary];
    
    [persistence deleteForwardRecordsIds:forwardRecordsIds];
    
    return upload;
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
    
    if (deletedUserAttributes.count > 0 && _session) {
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
