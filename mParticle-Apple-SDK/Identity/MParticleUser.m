//
//  MParticleUser.m
//

#import "MParticleUser.h"
#import "MPILogger.h"
#import "mParticle.h"
#import "MPAudience.h"
#import "MPPersistenceController.h"
#import "MPDataPlanFilter.h"
#import "MPIConstants.h"
#import "MPKitContainer.h"
#import "mParticleSwift.h"

@interface MParticleUser ()

@property (nonatomic, strong) MPBackendController_PRIVATE *backendController;

@end

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPDataPlanFilter *dataPlanFilter;

@end

@interface MPKitContainer_PRIVATE ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;

@end

@implementation MParticleUser

- (instancetype)init
{
    self = [super init];
    if (self) {
        _backendController = [MParticle sharedInstance].backendController;
        _isLoggedIn = false;
    }
    return self;
}

- (NSDate *)firstSeen {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSNumber *firstSeenMs = [userDefaults mpObjectForKey:kMPFirstSeenUser userId:self.userId];
    return [NSDate dateWithTimeIntervalSince1970:firstSeenMs.doubleValue/1000.0];
}

- (NSDate *)lastSeen {
    if ([MParticle.sharedInstance.identity.currentUser.userId isEqual:self.userId]) {
        return [NSDate date];
    }
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSNumber *lastSeenMs = [userDefaults mpObjectForKey:kMPLastSeenUser userId:self.userId];
    return [NSDate dateWithTimeIntervalSince1970:lastSeenMs.doubleValue/1000.0];
}

- (NSDictionary*) identities {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSArray *userIdentityArray = [userDefaults mpObjectForKey:kMPUserIdentityArrayKey userId:_userId];
    
    NSMutableDictionary *userIdentities = [NSMutableDictionary dictionary];
    [userIdentityArray enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *identity = obj[@"i"];
        NSNumber *type = obj[@"n"];
        [userIdentities setObject:identity forKey:type];
    }];
    
    //Remove IDFA if ATT status demands
    NSNumber *currentStatus = [MParticle sharedInstance].stateMachine.attAuthorizationStatus;
    if (userIdentities[@(MPIdentityIOSAdvertiserId)] && currentStatus != nil && currentStatus.integerValue != MPATTAuthorizationStatusAuthorized) {
        [userIdentities removeObjectForKey:@(MPIdentityIOSAdvertiserId)];
    }
    
    return userIdentities;
}

-(NSDictionary*) userAttributes
{
    return [[MParticle sharedInstance].backendController userAttributesForUserId:self.userId];
}

-(void) setUserAttributes:(NSDictionary *)userAttributes
{
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:userAttributes];
    
    NSDictionary<NSString *, id> *existingUserAttributes = self.userAttributes;
    [existingUserAttributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self removeUserAttribute:key];
    }];
    
    [userAttributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull valueOrValues, BOOL * _Nonnull stop) {
        if ([valueOrValues isKindOfClass:[NSArray class]]) {
            NSArray *values = valueOrValues;
            [self setUserAttributeList:key values:values];
        }
        else {
            id value = valueOrValues;
            [self setUserAttribute:key value:value];
        }
    }];
}

- (void)setUserId:(NSNumber *)userId {
    _userId = userId;
}

- (void)setIsLoggedIn:(BOOL)isLoggedIn {
    _isLoggedIn = isLoggedIn;
}

- (void)setIdentity:(NSString *)identityString identityType:(MPIdentity)identityType {
    
    NSDate *timestamp = [NSDate date];
    dispatch_async([MParticle messageQueue], ^{
        [self setIdentitySync:identityString identityType:identityType timestamp:timestamp];
    });
}

- (void)setIdentitySync:(NSString *)identityString identityType:(MPIdentity)identityType {
    [self setIdentitySync:identityString identityType:identityType timestamp:[NSDate date]];
}

