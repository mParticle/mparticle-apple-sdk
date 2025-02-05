//
//  MPIdentityApi.m
//

#import "MPIdentityApi.h"
#import "MPIdentityApiManager.h"
#import "mParticle.h"
#import "MPBackendController.h"
#import "MPConsumerInfo.h"
#import "MPSession.h"
#import "MPPersistenceController.h"
#import "MPIdentityDTO.h"
#import "MPEnums.h"
#import "MPILogger.h"
#import "MPKitContainer.h"
#import "MPUpload.h"
#import "MParticleSwift.h"

typedef NS_ENUM(NSUInteger, MPIdentityRequestType) {
    MPIdentityRequestIdentify = 0,
    MPIdentityRequestLogin = 1,
    MPIdentityRequestLogout = 2,
    MPIdentityRequestModify = 3
};

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;

@end

@interface MPIdentityApi ()

@property (nonatomic, strong) MPIdentityApiManager *apiManager;
@property(nonatomic, strong, readwrite, nonnull) MParticleUser *currentUser;

@end

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;

@end

@interface MPBackendController_PRIVATE ()

- (NSMutableDictionary<NSString *, id> *)userAttributesForUserId:(NSNumber *)userId;

@end

@interface MParticleUser ()

- (void)setIdentitySync:(NSString *)identityString identityType:(MPIdentity)identityType;
- (void)setUserId:(NSNumber *)userId;
- (void)setIsLoggedIn:(BOOL)isLoggedIn;
@end

@interface MPKitContainer_PRIVATE ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;

@end

@interface MPAliasRequest ()

@property (nonatomic, strong, readwrite) NSDate *startTime;
@property (nonatomic, strong, readwrite) NSDate *endTime;

@end

@implementation MPIdentityApi

@synthesize currentUser = _currentUser;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _apiManager = [[MPIdentityApiManager alloc] init];
    }
    return self;
}

- (void)onModifyRequestComplete:(MPIdentityApiRequest *)request httpResponse:(MPIdentityHTTPModifySuccessResponse *) httpResponse completion:(MPModifyApiResultCallback)completion error: (NSError *) error {
    if (error) {
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    if (request.identities) {
        NSMutableDictionary *userIDsCopy = [request.identities mutableCopy];
        
        if (userIDsCopy[@(MPIdentityCustomerId)]) {
            [self.currentUser setIdentitySync:userIDsCopy[@(MPIdentityCustomerId)] identityType:MPIdentityCustomerId];
            [userIDsCopy removeObjectForKey:@(MPIdentityCustomerId)];
        }
        
        if (userIDsCopy[@(MPIdentityEmail)]) {
            [self.currentUser setIdentitySync:userIDsCopy[@(MPIdentityEmail)] identityType:MPIdentityEmail];
            [userIDsCopy removeObjectForKey:@(MPIdentityEmail)];
        }
        
        [userIDsCopy enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, id identityValue, BOOL * _Nonnull stop) {
            MPIdentity identityType = (MPIdentity)key.intValue;
            if ((NSNull *)identityValue == [NSNull null]) {
                identityValue = nil;
            }
            [self.currentUser setIdentitySync:identityValue identityType:identityType];
        }];
    }
    
    [self forwardCallToKits:request identityRequestType:MPIdentityRequestModify user:self.currentUser];
    
    if (completion) {
        MPModifyApiResult *apiResult = [[MPModifyApiResult alloc] init];
        apiResult.user = self.currentUser;
        NSMutableArray<MPIdentityChange *> *changes = [[NSMutableArray alloc] init];

        for (NSDictionary *userChange in httpResponse.changeResults) {
            if (userChange[@"modified_mpid"] != nil && userChange[@"identity_type"] != nil) {
                MPIdentityChange *change = [[MPIdentityChange alloc] init];
                
                MParticleUser *changedUser = [[MParticleUser alloc] init];
                changedUser.userId = userChange[@"modified_mpid"];
                change.changedUser = changedUser;
                
                NSString *identityString = userChange[@"identity_type"];
                NSNumber *identityNumber = [MPIdentityHTTPIdentities identityTypeForString:identityString];
                if (identityNumber != nil) {
                    change.changedIdentity = (MPIdentity)identityNumber.intValue;
                    
                    [changes addObject:change];
                } else {
                    MPILogError(@"Invalid identity type received: %@", identityString);
                }
            }
        }
        apiResult.identityChanges = changes;

        completion(apiResult, nil);
    }
}

