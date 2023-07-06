//
//  MPEventLogging.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import "MPEventLogging.h"
#import "MPBackendController.h"
#import "MPAppDelegateProxy.h"
#import "MPPersistenceController.h"
#import "MPMessage.h"
#import "MPSession.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPNetworkPerformance.h"
#import "MPIUserDefaults.h"
#import "MPBreadcrumb.h"
#import "MPUpload.h"
#import "MPApplication.h"
#import "MPCustomModule.h"
#import "MPMessageBuilder.h"
#import "MPEvent.h"
#import "MParticleUserNotification.h"
#import "NSDictionary+MPCaseInsensitive.h"
//#import "MPHasher.h"
#import "MPUploadBuilder.h"
#import "MPILogger.h"
#import "MPResponseEvents.h"
#import "MPConsumerInfo.h"
#import "MPResponseConfig.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPKitContainer.h"
#import "MPUserAttributeChange.h"
#import "MPUserIdentityChange.h"
#import "MPSearchAdsAttribution.h"
#import "MPURLRequestBuilder.h"
#import "MPArchivist.h"
#import "MPListenerController.h"
#import "MParticleWebView.h"
#import "MPDevice.h"

@interface MParticle()
@property (nonatomic, strong, nonnull) MPBackendController *backendController;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPPersistenceController *persistenceController;
@end

@implementation MPEventLogging

- (MPBackendController *)backendController {
    return [MParticle sharedInstance].backendController;
}

- (NSMutableSet<MPEvent *> *)eventSet {
    if (_eventSet) {
        return _eventSet;
    }
    
    _eventSet = [[NSMutableSet alloc] initWithCapacity:1];
    return _eventSet;
}

- (void)logEvent:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];
    
     event.messageType = MPMessageTypeEvent;

    [self logBaseEvent:event
     completionHandler:^(MPBaseEvent *baseEvent, MPExecStatus execStatus) {
         if ([self.eventSet containsObject:(MPEvent *)baseEvent]) {
             [self->_eventSet removeObject:(MPEvent *)baseEvent];
         }

         completionHandler((MPEvent *)baseEvent, execStatus);
     }];
}

- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent completionHandler:(void (^)(MPCommerceEvent *commerceEvent, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd  parameter1:commerceEvent];
    
    commerceEvent.messageType = MPMessageTypeCommerceEvent;
    
    [self logBaseEvent:commerceEvent
     completionHandler:^(MPBaseEvent *baseEvent, MPExecStatus execStatus) {
         completionHandler((MPCommerceEvent *)baseEvent, execStatus);
     }];
}

- (void)logNetworkPerformanceMeasurement:(MPNetworkPerformance *)networkPerformance completionHandler:(void (^)(MPNetworkPerformance *networkPerformance, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:networkPerformance];
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSDictionary *messageInfo = [networkPerformance dictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeNetworkPerformance session:self.backendController.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
    MPMessage *message = [messageBuilder build];
    
    [self.backendController saveMessage:message updateSession:YES];
    
    execStatus = MPExecStatusSuccess;
    
    if (completionHandler) {
        completionHandler(networkPerformance, execStatus);
    }
}

- (void)leaveBreadcrumb:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd  parameter1:event];
    
    event.messageType = MPMessageTypeBreadcrumb;
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSDictionary *messageInfo = [event breadcrumbDictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.backendController.session messageInfo:messageInfo];
    if (event.timestamp) {
        [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
    }
    MPMessage *message = [messageBuilder build];
    
    [self.backendController saveMessage:message updateSession:YES];
    
    if ([self.eventSet containsObject:event]) {
        [_eventSet removeObject:event];
    }
    
    [self.backendController.session incrementCounter];
    
    execStatus = MPExecStatusSuccess;

    completionHandler(event, execStatus);
}