- (void)setIdentitySync:(NSString *)identityString identityType:(MPIdentity)identityType timestamp:(NSDate *)timestamp {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:identityString parameter2:@(identityType) parameter3:timestamp];
    if ([MPEnum isUserIdentity:identityType]) {
        __weak MParticleUser *weakSelf = self;
        [self.backendController setUserIdentity:identityString
                                   identityType:(MPUserIdentity)identityType
                                      timestamp:timestamp
                              completionHandler:^(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
                                  __strong MParticleUser *strongSelf = weakSelf;
                                if (MParticle.sharedInstance.dataPlanFilter == nil || ![MParticle.sharedInstance.dataPlanFilter isBlockedUserIdentityType:(MPIdentity)identityType]) {
                                  if (strongSelf) {
                                      [strongSelf forwardLegacyUserIdentityToKitContainer:identityString
                                                                             identityType:identityType
                                                                               execStatus:execStatus];
                                  }
                                } else {
                                    MPILogDebug(@"Blocked user identity from kits: %@ - %@", @(identityType), identityString);
                                }
                              }];
    }
    
    NSNumber *identityTypeNumber = @(identityType);
    BOOL (^objectTester)(id, NSUInteger, BOOL *) = ^(id obj, NSUInteger idx, BOOL *stop) {
        NSNumber *currentIdentityType = obj[kMPUserIdentityTypeKey];
        BOOL foundMatch = [currentIdentityType isEqualToNumber:identityTypeNumber];
        
        if (foundMatch) {
            *stop = YES;
        }
        
        return foundMatch;
    };
    
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSMutableArray *identities = [[userDefaults mpObjectForKey:kMPUserIdentityArrayKey userId:[MPPersistenceController_PRIVATE mpId]] mutableCopy];
    if (!identities) {
        identities = [[NSMutableArray alloc] init];
    }
    NSUInteger existingEntryIndex;
    
    if (identityString == nil || (NSNull *)identityString == [NSNull null] || [identityString isEqualToString:@""]) {
        existingEntryIndex = [identities indexOfObjectPassingTest:objectTester];
        
        if (existingEntryIndex != NSNotFound) {
            [identities removeObjectAtIndex:existingEntryIndex];
        }
    } else {
        existingEntryIndex = [identities indexOfObjectPassingTest:objectTester];
        
        if (existingEntryIndex == NSNotFound) {
            NSMutableDictionary *newIdentityDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
            
            newIdentityDictionary[kMPUserIdentityTypeKey] = identityTypeNumber;
            newIdentityDictionary[kMPUserIdentityIdKey] = identityString;
                        
            [identities addObject:newIdentityDictionary];
        } else {
            NSMutableDictionary *newIdentityDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
            
            newIdentityDictionary[kMPUserIdentityTypeKey] = identityTypeNumber;
            newIdentityDictionary[kMPUserIdentityIdKey] = identityString;
            
            [identities replaceObjectAtIndex:existingEntryIndex withObject:newIdentityDictionary];
        }
    }
        
    [userDefaults setObject:identities forKeyedSubscript:kMPUserIdentityArrayKey];
    [userDefaults synchronize];
}

- (BOOL)forwardLegacyUserIdentityToKitContainer:(NSString *)identityString identityType:(MPUserIdentity)identityType execStatus:(MPExecStatus) execStatus {
    if (execStatus != MPExecStatusSuccess || MPIsNull(identityString)) {
        return NO;
    }
    MPILogDebug(@"Set user identity: %@", identityString);
    if (MParticle.sharedInstance.dataPlanFilter == nil || ![MParticle.sharedInstance.dataPlanFilter isBlockedUserIdentityType:(MPIdentity)identityType]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(setUserIdentity:identityType:)
                                                       userIdentity:identityString
                                                       identityType:identityType
                                                         kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                [kit setUserIdentity:identityString identityType:identityType];
            }];
        });
    } else {
        MPILogDebug(@"Blocked legacy user identity from kits: %@ - %@", @(identityType), identityString);
    }
    return YES;
}

- (nullable NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    dispatch_async([MParticle messageQueue], ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:key parameter2:value];
        
        MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
        if (stateMachine.optOut) {
            return;
        }
        
        NSNumber *newValue = [self.backendController incrementUserAttribute:key byValue:value];
        
        MPILogDebug(@"User attribute %@ incremented by %@. New value: %@", key, value, newValue);
        if (MParticle.sharedInstance.dataPlanFilter == nil || ![MParticle.sharedInstance.dataPlanFilter isBlockedUserAttributeKey:key]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(incrementUserAttribute:byValue:)
                                                       userAttributeKey:key
                                                                  value:value
                                                             kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:self kitConfiguration:kitConfig];
                    
                    if ([kit respondsToSelector:@selector(incrementUserAttribute:byValue:)]) {
                        [kit incrementUserAttribute:key byValue:value];
                    }
                    if ([kit respondsToSelector:@selector(onIncrementUserAttribute:)] && filteredUser != nil) {
                        [kit onIncrementUserAttribute:filteredUser];
                    }
                }];
                
                [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(setUserAttribute:value:)
                                                       userAttributeKey:key
                                                                  value:newValue
                                                             kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                    if (![kit respondsToSelector:@selector(incrementUserAttribute:byValue:)]) {
                        FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:self kitConfiguration:kitConfig];
                        
                        if ([kit respondsToSelector:@selector(setUserAttribute:value:)]) {
                            [kit setUserAttribute:key value:newValue];
                        }
                        if ([kit respondsToSelector:@selector(onSetUserAttribute:)] && filteredUser != nil) {
                            [kit onSetUserAttribute:filteredUser];
                        }
                    }
                }];
            });
        } else {
            MPILogDebug(@"Blocked user attribute increment from kits: %@ - %@", key, value);
        }
    });
    
    return @0;
}

