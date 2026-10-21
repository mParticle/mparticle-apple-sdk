#import "MPBackendController.h"
#import "MPPersistenceUtilities.h"
#import "MPIConstants.h"
#import "MPEvent.h"
#import "MPILogger.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "mParticle.h"
#import "MPUserDefaultsConnector.h"
#import "MPUploadSettings.h"
#import "MPNetworkCommunication.h"
#import "MParticleSession+MParticlePrivate.h"
@import mParticle_Apple_SDK_Swift;

// MPUserDefaultsConnector holds no state and reads MParticle.sharedInstance on every call.
static id<MPBackendHost> MPBackendHostInstance(void) {
    return (id<MPBackendHost>)[[MPUserDefaultsConnector alloc] init];
}

@implementation MPBackendController_PRIVATE (ObjCBoundary)

#pragma mark Initialization

- (instancetype)initWithDelegate:(id<MPBackendControllerDelegate>)delegate {
    id<MPBackendHost> host = MPBackendHostInstance();
    return [self initWithHost:host delegate:delegate persistence:[host openPersistence]];
}

- (instancetype)initWithDelegate:(id<MPBackendControllerDelegate>)delegate persistence:(id<MPBackendPersistence>)persistence {
    return [self initWithHost:MPBackendHostInstance() delegate:delegate persistence:persistence];
}

#pragma mark Network layer

- (MPNetworkCommunication_PRIVATE *)networkCommunication {
    return (MPNetworkCommunication_PRIVATE *)self.networkCommunicationStorage;
}

- (void)setNetworkCommunication:(MPNetworkCommunication_PRIVATE *)networkCommunication {
    self.networkCommunicationStorage = (id<MPBackendUploadNetworking>)networkCommunication;
}

#pragma mark Attribute validation and upload context

+ (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error  {
    return [MPBackendAttributeValidation checkKey:key value:value host:MPBackendHostInstance() error:error];
}

+ (MPUploadBuilderContext *)uploadBuilderContextWithPersistence:(id<MPUploadEnrichmentPersistence> (^)(void))persistence {
    return [[MPUploadBuilderContext alloc] initWithHost:MPBackendHostInstance() persistence:persistence];
}

// Objective-C because the persistence block may return nil, which the Swift context's closure type does not allow.
- (MPUploadBuilderContext *)uploadBuilderContext {
    return [MPBackendController_PRIVATE uploadBuilderContextWithPersistence:^{ return (id<MPUploadEnrichmentPersistence>)self.persistence; }];
}

#pragma mark Start-up

- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret networkOptions:(nullable MPNetworkOptions *)networkOptions firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType startKitsAsync:(BOOL)startKitsAsync consentState:(MPConsentState *)consentState completionHandler:(dispatch_block_t)completionHandler {
    MPConsentState *storedConsentState = [MPPersistenceUtilities consentStateForMpid:[MPPersistenceUtilities mpId]];
    if (consentState != nil && storedConsentState == nil) {
        [MPPersistenceUtilities setConsentState:consentState forMpid:[MPPersistenceUtilities mpId]];
    }

    [self.startupCoordinator startWithKey:apiKey
                                   secret:secret
                           networkOptions:networkOptions
                                 firstRun:firstRun
                         installationType:(MPInstallationTypeSwift)installationType
                           startKitsAsync:startKitsAsync
                        completionHandler:completionHandler];
}

- (void)prepareBatchesForUpload:(MPUploadSettings *)uploadSettings {
    [self.uploadCoordinator prepareBatchesForUpload:uploadSettings];
}

- (void)prepareBatchesForUploadSettings:(NSObject *)settings {
    [self prepareBatchesForUpload:(MPUploadSettings *)settings];
}

#pragma mark Pending session

- (MParticleSession *)tempSession {
    __block MParticleSession *pending;
    [self.sessionState withSessionLock:^{ pending = (MParticleSession *)self.pendingSessionStorage; }];
    return pending;
}

- (void)createPendingSessionWithUUID:(NSString *)uuid {
    self.pendingSessionStorage = [[MParticleSession alloc] initWithUUID:uuid];
}

- (void)setPendingSessionStartTime:(double)timestamp {
    ((MParticleSession *)self.pendingSessionStorage).startTime = @(timestamp);
}

- (void)clearPendingSession {
    self.pendingSessionStorage = nil;
}

#pragma mark Identities

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler {
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");

    MPBackendIdentityOutcome *outcome = [self.identityWriter setUserIdentity:identityString
                                                                identityType:(MPUserIdentitySwift)identityType
                                                                   timestamp:timestamp];
    completionHandler(outcome.value, (MPUserIdentity)outcome.type, outcome.status);
}

#pragma mark Events

- (void)beginTimedEvent:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    [event beginTiming];
    [self.eventSet addObject:event];
    completionHandler(event, MPExecStatusSuccess);
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", eventName];
    MPEvent *event = [[self.eventSet filteredSetUsingPredicate:predicate] anyObject];

    return event;
}

- (void)leaveBreadcrumb:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    event.messageType = MPMessageTypeBreadcrumb;
    [self.eventLogger saveEventMessageOfType:event.messageType
                                 messageInfo:[event breadcrumbDictionaryRepresentation]
                                   timestamp:event.timestamp
                           shouldUploadEvent:YES];

    if ([self.eventSet containsObject:event]) {
        [self.eventSet removeObject:event];
    }

    completionHandler(event, MPExecStatusSuccess);
}

- (void)logBaseEvent:(MPBaseEvent *)event completionHandler:(void (^)(MPBaseEvent *event, MPExecStatus execStatus))completionHandler {
    if (event.shouldBeginSession) {
        [self.eventLogger beginSessionForEventAtDate:event.timestamp];
    }
    if ([event isKindOfClass:[MPEvent class]] || [event isKindOfClass:[MPCommerceEvent class]]) {
        [self.eventLogger saveEventMessageOfType:event.messageType
                                     messageInfo:[event dictionaryRepresentation]
                                       timestamp:event.timestamp
                               shouldUploadEvent:event.shouldUploadEvent];
        MPILogDebug(@"Logged event: %@", event.dictionaryRepresentation);
    }

    completionHandler(event, MPExecStatusSuccess);
}

- (void)logEvent:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    event.messageType = MPMessageTypeEvent;

    [self logBaseEvent:event
     completionHandler:^(MPBaseEvent *baseEvent, MPExecStatus execStatus) {
         if ([self.eventSet containsObject:(MPEvent *)baseEvent]) {
             [self.eventSet removeObject:(MPEvent *)baseEvent];
         }

         completionHandler((MPEvent *)baseEvent, execStatus);
     }];
}

- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent completionHandler:(void (^)(MPCommerceEvent *commerceEvent, MPExecStatus execStatus))completionHandler {
    commerceEvent.messageType = MPMessageTypeCommerceEvent;

    [self logBaseEvent:commerceEvent
     completionHandler:^(MPBaseEvent *baseEvent, MPExecStatus execStatus) {
         completionHandler((MPCommerceEvent *)baseEvent, execStatus);
     }];
}

- (void)logScreen:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    event.messageType = MPMessageTypeScreenView;
    [event endTiming];
    if (event.type != MPEventTypeNavigation) {
        event.type = MPEventTypeNavigation;
    }

    [self.eventLogger saveEventMessageOfType:event.messageType
                                 messageInfo:[event screenDictionaryRepresentation]
                                   timestamp:event.timestamp
                           shouldUploadEvent:event.shouldUploadEvent];

    if ([self.eventSet containsObject:event]) {
        [self.eventSet removeObject:event];
    }

    completionHandler(event, MPExecStatusSuccess);
}

@end