- (void)onIdentityRequestComplete:(MPIdentityApiRequest *)request identityRequestType:(MPIdentityRequestType)identityRequestType httpResponse:(MPIdentityHTTPSuccessResponse *)httpResponse completion:(MPIdentityApiResultCallback)completion error: (NSError *) error {
    if (error) {
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    NSNumber *previousMPID = [MPPersistenceController_PRIVATE mpId];
    [MPPersistenceController_PRIVATE setMpid:httpResponse.mpid];
    MPIdentityApiResult *apiResult = [[MPIdentityApiResult alloc] init];
    MParticleUser *previousUser = self.currentUser;
    MParticleUser *user = [[MParticleUser alloc] init];
    user.userId = httpResponse.mpid;
    user.isLoggedIn = httpResponse.isLoggedIn;
    apiResult.user = user;
    apiResult.previousUser = previousUser;
    self.currentUser = user;
    MPSession *session = [MParticle sharedInstance].backendController.session;
    session.userId = httpResponse.mpid;
    NSString *userIdsString = session.sessionUserIds;
    NSMutableArray *userIds = [[userIdsString componentsSeparatedByString:@","] mutableCopy];
    
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];

    if (user.userId.longLongValue != 0) {
        [userDefaults setMPObject:[NSDate date] forKey:kMPLastIdentifiedDate userId:user.userId];
        [userDefaults synchronize];
    }
    
    if (httpResponse.mpid.longLongValue != 0 &&
        ([userIds lastObject] && ![[userIds lastObject] isEqualToString:httpResponse.mpid.stringValue])) {
        [userIds addObject:httpResponse.mpid];
    }
    
    session.sessionUserIds = userIds.count > 0 ? [userIds componentsJoinedByString:@","] : @"";
    [[MParticle sharedInstance].persistenceController updateSession:session];
    
    if (request.identities) {
        NSMutableDictionary *userIDsCopy = [request.identities mutableCopy];
        
        if (userIDsCopy[@(MPIdentityCustomerId)]) {
            [self.currentUser setIdentitySync:userIDsCopy[@(MPIdentityCustomerId)] identityType:MPIdentityCustomerId];
            [userIDsCopy removeObjectForKey:@(MPIdentityCustomerId)];
        }
        
        if (userIDsCopy[@(MPIdentityEmail)]) {
            [self.currentUser setIdentitySync:userIDsCopy[@(MPIdentityEmail)] identityType:MPIdentityEmail];
            [userIDsCopy removeObjectForKey:@(MPIdentityEmail)];
        }
        
        [userIDsCopy enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, id  _Nonnull identityValue, BOOL * _Nonnull stop) {
            MPIdentity identityType = (MPIdentity)key.intValue;
            [self.currentUser setIdentitySync:identityValue identityType:identityType];
        }];
    }
    
    if (httpResponse.mpid.intValue != previousMPID.intValue) {
        [self onMPIDChange:request httpResponse:httpResponse previousUser:previousUser newUser:user];
    }
    
    [self forwardCallToKits:request identityRequestType:identityRequestType user:user];
    
    if (completion) {
        completion(apiResult, nil);
    }
}

