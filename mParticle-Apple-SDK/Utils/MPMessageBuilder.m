#import "MPMessageBuilder.h"
#import "MPStateMachine.h"
#import <UIKit/UIKit.h>
#import "MPEnums.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPILogger.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPPersistenceController.h"
#import "mParticle.h"

@import mParticle_Apple_SDK_Swift;

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
    NSString *string = [MPMessageBuilderFields stringForMessageTypeRawValue:type];
    if (!string) {
        MPILogError(@"Unknown message type enum: %@", @(type));
        return kMPMessageTypeStringUnknown;
    }

    return string;
}

+ (MPMessageType)messageTypeForString:(NSString *)string {
    NSNumber *rawType = [MPMessageBuilderFields rawMessageTypeForString:string];
    if (rawType == nil) {
        MPILogError(@"Unknown message type string: %@", string);
        return MPMessageTypeUnknown;
    }

    return (MPMessageType)rawType.unsignedIntegerValue;
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
                NSArray<NSNumber *> *userIdNumbers = [MPMessageBuilderFields filteredUserIdsFrom:_session.sessionUserIds];
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
            UIWindow *keyWindow = nil;
            
            // Get key window from active window scene (iOS 13+)
            NSSet<UIScene *> *connectedScenes = [MPApplication_PRIVATE sharedUIApplication].connectedScenes;
            for (UIScene *scene in connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *window in windowScene.windows) {
                        if (window.isKeyWindow) {
                            keyWindow = window;
                            break;
                        }
                    }
                    if (keyWindow) {
                        break;
                    }
                }
            }
            
            UIViewController *presentedViewController = keyWindow.rootViewController.presentedViewController;
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

- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session userIdentityChange:(MPUserIdentityChangePRIVATE *)userIdentityChange {
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
    id oldValue = userAttributeChange.userAttributes[userAttributeChange.key];
    MPUserAttributeChangeFields *fields = [MPMessageBuilderFields userAttributeChangeFieldsWithDeleted:userAttributeChange.deleted
                                                                                                     key:userAttributeChange.key
                                                                                                oldValue:oldValue
                                                                                                newValue:userAttributeChange.valueToLog];

    _messageDictionary[kMPUserAttributeWasDeletedKey] = @(fields.deleted);
    _messageDictionary[kMPEventNameKey] = fields.attributeKey;
    _messageDictionary[kMPUserAttributeOldValueKey] = fields.oldValue;
    _messageDictionary[kMPUserAttributeNewValueKey] = fields.newValue;
    _messageDictionary[kMPUserAttributeNewlyAddedKey] = @(fields.newlyAdded);
}

- (void)userIdentityChange:(MPUserIdentityChangePRIVATE *)userIdentityChange {
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
    NSString *launchInfoString = [MPMessageBuilderFields launchInfoStringFrom:launchInfo];
    if (launchInfoString) {
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

    MPStateTransitionFields *fields = [MPMessageBuilderFields stateTransitionFieldsWithSourceApplication:stateMachine.launchInfo.sourceApplication
                                                                                           launchURLString:stateMachine.launchInfo.url.absoluteString
                                                                                          launchParameters:stateMachine.launchInfo.annotation
                                                                             previousSessionInterruptions:previousSession ? previousSession.numberOfInterruptions : 0
                                                                                         sessionFinalized:sessionFinalized];

    if (fields.sourceApplication) {
        _messageDictionary[kMPLaunchSourceKey] = fields.sourceApplication;
    }

    if (fields.launchURLString) {
        _messageDictionary[kMPLaunchURLKey] = fields.launchURLString;
    }

    if (fields.launchParameters) {
        _messageDictionary[kMPLaunchParametersKey] = fields.launchParameters;
    }

    _messageDictionary[kMPLaunchNumberOfSessionInterruptionsKey] = @(fields.numberOfSessionInterruptions);
    _messageDictionary[kMPLaunchSessionFinalizedKey] = @(fields.sessionFinalized);
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

@end