- (void)setUserAttribute:(nonnull NSString *)key value:(nonnull id)value {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:key parameter2:value];
    
    if ([value isKindOfClass:[NSString class]] && (((NSString *)value).length <= 0)) {
        MPILogDebug(@"User attribute not updated. Please use removeUserAttribute.");
        
        return;
    }
    
    __weak MParticleUser *weakSelf = self;
    NSDate *timestamp = [NSDate date];
    dispatch_async([MParticle messageQueue], ^{
        
        [self.backendController setUserAttribute:key
                                           value:value
                                       timestamp:timestamp
                               completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                                   __strong MParticleUser *strongSelf = weakSelf;
                                   
                                   if (execStatus == MPExecStatusSuccess) {
                                       if (value) {
                                           MPILogDebug(@"Set user attribute - %@:%@", key, value);
                                       } else {
                                           MPILogDebug(@"Reset user attribute - %@", key);
                                       }
                                       if (MParticle.sharedInstance.dataPlanFilter == nil || ![MParticle.sharedInstance.dataPlanFilter isBlockedUserAttributeKey:key]) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               // Forwarding calls to kits
                                               [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(setUserAttribute:value:)
                                                                                      userAttributeKey:key
                                                                                                 value:value
                                                                                            kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                   FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:strongSelf kitConfiguration:kitConfig];
                                                   
                                                   [kit setUserAttribute:key value:value];
                                                   if ([kit respondsToSelector:@selector(onSetUserAttribute:)] && filteredUser != nil) {
                                                       [kit onSetUserAttribute:filteredUser];
                                                   }
                                               }];
                                           });
                                       } else {
                                           MPILogDebug(@"Blocked user attribute from kits: %@ - %@", key, value);
                                       }
                                   }
                               }];
    });
}

- (void)setUserAttributeList:(nonnull NSString *)key values:(nonnull NSArray<NSString *> *)values {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:key parameter2:values];
    
    if (values.count == 0) {
        MPILogDebug(@"User attribute not updated. Please use removeUserAttribute.");
        return;
    }

    __weak MParticleUser *weakSelf = self;
    NSDate *timestamp = [NSDate date];
    dispatch_async([MParticle messageQueue], ^{
        [self.backendController setUserAttribute:key
                                          values:values
                                       timestamp:timestamp
                               completionHandler:^(NSString *key, NSArray *values, MPExecStatus execStatus) {
                                   
                                   __strong MParticleUser *strongSelf = weakSelf;
                                   
                                   if (execStatus == MPExecStatusSuccess) {
                                       if (values) {
                                           MPILogDebug(@"Set user attribute values - %@:%@", key, values);
                                       } else {
                                           MPILogDebug(@"Reset user attribute - %@", key);
                                       }
                                       
                                       if (MParticle.sharedInstance.dataPlanFilter == nil || ![MParticle.sharedInstance.dataPlanFilter isBlockedUserAttributeKey:key]) {
                                           // Forwarding calls to kits
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               SEL setUserAttributeSelector = @selector(setUserAttribute:value:);
                                               SEL setUserAttributeListSelector = @selector(setUserAttribute:values:);
                                               
                                               [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:setUserAttributeListSelector
                                                                                      userAttributeKey:key
                                                                                                 value:values
                                                                                            kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                   FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:strongSelf kitConfiguration:kitConfig];
                                                   if ([kit respondsToSelector:setUserAttributeListSelector]) {
                                                       [kit setUserAttribute:key values:values];
                                                   } else if ([kit respondsToSelector:setUserAttributeSelector]) {
                                                       NSString *csvValues = [values componentsJoinedByString:@","];
                                                       [kit setUserAttribute:key value:csvValues];
                                                   } else if ([kit respondsToSelector:@selector(onSetUserAttribute:)] && filteredUser != nil) {
                                                       [kit onSetUserAttribute:filteredUser];
                                                   }
                                               }];
                                           });
                                       } else {
                                           MPILogDebug(@"Blocked user attribute list from kits: %@ - %@", key, values);
                                       }
                                   }
                               }];
    });
}