- (void)logError:(NSString *)message exception:(NSException *)exception topmostContext:(id)topmostContext eventInfo:(NSDictionary *)eventInfo completionHandler:(void (^)(NSString *message, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:message parameter2:exception parameter3:topmostContext parameter4:eventInfo];
    
    NSString *execMessage = exception ? exception.name : message;
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSMutableDictionary *messageInfo = [@{kMPCrashWasHandled:@"true", kMPCrashingSeverity:@"error"} mutableCopy];
    if (exception) {
        messageInfo[kMPErrorMessage] = exception.reason;
        messageInfo[kMPCrashingClass] = exception.name;
        
        NSArray *callStack = [exception callStackSymbols];
        if (callStack) {
            messageInfo[kMPStackTrace] = [callStack componentsJoinedByString:@"\n"];
        }
        
        NSArray<MPBreadcrumb *> *fetchedbreadcrumbs = [[MParticle sharedInstance].persistenceController fetchBreadcrumbs];
        if (fetchedbreadcrumbs) {
            NSMutableArray *breadcrumbs = [[NSMutableArray alloc] initWithCapacity:fetchedbreadcrumbs.count];
            for (MPBreadcrumb *breadcrumb in fetchedbreadcrumbs) {
                [breadcrumbs addObject:[breadcrumb dictionaryRepresentation]];
            }
            
            NSString *messageTypeBreadcrumbKey = kMPMessageTypeStringBreadcrumb;
            messageInfo[messageTypeBreadcrumbKey] = breadcrumbs;
        }
    } else {
        messageInfo[kMPErrorMessage] = message;
    }
    
    if (topmostContext) {
        messageInfo[kMPTopmostContext] = [[topmostContext class] description];
    }
    
    if (eventInfo.count > 0) {
        messageInfo[kMPAttributesKey] = eventInfo;
    }
    
    NSDictionary *appImageInfo = [MPApplication appImageInfo];
    if (appImageInfo) {
        [messageInfo addEntriesFromDictionary:appImageInfo];
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCrashReport session:self.backendController.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
    MPMessage *errorMessage = [messageBuilder build];
    
    [self.backendController saveMessage:errorMessage updateSession:YES];
    
    execStatus = MPExecStatusSuccess;
    
    completionHandler(execMessage, execStatus);
}

-  (void)logCrash:(NSString *)message stackTrace:(NSString *)stackTrace plCrashReport:(NSString *)plCrashReport completionHandler:(void (^)(NSString *message, MPExecStatus execStatus)) completionHandler
{
    NSString *execMessage = message ? message : @"Crash Report";
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSMutableDictionary *messageInfo = [@{
        kMPCrashingSeverity: @"fatal",
        kMPCrashWasHandled: @"false"
    } mutableCopy];
    
    if(message) {
        messageInfo[kMPErrorMessage] = message;
    }
    
    NSData* data = [plCrashReport dataUsingEncoding:NSUTF8StringEncoding];
    NSNumber *maxPLCrashBytesNumber = [MParticle sharedInstance].stateMachine.crashMaxPLReportLength;
    if (maxPLCrashBytesNumber != nil) {
        NSInteger maxPLCrashBytes = maxPLCrashBytesNumber.integerValue;
        if (data.length > maxPLCrashBytes) {
            NSInteger bytesToTruncate = data.length - maxPLCrashBytes;
            NSInteger bytesRemaining = data.length - bytesToTruncate;
            data = [data subdataWithRange:NSMakeRange(0, bytesRemaining)];
        }
    }
    NSString *plCrashReportBase64 = [data base64EncodedStringWithOptions:0];
    if(plCrashReportBase64) {
        messageInfo[kMPPLCrashReport] = plCrashReportBase64;
    }
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    NSArray<MPBreadcrumb *> *fetchedbreadcrumbs = [persistence fetchBreadcrumbs];
    if (fetchedbreadcrumbs) {
        NSMutableArray *breadcrumbs = [[NSMutableArray alloc] initWithCapacity:fetchedbreadcrumbs.count];
        for (MPBreadcrumb *breadcrumb in fetchedbreadcrumbs) {
            [breadcrumbs addObject:[breadcrumb dictionaryRepresentation]];
        }
        messageInfo[kMPMessageTypeLeaveBreadcrumbs] = breadcrumbs;
    }
    
    if(stackTrace) {
        messageInfo[kMPStackTrace] = stackTrace;
    }

    MPSession *crashSession = nil;
    NSArray<MPSession *> *sessions = [[MParticle sharedInstance].persistenceController fetchPossibleSessionsFromCrash];
    for (MPSession *session in sessions) {
        if (![session isEqual:self.backendController.session]) {
            crashSession = session;
            break;
        }
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCrashReport session:crashSession messageInfo:messageInfo];
    MPMessage *crashMessage = [messageBuilder build];
    
    NSInteger maxBytes = [MPPersistenceController maxBytesPerEvent:crashMessage.messageType];
    if(crashMessage.messageData.length > maxBytes) {
        NSInteger bytesToTruncate = crashMessage.messageData.length - maxBytes;
        NSInteger bytesToRetain = plCrashReportBase64.length - bytesToTruncate;
        [crashMessage truncateMessageDataProperty:kMPPLCrashReport toLength:bytesToRetain];
    }
    [persistence saveMessage:crashMessage];
    
    execStatus = MPExecStatusSuccess;
    completionHandler(execMessage, execStatus);
}

- (void)logBaseEvent:(MPBaseEvent *)event completionHandler:(void (^)(MPBaseEvent *event, MPExecStatus execStatus))completionHandler {
    if (![MPStateMachine canWriteMessagesToDB]) {
        MPILogError(@"Not saving message for event to prevent excessive local database growth because API Key appears to be invalid based on server response");
        completionHandler(event, MPExecStatusFail);
        return;
    }
    
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];
    
    if (event.shouldBeginSession) {
        NSDate *date = event.timestamp ?: [NSDate date];
        [self.backendController beginSessionWithIsManual:!MParticle.sharedInstance.automaticSessionTracking date:date];
    }
    if ([event isKindOfClass:[MPEvent class]] || [event isKindOfClass:[MPCommerceEvent class]]) {
        NSDictionary<NSString *, id> *messageInfo = [event dictionaryRepresentation];
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.backendController.session messageInfo:messageInfo];
            if (event.timestamp) {
                [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
            }
        #if TARGET_OS_IOS == 1
        #ifndef MPARTICLE_LOCATION_DISABLE
            messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
        #endif
        #endif
            MPMessage *message = [messageBuilder build];
            message.shouldUploadEvent = event.shouldUploadEvent;
            
            [self.backendController saveMessage:message updateSession:YES];
            
            [self.backendController.session incrementCounter];
            
            MPILogDebug(@"Logged event: %@", event.dictionaryRepresentation);
    }
    
    completionHandler(event, MPExecStatusSuccess);
}

- (void)logScreen:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];
    
    event.messageType = MPMessageTypeScreenView;

    MPExecStatus execStatus = MPExecStatusFail;

    [event endTiming];
    
    if (event.type != MPEventTypeNavigation) {
        event.type = MPEventTypeNavigation;
    }
    
    NSDictionary *messageInfo = [event screenDictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.backendController.session messageInfo:messageInfo];
    if (event.timestamp) {
        [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
    }
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
    MPMessage *message = [messageBuilder build];
    message.shouldUploadEvent = event.shouldUploadEvent;
    
    [self.backendController saveMessage:message updateSession:YES];
    
    if ([self.eventSet containsObject:event]) {
        [_eventSet removeObject:event];
    }
    
    [self.backendController.session incrementCounter];
    
    execStatus = MPExecStatusSuccess;
    
    completionHandler(event, execStatus);
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", eventName];
    MPEvent *event = [[self.eventSet filteredSetUsingPredicate:predicate] anyObject];
    
    return event;
}

@end