- (void)onMPIDChange:(MPIdentityApiRequest *)request httpResponse:(MPIdentityHTTPSuccessResponse *)httpResponse previousUser:(MParticleUser *)previousUser newUser:(MParticleUser *)newUser {
    
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];

    NSDate *date = [NSDate date];
    NSNumber *dateMs = @([date timeIntervalSince1970] * 1000.0);
    if (previousUser != nil) {
        [userDefaults setMPObject:dateMs forKey:kMPLastSeenUser userId:previousUser.userId];
    }
    if ([userDefaults mpObjectForKey:kMPFirstSeenUser userId:newUser.userId] == nil) {
        [userDefaults setMPObject:dateMs forKey:kMPFirstSeenUser userId:newUser.userId];
    }
    
    [userDefaults setMPObject:@(httpResponse.isEphemeral) forKey:kMPIsEphemeralKey userId:httpResponse.mpid];
    [userDefaults synchronize];
    
    [[MParticle sharedInstance].persistenceController moveContentFromMpidZeroToMpid:httpResponse.mpid];
    
    if (newUser) {
        NSDictionary *userInfo = nil;
        if (previousUser != nil) {
            userInfo = @{mParticleUserKey:newUser, mParticlePreviousUserKey:previousUser};
        } else {
            userInfo = @{mParticleUserKey:newUser};
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleIdentityStateChangeListenerNotification object:nil userInfo:userInfo];
        });
    }
    
    NSArray<NSDictionary *> *kitConfig = [[MParticle sharedInstance].kitContainer_PRIVATE.originalConfig copy];
    if (kitConfig) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MParticle sharedInstance].kitContainer_PRIVATE configureKits:kitConfig];
        });
    }
}

- (void)forwardCallToKits:(MPIdentityApiRequest *)request identityRequestType:(MPIdentityRequestType)identityRequestType user:(MParticleUser *)user{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (identityRequestType) {
            case MPIdentityRequestIdentify: {
                [[MParticle sharedInstance].kitContainer_PRIVATE forwardIdentitySDKCall:@selector(onIdentifyComplete: request:)
                                                                     kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                                         FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:user kitConfiguration:kitConfig];
                                                                         FilteredMPIdentityApiRequest *filteredRequest = [[FilteredMPIdentityApiRequest alloc] initWithIdentityRequest:request kitConfiguration:kitConfig];
                                                                         [kit onIdentifyComplete:filteredUser request:filteredRequest];
                                                                     }];
                break;
            }
            case MPIdentityRequestLogin: {
                [[MParticle sharedInstance].kitContainer_PRIVATE forwardIdentitySDKCall:@selector(onLoginComplete: request:)
                                                                     kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                                         FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:user kitConfiguration:kitConfig];
                                                                         FilteredMPIdentityApiRequest *filteredRequest = [[FilteredMPIdentityApiRequest alloc] initWithIdentityRequest:request kitConfiguration:kitConfig];
                                                                         [kit onLoginComplete:filteredUser request:filteredRequest];
                                                                     }];
                break;
            }
            case MPIdentityRequestLogout: {
                [[MParticle sharedInstance].kitContainer_PRIVATE forwardIdentitySDKCall:@selector(onLogoutComplete: request:)
                                                                     kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                                         FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:user kitConfiguration:kitConfig];
                                                                         FilteredMPIdentityApiRequest *filteredRequest = [[FilteredMPIdentityApiRequest alloc] initWithIdentityRequest:request kitConfiguration:kitConfig];
                                                                         [kit onLogoutComplete:filteredUser request:filteredRequest];
                                                                     }];
                break;
            }
            case MPIdentityRequestModify: {
                [[MParticle sharedInstance].kitContainer_PRIVATE forwardIdentitySDKCall:@selector(onModifyComplete: request:)
                                                                     kitHandler:^(id<MPKitProtocol> kit, MPKitConfiguration *kitConfig) {
                                                                         FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:user kitConfiguration:kitConfig];
                                                                         FilteredMPIdentityApiRequest *filteredRequest = [[FilteredMPIdentityApiRequest alloc] initWithIdentityRequest:request kitConfiguration:kitConfig];
                                                                         [kit onModifyComplete:filteredUser request:filteredRequest];
                                                                     }];
                break;
            }
            default: {
                MPILogError(@"Unknown identity request type: %@", @(identityRequestType));
                break;
            }
        }
    });
}

- (MParticleUser *)currentUser {
    if (_currentUser) {
        return _currentUser;
    }

    NSNumber *mpid = [MPPersistenceController_PRIVATE mpId];
    MParticleUser *user = [[MParticleUser alloc] init];
    user.userId = mpid;
    _currentUser = user;
    return _currentUser;
}

- (MParticleUser *)getUser:(NSNumber *)mpId {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    if ([userDefaults isExistingUserId:mpId]) {
        MParticleUser *user = [[MParticleUser alloc] init];
        user.userId = mpId;
        return user;
    } else {
        return nil;
    }
}