- (void)setUserTag:(nonnull NSString *)tag {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:tag];
    
    __weak MParticleUser *weakSelf = self;
    NSDate *timestamp = [NSDate date];
    dispatch_async([MParticle messageQueue], ^{
        [self.backendController setUserTag:tag
                                 timestamp:timestamp
                         completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
            __strong MParticleUser *strongSelf = weakSelf;
            
            if (execStatus == MPExecStatusSuccess) {
                MPILogDebug(@"Set user tag - %@", tag);
                
                if (MParticle.sharedInstance.dataPlanFilter == nil || ![MParticle.sharedInstance.dataPlanFilter isBlockedUserAttributeKey:tag]) {
                    // Forwarding calls to kits
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(setUserTag:)
                                                               userAttributeKey:tag
                                                                          value:nil
                                                                     kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                            FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:strongSelf kitConfiguration:kitConfig];
                            
                            [kit setUserTag:tag];
                            if ([kit respondsToSelector:@selector(onSetUserTag:)] && filteredUser != nil) {
                                [kit onSetUserTag:filteredUser];
                            }
                        }];
                    });
                } else {
                    MPILogDebug(@"Blocked user tag from kits: %@", tag);
                }
            }
        }];
    });
}

- (void)removeUserAttribute:(nonnull NSString *)key {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:key];
    
    __weak MParticleUser *weakSelf = self;
    NSDate *timestamp = [NSDate date];
    dispatch_async([MParticle messageQueue], ^{
        [self.backendController removeUserAttribute:key
                                       timestamp:timestamp
                               completionHandler:^(NSString *key, id value, MPExecStatus execStatus) {
                                   
                                   __strong MParticleUser *strongSelf = weakSelf;
                                   
                                   if (execStatus == MPExecStatusSuccess) {
                                       MPILogDebug(@"Removed user attribute - %@", key);
                                       
                                       if (MParticle.sharedInstance.dataPlanFilter == nil ||![MParticle.sharedInstance.dataPlanFilter isBlockedUserAttributeKey:key]) {
                                           // Forwarding calls to kits
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                   [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:_cmd
                                                                                          userAttributeKey:key
                                                                                                     value:nil
                                                                                                kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                       FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:strongSelf kitConfiguration:kitConfig];
                                                       
                                                       [kit removeUserAttribute:key];
                                                       if ([kit respondsToSelector:@selector(onRemoveUserAttribute:)] && filteredUser != nil) {
                                                           [kit onRemoveUserAttribute:filteredUser];
                                                       }
                                                   }];
                                           });
                                       } else {
                                           MPILogDebug(@"Blocked remove user attribute from kits: %@", key);
                                       }
                                   }
                           }];
    });
}

#pragma mark - User Segments
- (void)getUserAudiencesWithCompletionHandler:(void (^)(NSArray<MPAudience *> *currentAudiences, NSError * _Nullable error))completionHandler {
    if ([MParticle sharedInstance].stateMachine.enableAudienceAPI) {
        dispatch_async([MParticle messageQueue], ^{
            [self.backendController fetchAudiencesWithCompletionHandler:completionHandler];
        });
    } else {
        NSError *audienceError = [NSError errorWithDomain:@"mParticle Audience"
                                                     code:202
                                                 userInfo:@{@"message":@"Your workspace is not enabled to retrieve user audiences."}];
        completionHandler(nil, audienceError);
    }
}

#pragma mark - Consent State

- (void)setConsentState:(MPConsentState *)state {
    
    [MPPersistenceController_PRIVATE setConsentState:state forMpid:self.userId];
    
    NSArray<NSDictionary *> *kitConfig = [[MParticle sharedInstance].kitContainer_PRIVATE.originalConfig copy];
    if (kitConfig) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MParticle sharedInstance].kitContainer_PRIVATE configureKits:kitConfig];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(setConsentState:) consentState:state kitHandler:^(id<MPKitProtocol>  _Nonnull kit, MPConsentState * _Nullable filteredConsentState, MPKitConfiguration * _Nonnull kitConfiguration) {
            MPKitExecStatus *status = [kit setConsentState:filteredConsentState];
            if (!status.success) {
                MPILogError(@"Failed to set consent state for kit=%@", status.integrationId);
            }
        }];
    });
}

- (nullable MPConsentState *)consentState {
    return [MPPersistenceController_PRIVATE consentStateForMpid:self.userId];
}


@end
