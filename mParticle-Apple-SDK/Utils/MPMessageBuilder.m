#import "MPMessageBuilder.h"
#import "MPSession.h"
#import "MPMessage.h"
#import "MPStateMachine.h"
#import <UIKit/UIKit.h>
#import "MPEnums.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPILogger.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPPersistenceController.h"
#import "MPApplication.h"
#import "mParticle.h"
#import "MParticleSwift.h"

NSString *const launchInfoStringFormat = @"%@%@%@=%@";
NSString *const kMPHorizontalAccuracyKey = @"acc";
NSString *const kMPLatitudeKey = @"lat";
NSString *const kMPLongitudeKey = @"lng";
NSString *const kMPVerticalAccuracyKey = @"vacc";
NSString *const kMPRequestedAccuracy = @"racc";
NSString *const kMPDistanceFilter = @"mdst";
NSString *const kMPIsForegroung = @"fg";
NSString *const kMPUserAttributeWasDeletedKey = @"d";
NSString *const kMPUserAttributeNewValueKey = @"nv";
NSString *const kMPUserAttributeOldValueKey = @"ov";
NSString *const kMPUserAttributeNewlyAddedKey = @"na";
NSString *const kMPUserIdentityNewValueKey = @"ni";
NSString *const kMPUserIdentityOldValueKey = @"oi";

@interface MParticle ()
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
@end

@interface MPMessageBuilder ()
@property (atomic, strong) NSMutableDictionary<NSString *, id> *messageDictionary;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic) MPMessageType messageTypeValue;
@end

@implementation MPMessageBuilder

+ (NSString *)stringForMessageType:(MPMessageType)type {
    NSString *string = kMPMessageTypeStringUnknown;
    
    switch (type) {
        case MPMessageTypeUnknown:                      string = kMPMessageTypeStringUnknown; break;
        case MPMessageTypeSessionStart:                 string = kMPMessageTypeStringSessionStart; break;
        case MPMessageTypeSessionEnd:                   string = kMPMessageTypeStringSessionEnd; break;
        case MPMessageTypeScreenView:                   string = kMPMessageTypeStringScreenView; break;
        case MPMessageTypeEvent:                        string = kMPMessageTypeStringEvent; break;
        case MPMessageTypeCrashReport:                  string = kMPMessageTypeStringCrashReport; break;
        case MPMessageTypeOptOut:                       string = kMPMessageTypeStringOptOut; break;
        case MPMessageTypeFirstRun:                     string = kMPMessageTypeStringFirstRun; break;
        case MPMessageTypePreAttribution:               string = kMPMessageTypeStringPreAttribution; break;
        case MPMessageTypePushRegistration:             string = kMPMessageTypeStringPushRegistration; break;
        case MPMessageTypeAppStateTransition:           string = kMPMessageTypeStringAppStateTransition; break;
        case MPMessageTypePushNotification:             string = kMPMessageTypeStringPushNotification; break;
        case MPMessageTypeNetworkPerformance:           string = kMPMessageTypeStringNetworkPerformance; break;
        case MPMessageTypeBreadcrumb:                   string = kMPMessageTypeStringBreadcrumb; break;
        case MPMessageTypeProfile:                      string = kMPMessageTypeStringProfile; break;
        case MPMessageTypePushNotificationInteraction:  string = kMPMessageTypeStringPushNotificationInteraction; break;
        case MPMessageTypeCommerceEvent:                string = kMPMessageTypeStringCommerceEvent; break;
        case MPMessageTypeUserAttributeChange:          string = kMPMessageTypeStringUserAttributeChange; break;
        case MPMessageTypeUserIdentityChange:           string = kMPMessageTypeStringUserIdentityChange; break;
        case MPMessageTypeMedia:                        string = kMPMessageTypeStringMedia; break;
        default:
            string = kMPMessageTypeStringUnknown;
            MPILogError(@"Unknown message type enum: %@", @(type));
            break;
    }
    
    return string;
}