- (NSArray<MParticleUser *> *)sortedUserArrayByLastSeen:(NSMutableArray<MParticleUser *> *)userArray {
    NSMutableArray<MParticleUser *> *sortedUserArray = [NSMutableArray arrayWithCapacity:userArray.count];
    while (userArray.count > 0) {
        NSDate *latestSeen = [NSDate distantPast];
        int latestIndex = 0;
        for (int i=0; i<userArray.count; i++) {
            MParticleUser *user = userArray[i];
            if ([user.lastSeen compare:latestSeen] == NSOrderedDescending) {
                latestSeen = user.lastSeen;
                latestIndex = i;
            }
        }
        MParticleUser *latestUser = userArray[latestIndex];
        [sortedUserArray addObject:latestUser];
        [userArray removeObjectAtIndex:latestIndex];
    }
    
    return sortedUserArray;
}

- (NSArray<MParticleUser *> *)getAllUsers {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSMutableArray<MParticleUser *> *userArray = [[NSMutableArray alloc] init];
    
    for (NSNumber *userID in [userDefaults userIDsInUserDefaults]) {
        MParticleUser *user = [[MParticleUser alloc] init];
        user.userId = userID;
        
        [userArray addObject:user];
    }
    
    return [self sortedUserArrayByLastSeen:userArray];
}

- (NSString *)deviceApplicationStamp {
    MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];

    return device.deviceIdentifier;
}

- (void)identifyNoDispatch:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [self.apiManager identify:identifyRequest completion:^(MPIdentityHTTPBaseSuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
        [self onIdentityRequestComplete:identifyRequest identityRequestType:MPIdentityRequestIdentify httpResponse:(MPIdentityHTTPSuccessResponse *)httpResponse completion:completion error: error];
    }];
}

- (void)identify:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiResultCallback)completion {
    MPIdentityApiResultCallback wrappedCompletion = ^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(apiResult, error);
            });
        }
    };
    dispatch_async([MParticle messageQueue], ^{
        [self identifyNoDispatch:identifyRequest completion:wrappedCompletion];
    });
}

- (void)identifyWithCompletion:(nullable MPIdentityApiResultCallback)completion {
    [self identify:(id _Nonnull)nil completion:completion];
}

- (void)login:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiResultCallback)completion {
    MPIdentityApiResultCallback wrappedCompletion = ^(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(apiResult, error);
            });
        }
    };
    
    dispatch_async([MParticle messageQueue], ^{
        
        [self.apiManager loginRequest:loginRequest completion:^(MPIdentityHTTPBaseSuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
            [self onIdentityRequestComplete:loginRequest identityRequestType:MPIdentityRequestLogin httpResponse:(MPIdentityHTTPSuccessResponse *)httpResponse completion:wrappedCompletion error: error];
        }];
        
    });
}

- (void)loginWithCompletion:(nullable MPIdentityApiResultCallback)completion {
    [self login:(id _Nonnull)nil completion:completion];
}

- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiResultCallback)completion {
    MPIdentityApiResultCallback wrappedCompletion = ^(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(apiResult, error);
            });
        }
    };
    
    dispatch_async([MParticle messageQueue], ^{
        [self.apiManager logout:logoutRequest completion:^(MPIdentityHTTPBaseSuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
            [self onIdentityRequestComplete:logoutRequest identityRequestType:MPIdentityRequestLogout httpResponse:(MPIdentityHTTPSuccessResponse *)httpResponse completion:wrappedCompletion error: error];
        }];
    });
}

- (void)logoutWithCompletion:(nullable MPIdentityApiResultCallback)completion {
    [self logout:(id _Nonnull)nil completion:completion];
}

- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPModifyApiResultCallback)completion {
    MPModifyApiResultCallback wrappedCompletion = ^(MPModifyApiResult *_Nullable apiResult, NSError *_Nullable error) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(apiResult, error);
            });
        }
    };
    dispatch_async([MParticle messageQueue], ^{
        [self.apiManager modify:modifyRequest completion:^(MPIdentityHTTPModifySuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
            [self onModifyRequestComplete:modifyRequest httpResponse:httpResponse completion:wrappedCompletion error: error];
        }];
    });
}

