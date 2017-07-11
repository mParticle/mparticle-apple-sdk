//
//  MParticleUser.m
//

#import "MParticleUser.h"
#import "MPBackendController.h"
#import "MPStateMachine.h"
#import "MPKitContainer.h"
#import "MPILogger.h"
#import "mParticle.h"
#import "MPUserSegments.h"
#import "MPUserSegments+Setters.h"

@interface MParticleUser ()

@property (nonatomic, strong) MPBackendController *backendController;
@property(nonatomic, strong, readwrite, nullable) NSNumber *userId;


@end

@interface MParticle ()

@property (nonatomic, strong) MPBackendController *backendController;

@end

@implementation MParticleUser

- (instancetype)init
{
    self = [super init];
    if (self) {
        _backendController = [MParticle sharedInstance].backendController;
    }
    return self;
}

- (nullable NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    if (!_backendController || _backendController.initializationStatus != MPInitializationStatusStarted) {
        MPILogError(@"Cannot increment user attribute. SDK is not initialized yet.");
        return nil;
    }
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return nil;
    }
    
    NSNumber *newValue = [self.backendController incrementUserAttribute:key byValue:value];
    
    MPILogDebug(@"User attribute %@ incremented by %@. New value: %@", key, value, newValue);
    
    [[MPKitContainer sharedInstance] forwardSDKCall:@selector(incrementUserAttribute:byValue:)
                                   userAttributeKey:key
                                              value:value
                                         kitHandler:^(id<MPKitProtocol> kit) {
                                             [kit incrementUserAttribute:key byValue:value];
                                         }];
    
    return newValue;
}

- (void)setUserAttribute:(NSString *)key value:(nullable id)value {
    __weak MParticleUser *weakSelf = self;
    
    [self.backendController setUserAttribute:key
                                       value:value
                                     attempt:0
                           completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                               __strong MParticleUser *strongSelf = weakSelf;
                               
                               if (execStatus == MPExecStatusSuccess) {
                                   if (value) {
                                       MPILogDebug(@"Set user attribute - %@:%@", key, value);
                                   } else {
                                       MPILogDebug(@"Reset user attribute - %@", key);
                                   }
                                   
                                   // Forwarding calls to kits
                                   if ((value == nil) || [value isKindOfClass:[NSString class]]) {
                                       if (((NSString *)value).length > 0) {
                                           [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserAttribute:value:)
                                                                          userAttributeKey:key
                                                                                     value:value
                                                                                kitHandler:^(id<MPKitProtocol> kit) {
                                                                                    [kit setUserAttribute:key value:value];
                                                                                }];
                                       } else {
                                           [[MPKitContainer sharedInstance] forwardSDKCall:@selector(removeUserAttribute:)
                                                                          userAttributeKey:key
                                                                                     value:value
                                                                                kitHandler:^(id<MPKitProtocol> kit) {
                                                                                    [kit removeUserAttribute:key];
                                                                                }];
                                       }
                                   } else {
                                       [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserAttribute:value:)
                                                                      userAttributeKey:key
                                                                                 value:value
                                                                            kitHandler:^(id<MPKitProtocol> kit) {
                                                                                [kit setUserAttribute:key value:value];
                                                                            }];
                                   }
                               } else if (execStatus == MPExecStatusDelayedExecution) {
                                   MPILogWarning(@"Delayed set user attribute: %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                   MPILogError(@"Could not set user attribute - %@:%@\n Reason: %@", key, value, [strongSelf.backendController execStatusDescription:execStatus]);
                               }
                           }];
}