+ (MPMessageType)messageTypeForString:(NSString *)string {
    MPMessageType type = MPMessageTypeUnknown;
        
    if ([string isEqual:kMPMessageTypeStringUnknown]) {
        type = MPMessageTypeUnknown;
    } else if ([string isEqual:kMPMessageTypeStringSessionStart]) {
        type = MPMessageTypeSessionStart;
    } else if ([string isEqual:kMPMessageTypeStringSessionEnd]) {
        type = MPMessageTypeSessionEnd;
    } else if ([string isEqual:kMPMessageTypeStringScreenView]) {
        type = MPMessageTypeScreenView;
    } else if ([string isEqual:kMPMessageTypeStringEvent]) {
        type = MPMessageTypeEvent;
    } else if ([string isEqual:kMPMessageTypeStringCrashReport]) {
        type = MPMessageTypeCrashReport;
    } else if ([string isEqual:kMPMessageTypeStringOptOut]) {
        type = MPMessageTypeOptOut;
    } else if ([string isEqual:kMPMessageTypeStringFirstRun]) {
        type = MPMessageTypeFirstRun;
    } else if ([string isEqual:kMPMessageTypeStringPreAttribution]) {
        type = MPMessageTypePreAttribution;
    } else if ([string isEqual:kMPMessageTypeStringPushRegistration]) {
        type = MPMessageTypePushRegistration;
    } else if ([string isEqual:kMPMessageTypeStringAppStateTransition]) {
        type = MPMessageTypeAppStateTransition;
    } else if ([string isEqual:kMPMessageTypeStringPushNotification]) {
        type = MPMessageTypePushNotification;
    } else if ([string isEqual:kMPMessageTypeStringNetworkPerformance]) {
        type = MPMessageTypeNetworkPerformance;
    } else if ([string isEqual:kMPMessageTypeStringBreadcrumb]) {
        type = MPMessageTypeBreadcrumb;
    } else if ([string isEqual:kMPMessageTypeStringProfile]) {
        type = MPMessageTypeProfile;
    } else if ([string isEqual:kMPMessageTypeStringPushNotificationInteraction]) {
        type = MPMessageTypePushNotificationInteraction;
    } else if ([string isEqual:kMPMessageTypeStringCommerceEvent]) {
        type = MPMessageTypeCommerceEvent;
    } else if ([string isEqual:kMPMessageTypeStringUserAttributeChange]) {
        type = MPMessageTypeUserAttributeChange;
    } else if ([string isEqual:kMPMessageTypeStringUserIdentityChange]) {
        type = MPMessageTypeUserIdentityChange;
    } else if ([string isEqual:kMPMessageTypeStringMedia]) {
        type = MPMessageTypeMedia;
    } else {
        MPILogError(@"Unknown message type string: %@", string);
    }
    
    return type;
}

- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session {
    self = [super init];
    if (!self || !messageType) {
        return nil;
    }
    
    _timestamp = [[NSDate date] timeIntervalSince1970];
    _messageDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
    _messageDictionary[kMPTimestampKey] = MPMilliseconds(_timestamp);
    
    _messageTypeValue = messageType;
    _messageType = [MPMessageBuilder stringForMessageType:messageType];
    
    _session = session;
    if (session) {
        if (messageType == MPMessageTypeSessionStart) {
            _uuid = _session.uuid;
        } else {
            _messageDictionary[kMPSessionIdKey] = _session.uuid;
            _messageDictionary[kMPSessionStartTimestamp] = MPMilliseconds(_session.startTime);
            
            if (messageType == MPMessageTypeSessionEnd) {
                NSArray *userIds = [_session.sessionUserIds componentsSeparatedByString:@","];
                
                NSMutableArray *userIdNumbers = [NSMutableArray array];
                [userIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSNumber *userId = @(obj.longLongValue);
                    if (userId && ![userId isEqual:@0]) {
                        [userIdNumbers addObject:userId];
                    }
                    
                }];
                
                if (userIdNumbers) {
                    _messageDictionary[kMPSessionUserIdsKey] = userIdNumbers;
                }
            }
        }
    }
    
    _dataPlanId = [MParticle sharedInstance].dataPlanId;
    _dataPlanVersion = [MParticle sharedInstance].dataPlanVersion;
    
    NSString *presentedViewControllerDescription = nil;
    NSNumber *mainThreadFlag;
    if ([NSThread isMainThread]) {
        if (![MPStateMachine_PRIVATE isAppExtension]) {
            UIViewController *presentedViewController = [MPApplication_PRIVATE sharedUIApplication].keyWindow.rootViewController.presentedViewController;
            presentedViewControllerDescription = presentedViewController ? [[presentedViewController class] description] : nil;
        } else {
            presentedViewControllerDescription = @"extension_message";
        }
        
        mainThreadFlag = @YES;
    } else {
        presentedViewControllerDescription = @"off_thread";
        mainThreadFlag = @NO;
    }
    
    if (presentedViewControllerDescription) {
        _messageDictionary[kMPPresentedViewControllerKey] = presentedViewControllerDescription;
    }
    _messageDictionary[kMPMainThreadKey] = mainThreadFlag;
    
    return self;
}

- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session messageInfo:(NSDictionary<NSString *, id> *)messageInfo {
    self = [self initWithMessageType:messageType session:session];
    if (self && messageInfo) {
        [_messageDictionary addEntriesFromDictionary:messageInfo];
        
        NSDictionary *messageAttributes = _messageDictionary[kMPAttributesKey];
        if (messageAttributes) {
            _messageDictionary[kMPAttributesKey] = [messageAttributes transformValuesToString];
        }
    }
    return self;
}

- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session userIdentityChange:(MPUserIdentityChange_PRIVATE *)userIdentityChange {
    self = [self initWithMessageType:messageType session:session];
    if (self && userIdentityChange) {
        [self userIdentityChange:userIdentityChange];
    }
    return self;
}

- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session userAttributeChange:(MPUserAttributeChange *)userAttributeChange {
    self = [self initWithMessageType:messageType session:session];
    if (self && userAttributeChange) {
        [self userAttributeChange:userAttributeChange];
    }
    return self;
}