- (BOOL)aliasUsers:(MPAliasRequest *)aliasRequest {
    if (aliasRequest.sourceMPID == nil || aliasRequest.destinationMPID == nil || aliasRequest.sourceMPID.longLongValue == 0 || aliasRequest.destinationMPID.longLongValue == 0 || [aliasRequest.sourceMPID isEqual:aliasRequest.destinationMPID]) {
        MPILogError(@"Invalid alias request - both users must exist and not be equal.");
        return NO;
    }
    
    double maxDaysAgo = MParticle.sharedInstance.stateMachine.aliasMaxWindow != nil ? MParticle.sharedInstance.stateMachine.aliasMaxWindow.doubleValue : 90;
    double secondsPerDay = 60*60*24;
    NSDate *oldestAllowableDate = [NSDate dateWithTimeIntervalSinceNow:-1*secondsPerDay*maxDaysAgo];
    
    if (aliasRequest.usedFirstLastSeen) {
        if ([aliasRequest.startTime compare:oldestAllowableDate] == NSOrderedAscending) {
            aliasRequest.startTime = oldestAllowableDate;
        }
    }
    
    if (aliasRequest.startTime == nil || aliasRequest.endTime == nil) {
        aliasRequest.startTime = oldestAllowableDate;
        aliasRequest.endTime = [NSDate dateWithTimeIntervalSinceNow:0];
    }
    
    if ([aliasRequest.startTime compare:aliasRequest.endTime] != NSOrderedAscending) {
        MPILogWarning(@"Invalid alias request - Start date must occur before end date. Alias Request will likely fail");
    }
    
    dispatch_async([MParticle messageQueue], ^{
        
        [MParticle.sharedInstance.backendController skipNextUpload];
        [MParticle.sharedInstance.backendController waitForKitsAndUploadWithCompletionHandler:^{
            MPIdentityHTTPAliasRequest *request = [[MPIdentityHTTPAliasRequest alloc] initWithIdentityApiAliasRequest:aliasRequest];
            NSDictionary *aliasDictionary = request.dictionaryRepresentation;
            NSData *uploadData = [NSJSONSerialization dataWithJSONObject:aliasDictionary options:0 error:nil];
            
            NSString *uuid = aliasDictionary[@"request_id"];
            
            MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil
                                                          uploadId:0
                                                              UUID:uuid
                                                        uploadData:uploadData
                                                         timestamp:[NSDate date].timeIntervalSince1970
                                                        uploadType:MPUploadTypeAlias
                                                        dataPlanId:[MParticle sharedInstance].dataPlanId
                                                   dataPlanVersion:[MParticle sharedInstance].dataPlanVersion
                                                    uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
            
            [MParticle.sharedInstance.persistenceController saveUpload:upload];
            [MParticle.sharedInstance.backendController waitForKitsAndUploadWithCompletionHandler:nil];
        }];
        
    });
    
    return YES;
}

@end

@implementation MPIdentityChange

@end

@implementation MPIdentityApiResult

@end

@implementation MPModifyApiResult

@end

@implementation MPIdentityHTTPErrorResponse

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary httpCode:(NSInteger) httpCode {
    self = [super init];
    if (self) {
        _httpCode = httpCode;
        if (dictionary) {
            _code = [dictionary[kMPIdentityRequestKeyCode] unsignedIntegerValue];
            _message = dictionary[kMPIdentityRequestKeyMessage];
        } else {
            _code = httpCode;
        }
    }
    return self;
}

- (instancetype)initWithCode:(MPIdentityErrorResponseCode) code message: (NSString *) message error: (NSError *) error {
    self = [super init];
    if (self) {
        _code = code;
        _innerError = error;
        _message = message;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"MPIdentityHTTPErrorResponse {\n"];
    [description appendFormat:@"  httpCode: %@\n", @(_httpCode)];
    [description appendFormat:@"  code: %@\n", @(_code)];
    [description appendFormat:@"  message: %@\n", _message];
    [description appendFormat:@"  inner error: %@\n", _innerError];
    [description appendString:@"}"];
    return description;
}

@end