- (void)setUserAttributeList:(NSString *)key values:(nullable NSArray<NSString *> *)values {
    __weak MParticleUser *weakSelf = self;
    
    [self.backendController setUserAttribute:key
                                      values:values
                                     attempt:0
                           completionHandler:^(NSString *key, NSArray *values, MPExecStatus execStatus) {
                               __strong MParticleUser *strongSelf = weakSelf;
                               
                               if (execStatus == MPExecStatusSuccess) {
                                   if (values) {
                                       MPILogDebug(@"Set user attribute values - %@:%@", key, values);
                                   } else {
                                       MPILogDebug(@"Reset user attribute - %@", key);
                                   }
                                   
                                   // Forwarding calls to kits
                                   if (values) {
                                       SEL setUserAttributeSelector = @selector(setUserAttribute:value:);
                                       SEL setUserAttributeListSelector = @selector(setUserAttribute:values:);
                                       
                                       [[MPKitContainer sharedInstance] forwardSDKCall:setUserAttributeListSelector
                                                                      userAttributeKey:key
                                                                                 value:values
                                                                            kitHandler:^(id<MPKitProtocol> kit) {
                                                                                if ([kit respondsToSelector:setUserAttributeListSelector]) {
                                                                                    [kit setUserAttribute:key values:values];
                                                                                } else if ([kit respondsToSelector:setUserAttributeSelector]) {
                                                                                    NSString *csvValues = [values componentsJoinedByString:@","];
                                                                                    [kit setUserAttribute:key value:csvValues];
                                                                                }
                                                                            }];
                                   } else {
                                       [[MPKitContainer sharedInstance] forwardSDKCall:@selector(removeUserAttribute:)
                                                                      userAttributeKey:key
                                                                                 value:values
                                                                            kitHandler:^(id<MPKitProtocol> kit) {
                                                                                [kit removeUserAttribute:key];
                                                                            }];
                                   }
                               } else if (execStatus == MPExecStatusDelayedExecution) {
                                   MPILogWarning(@"Delayed set user attribute values: %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                   MPILogError(@"Could not set user attribute values - %@:%@\n Reason: %@", key, values, [strongSelf.backendController execStatusDescription:execStatus]);
                               }
                           }];
}

- (void)setUserTag:(NSString *)tag {
    __weak MParticleUser *weakSelf = self;
    
    [self.backendController setUserAttribute:tag
                                       value:nil
                                     attempt:0
                           completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                               __strong MParticleUser *strongSelf = weakSelf;
                               
                               if (execStatus == MPExecStatusSuccess) {
                                   MPILogDebug(@"Set user tag - %@", tag);
                                   
                                   // Forwarding calls to kits
                                   [[MPKitContainer sharedInstance] forwardSDKCall:@selector(setUserTag:)
                                                                  userAttributeKey:tag
                                                                             value:nil
                                                                        kitHandler:^(id<MPKitProtocol> kit) {
                                                                            [kit setUserTag:tag];
                                                                        }];
                               } else if (execStatus == MPExecStatusDelayedExecution) {
                                   MPILogWarning(@"Delayed set user tag: %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                   MPILogError(@"Could not set user tag - %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               }
                           }];
}

- (void)removeUserAttribute:(NSString *)key {
    __weak MParticleUser *weakSelf = self;
    
    [self.backendController setUserAttribute:key
                                       value:@""
                                     attempt:0
                           completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                               __strong MParticleUser *strongSelf = weakSelf;
                               
                               if (execStatus == MPExecStatusSuccess) {
                                   MPILogDebug(@"Removed user attribute - %@", key);
                                   
                                   // Forwarding calls to kits
                                   [[MPKitContainer sharedInstance] forwardSDKCall:_cmd
                                                                  userAttributeKey:key
                                                                             value:nil
                                                                        kitHandler:^(id<MPKitProtocol> kit) {
                                                                            [kit removeUserAttribute:key];
                                                                        }];
                               } else if (execStatus == MPExecStatusDelayedExecution) {
                                   MPILogWarning(@"Delayed removing user attribute: %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               } else if (execStatus != MPExecStatusContinuedDelayedExecution) {
                                   MPILogError(@"Could not remove user attribute - %@\n Reason: %@", key, [strongSelf.backendController execStatusDescription:execStatus]);
                               }
                           }];
}

#pragma mark - User Segments

- (void)userSegments:(NSTimeInterval)timeout endpointId:(NSString *)endpointId completionHandler:(MPUserSegmentsHandler)completionHandler {
    MPExecStatus execStatus = [self.backendController fetchSegments:timeout
                                                         endpointId:endpointId
                                                  completionHandler:^(NSArray *segments, NSTimeInterval elapsedTime, NSError *error) {
                                                      if (!segments) {
                                                          completionHandler(nil, error);
                                                          return;
                                                      }
                                                      
                                                      MPUserSegments *userSegments = [[MPUserSegments alloc] initWithSegments:segments];
                                                      completionHandler(userSegments, error);
                                                  }];
    
    if (execStatus == MPExecStatusSuccess) {
        MPILogDebug(@"Fetching user segments");
    } else {
        MPILogError(@"Could not fetch user segments: %@", [self.backendController execStatusDescription:execStatus]);
    }
}


@end