#pragma mark Private methods
- (void)userAttributeChange:(nonnull MPUserAttributeChange *)userAttributeChange {
    _messageDictionary[kMPUserAttributeWasDeletedKey] = userAttributeChange.deleted ? @YES : @NO;
    _messageDictionary[kMPEventNameKey] = userAttributeChange.key;
    
    id oldValue = userAttributeChange.userAttributes[userAttributeChange.key];
    _messageDictionary[kMPUserAttributeOldValueKey] = oldValue ? oldValue : [NSNull null];
    _messageDictionary[kMPUserAttributeNewValueKey] = userAttributeChange.valueToLog && !userAttributeChange.deleted ? userAttributeChange.valueToLog : [NSNull null];
    _messageDictionary[kMPUserAttributeNewlyAddedKey] = oldValue ? @NO : @YES;
}

- (void)userIdentityChange:(MPUserIdentityChange_PRIVATE *)userIdentityChange {
    NSDictionary *dictionary = [userIdentityChange.newUserIdentity dictionaryRepresentation];
    if (dictionary) {
        _messageDictionary[kMPUserIdentityNewValueKey] = dictionary;
    }
    
    dictionary = [userIdentityChange.oldUserIdentity dictionaryRepresentation];
    if (dictionary) {
        _messageDictionary[kMPUserIdentityOldValueKey] = dictionary;
    }
}

#pragma mark Public instance methods
- (NSDictionary *)messageInfo {
    return _messageDictionary;
}

- (void)launchInfo:(NSDictionary *)launchInfo {
    NSString *launchScheme = [launchInfo[UIApplicationLaunchOptionsURLKey] absoluteString];
    NSString *launchSource = launchInfo[UIApplicationLaunchOptionsSourceApplicationKey];
    
    if (launchScheme && launchSource) {
        NSRange range = [launchScheme rangeOfString:@"?"];
        NSString *sourcePrefix = (range.length > 0) ? @"&" : @"?";
        
        NSString *launchInfoString = [NSString stringWithFormat:launchInfoStringFormat, launchScheme, sourcePrefix, kMPLaunchSourceKey, launchSource];
        _messageDictionary[kMPLaunchURLKey] = launchInfoString;
    }
}

- (void)timestamp:(NSTimeInterval)timestamp {
    _timestamp = timestamp;
    _messageDictionary[kMPTimestampKey] = MPMilliseconds(_timestamp);
}

// NOTE: Here "sessionFinalized" is really referring to if we are starting a new session on launch, see Facebook event forwarder backend code
- (void)stateTransition:(BOOL)sessionFinalized previousSession:(MPSession *)previousSession {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    if (stateMachine.launchInfo.sourceApplication) {
        _messageDictionary[kMPLaunchSourceKey] = stateMachine.launchInfo.sourceApplication;
    }
    
    if (stateMachine.launchInfo.url) {
        _messageDictionary[kMPLaunchURLKey] = [stateMachine.launchInfo.url absoluteString];
    }
    
    if (stateMachine.launchInfo.annotation) {
        _messageDictionary[kMPLaunchParametersKey] = stateMachine.launchInfo.annotation;
    }
    
    _messageDictionary[kMPLaunchNumberOfSessionInterruptionsKey] = previousSession ? @(previousSession.numberOfInterruptions) : @0;
    _messageDictionary[kMPLaunchSessionFinalizedKey] = @(sessionFinalized);
}

- (MPMessage *)build {
    _messageDictionary[kMPMessageTypeKey] = _messageType;
    _messageDictionary[kMPMessageIdKey] = _uuid ?: [[NSUUID UUID] UUIDString];
    
    NSNumber *userId = _session.userId.integerValue ? _session.userId : [MPPersistenceController_PRIVATE mpId];

    MPMessage *message = [[MPMessage alloc] initWithSession:_session
                                                messageType:_messageType
                                                messageInfo:[_messageDictionary copy]
                                               uploadStatus:MPUploadStatusBatch
                                                       UUID:_messageDictionary[kMPMessageIdKey]
                                                  timestamp:_timestamp
                                                     userId:userId
                                                 dataPlanId:_dataPlanId
                                            dataPlanVersion:_dataPlanVersion];
    return message;
}

#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
- (void)location:(CLLocation *)location {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    if ([MPStateMachine_PRIVATE runningInBackground] && !stateMachine.locationManager.backgroundLocationTracking) {
        return;
    }
    
    BOOL isCrashReport = _messageTypeValue == MPMessageTypeCrashReport;
    BOOL isOptOutMessage = _messageTypeValue == MPMessageTypeOptOut;
    
    if (location && !isCrashReport && !isOptOutMessage) {
        _messageDictionary[kMPLocationKey] = @{kMPHorizontalAccuracyKey:@(location.horizontalAccuracy),
                                              kMPVerticalAccuracyKey:@(location.verticalAccuracy),
                                              kMPLatitudeKey:@(location.coordinate.latitude),
                                              kMPLongitudeKey:@(location.coordinate.longitude),
                                              kMPRequestedAccuracy:@(stateMachine.locationManager.requestedAccuracy),
                                              kMPDistanceFilter:@(stateMachine.locationManager.requestedDistanceFilter),
                                              kMPIsForegroung:@(!stateMachine.backgrounded)};
    }
}
#endif
#endif

@end
