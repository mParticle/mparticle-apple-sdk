//
//  MParticleShim.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import "MParticleShim.h"
#import "MParticle.h"
#import "MPEvent.h"
#import "MPILogger.h"
#import "MPDataPlanFilter.h"
#import "MPKitContainer.h"
#import "MPForwardQueueParameters.h"
#import "MPIConstants.h"

NSString *const kMPMethodName = @"$MethodName";

@interface MParticle()
@property (nonatomic, strong) MPDataPlanFilter *dataPlanFilter;
@property (nonatomic, strong) MPKitContainer *kitContainer;
+ (dispatch_queue_t)messageQueue;
@end

@implementation MParticleShim

- (instancetype)initWithInstance:(MParticle *)mpInstance {
    if (self = [super init]) {
        _mpInstance = mpInstance;
    }
    return self;
}

- (void)logEvent:(MPBaseEvent *)event {
    if (event == nil) {
        MPILogError(@"Cannot log nil event!");
    } else if ([event isKindOfClass:[MPEvent class]]) {
        [self logCustomEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self logCommerceEvent:(MPCommerceEvent *)event];
#pragma clang diagnostic pop
    } else {
        dispatch_async([MParticle messageQueue], ^{
            [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];
            
            [[MParticle sharedInstance].mediator.eventLogging logBaseEvent:event
                               completionHandler:^(MPBaseEvent *event, MPExecStatus execStatus) {
                               }];
            MPBaseEvent *kitEvent = self->_mpInstance.dataPlanFilter != nil ? [self->_mpInstance.dataPlanFilter transformEventForBaseEvent:event] : event;
            if (kitEvent) {
            // Forwarding calls to kits
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_mpInstance.kitContainer forwardSDKCall:@selector(logBaseEvent:)
                                                                  event:kitEvent
                                                             parameters:nil
                                                            messageType:kitEvent.messageType
                                                               userInfo:nil
                 ];
            });
            } else {
                MPILogDebug(@"Blocked base event from kits: %@", event);
            }
        });
    }
}

- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    MPEvent *event = [_mpInstance.mediator.eventLogging eventWithName:eventName];
    if (event) {
        event.type = eventType;
    } else {
        event = [[MPEvent alloc] initWithName:eventName type:eventType];
    }
    
    event.customAttributes = eventInfo;
    [self logEvent:event];
}

- (void)logScreenEvent:(MPEvent *)event {
    if (event == nil) {
        MPILogError(@"Cannot log nil screen event!");
        return;
    }
    if (!event.timestamp) {
        event.timestamp = [NSDate date];
    }
    dispatch_async([MParticle messageQueue], ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];

        [self->_mpInstance.mediator.eventLogging logScreen:event
                        completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                            if (execStatus == MPExecStatusSuccess) {
                                MPILogDebug(@"Logged screen event: %@", event);
                                MPEvent *kitEvent = self->_mpInstance.dataPlanFilter != nil ? [self->_mpInstance.dataPlanFilter transformEventForScreenEvent:event] : event;
                                if (kitEvent) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        // Forwarding calls to kits
                                        [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(logScreen:)
                                                                                          event:kitEvent
                                                                                     parameters:nil
                                                                                    messageType:MPMessageTypeScreenView
                                                                                       userInfo:nil
                                         ];
                                    });
                                } else {
                                    MPILogDebug(@"Blocked screen event from kits: %@", event);
                                }
                            }
                        }];
    });
}

- (void)logScreen:(NSString *)screenName eventInfo:(NSDictionary<NSString *, id> *)eventInfo shouldUploadEvent:(BOOL)shouldUploadEvent {
    if (!screenName) {
        MPILogError(@"Screen name is required.");
        return;
    }
    
    MPEvent *event = [_mpInstance.mediator.eventLogging eventWithName:screenName];
    if (!event) {
        event = [[MPEvent alloc] initWithName:screenName type:MPEventTypeNavigation];
    }
    
    event.customAttributes = eventInfo;
    event.shouldUploadEvent = shouldUploadEvent;
    
    [self logScreenEvent:event];
}

- (void)logCustomEvent:(MPEvent *)event {
    if (event == nil) {
        MPILogError(@"Cannot log nil event!");
        return;
    }
    
    [event endTiming];
    
    dispatch_async([MParticle messageQueue], ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];

        [self->_mpInstance.mediator.eventLogging logEvent:event
                       completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                       }];
        MPEvent *kitEvent = self->_mpInstance.dataPlanFilter != nil ? [self->_mpInstance.dataPlanFilter transformEventForEvent:event] : event;
        if (kitEvent) {
            // Forwarding calls to kits
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_mpInstance.kitContainer forwardSDKCall:@selector(logEvent:)
                                                                  event:kitEvent
                                                             parameters:nil
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
                 ];
            });
        } else {
            MPILogDebug(@"Blocked custom event from kits: %@", event);
        }
        
    });
}

- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    if (commerceEvent == nil) {
        MPILogError(@"Cannot log nil commerce event!");
        return;
    }
    if (!commerceEvent.timestamp) {
        commerceEvent.timestamp = [NSDate date];
    }
    dispatch_async([MParticle messageQueue], ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:commerceEvent];

        [self->_mpInstance.mediator.eventLogging logCommerceEvent:commerceEvent
                               completionHandler:^(MPCommerceEvent *commerceEvent, MPExecStatus execStatus) {
                                   if (execStatus == MPExecStatusSuccess) {
                                   } else {
                                       MPILogDebug(@"Failed to log commerce event: %@", commerceEvent);
                                   }
                               }];
        
        MPCommerceEvent *kitEvent = self->_mpInstance.dataPlanFilter != nil ? [self->_mpInstance.dataPlanFilter transformEventForCommerceEvent:commerceEvent] : commerceEvent;
        if (kitEvent) {
            // Forwarding calls to kits
            [[MParticle sharedInstance].kitContainer forwardCommerceEventCall:kitEvent];
        } else {
            MPILogDebug(@"Blocked commerce event from kits: %@", commerceEvent);
        }
    });
}

- (void)logError:(NSString *)message eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    if (!message) {
        MPILogError(@"'message' is required for %@", NSStringFromSelector(_cmd));
        return;
    }
    
    dispatch_async([MParticle messageQueue], ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:message];

        [self->_mpInstance.mediator.eventLogging logError:message
                               exception:nil
                          topmostContext:nil
                               eventInfo:eventInfo
                       completionHandler:^(NSString *message, MPExecStatus execStatus) {
                           if (execStatus == MPExecStatusSuccess) {
                               MPILogDebug(@"Logged error with message: %@", message);
                               
                               // Forwarding calls to kits
                               MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
                               [queueParameters addParameter:message];
                               [queueParameters addParameter:eventInfo];
                               
                               [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(logError:eventInfo:) event:nil parameters:queueParameters messageType:MPMessageTypeUnknown userInfo:nil];
                           }
                       }];
    });
}

- (void)logException:(NSException *)exception topmostContext:(id)topmostContext {
    dispatch_async([MParticle messageQueue], ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:exception];

        [self->_mpInstance.mediator.eventLogging logError:nil
                               exception:exception
                          topmostContext:topmostContext
                               eventInfo:nil
                       completionHandler:^(NSString *message, MPExecStatus execStatus) {
                           if (execStatus == MPExecStatusSuccess) {
                               MPILogDebug(@"Logged exception name: %@, reason: %@, topmost context: %@", message, exception.reason, topmostContext);
                               
                               // Forwarding calls to kits
                               MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
                               [queueParameters addParameter:exception];
                               
                               [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(logException:) event:nil parameters:queueParameters messageType:MPMessageTypeUnknown userInfo:nil];
                           }
                       }];
    });
}

- (void)leaveBreadcrumb:(NSString *)breadcrumbName eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    if (!breadcrumbName) {
        MPILogError(@"Breadcrumb name is required.");
        return;
    }
    
    MPEvent *event = [_mpInstance.mediator.eventLogging eventWithName:breadcrumbName];
    if (!event) {
        event = [[MPEvent alloc] initWithName:breadcrumbName type:MPEventTypeOther];
    }
    
    event.customAttributes = eventInfo;
    
    if (!event.timestamp) {
        event.timestamp = [NSDate date];
    }
    
    dispatch_async([MParticle messageQueue], ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:breadcrumbName parameter2:eventInfo];

        [self->_mpInstance.mediator.eventLogging leaveBreadcrumb:event
                              completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                                  if (execStatus == MPExecStatusSuccess) {
                                      MPILogDebug(@"Left breadcrumb: %@", event);
                                      MPEvent *kitEvent = self->_mpInstance.dataPlanFilter != nil ? [self->_mpInstance.dataPlanFilter transformEventForEvent:event] : event;
                                      if (kitEvent) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              // Forwarding calls to kits
                                              [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(leaveBreadcrumb:)
                                                                                                event:kitEvent
                                                                                           parameters:nil
                                                                                          messageType:MPMessageTypeBreadcrumb
                                                                                             userInfo:nil
                                               ];
                                          });
                                      } else {
                                          MPILogDebug(@"Blocked breadcrumb event from kits: %@", event);
                                      }
                                  }
                              }];
    });
}

- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    NSMutableDictionary *eventDictionary = [@{@"$Amount":@(increaseAmount),
                                              kMPMethodName:@"LogLTVIncrease"}
                                            mutableCopy];
    
    if (eventInfo) {
        [eventDictionary addEntriesFromDictionary:eventInfo];
    }
    
    if (!eventName) {
        eventName = @"Increase LTV";
    }
    
    MPEvent *event = [[MPEvent alloc] initWithName:eventName type:MPEventTypeTransaction];
    event.customAttributes = eventDictionary;
    
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:@(increaseAmount) parameter2:eventName parameter3:eventInfo];
    
    [_mpInstance.mediator.eventLogging logEvent:event
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                       if (execStatus == MPExecStatusSuccess) {
                           MPEvent *kitEvent = self->_mpInstance.dataPlanFilter != nil ? [self->_mpInstance.dataPlanFilter transformEventForEvent:event] : event;
                           if (kitEvent) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   // Forwarding calls to kits
                                   [[MParticle sharedInstance].kitContainer forwardSDKCall:@selector(logLTVIncrease:event:)
                                                                                     event:nil
                                                                                parameters:nil
                                                                               messageType:MPMessageTypeUnknown
                                                                                  userInfo:nil
                                    ];
                               });
                           } else {
                               MPILogDebug(@"Blocked LTV increase event from kits: %@", event);
                           }
                       }
                   }];
}

@end
