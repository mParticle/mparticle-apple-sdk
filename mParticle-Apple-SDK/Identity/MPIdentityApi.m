//
//  MPIdentityApi.m
//

#import "MPIdentityApi.h"
#import "MPIdentityApiManager.h"
#import "mParticle.h"
#import "MPBackendController.h"
#import "MPStateMachine.h"
#import "MPConsumerInfo.h"
#import "MPUtils.h"
#import "MPIUserDefaults.h"
#import "MPSession.h"
#import "MPPersistenceController.h"
#import "MPIdentityDTO.h"
#import "MPEnums.h"

@interface MPIdentityApi ()

@property (nonatomic, strong) MPIdentityApiManager *apiManager;
@property(nonatomic, strong, readwrite, nonnull) MParticleUser *currentUser;

@end

@interface MParticle ()

@property (nonatomic, strong, nonnull) MPBackendController *backendController;

@end

@interface MPBackendController ()

- (NSMutableDictionary<NSString *, id> *)userAttributesForUserId:(NSNumber *)userId;

@end

@interface MParticleUser ()

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType;
- (void)setUserId:(NSNumber *)userId;
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

- (void)onModifyRequestSuccess:(MPIdentityApiRequest *)request httpResponse:(MPIdentityHTTPModifySuccessResponse *) httpResponse completion:(MPIdentityApiResultCallback)completion {
    if (request.userIdentities) {
        [request.userIdentities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, id  _Nonnull identityValue, BOOL * _Nonnull stop) {
            MPUserIdentity identityType = (MPUserIdentity)key.intValue;
            if ((NSNull *)identityValue == [NSNull null]) {
                identityValue = nil;
            }
            [self.currentUser setUserIdentity:identityValue identityType:identityType];
        }];
    }
    if (completion) {
        MPIdentityApiResult *apiResult = [[MPIdentityApiResult alloc] init];
        apiResult.user = self.currentUser;
        completion(apiResult, nil);
    }
}

- (void)onIdentityRequestSuccess:(MPIdentityApiRequest *)request httpResponse:(MPIdentityHTTPSuccessResponse *) httpResponse completion:(MPIdentityApiResultCallback)completion {
    NSNumber *previousMPID = [MPUtils mpId];
    [MPUtils setMpid:httpResponse.mpid];
    MPIdentityApiResult *apiResult = [[MPIdentityApiResult alloc] init];
    MParticleUser *user = [[MParticleUser alloc] init];
    user.userId = httpResponse.mpid;
    apiResult.user = user;
    self.currentUser = user;
    MPSession *session = [MParticle sharedInstance].backendController.session;
    session.userId = httpResponse.mpid;
    NSString *userIdsString = session.sessionUserIds;
    NSMutableArray *userIds = [[userIdsString componentsSeparatedByString:@","] mutableCopy];
    
    if (httpResponse.mpid.longLongValue != 0 &&
        ([userIds lastObject] && ![[userIds lastObject] isEqualToString:httpResponse.mpid.stringValue])) {
        [userIds addObject:httpResponse.mpid];
    }
    
    session.sessionUserIds = userIds.count > 0 ? [userIds componentsJoinedByString:@","] : @"";
    [[MPPersistenceController sharedInstance] updateSession:session];
    
    if (request.userIdentities) {
        [request.userIdentities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, id  _Nonnull identityValue, BOOL * _Nonnull stop) {
            MPUserIdentity identityType = (MPUserIdentity)key.intValue;
            [self.currentUser setUserIdentity:identityValue identityType:identityType];
        }];
    }
    
    if (httpResponse.mpid.intValue == previousMPID.intValue) {
        completion(apiResult, nil);
        return;
    }
    
    if (request.copyUserAttributes) {
        NSMutableDictionary *previousUserAttributes = [[MParticle sharedInstance].backendController userAttributesForUserId:previousMPID];
        if (previousUserAttributes) {
            for (NSString *key in [previousUserAttributes allKeys]) {
                if (key) {
                    [user setUserAttribute:key value:previousUserAttributes[key]];
                }
            }
        }
    }
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    [userDefaults setMPObject:@(httpResponse.isEphemeral) forKey:kMPIsEphemeralKey userId:httpResponse.mpid];
    [userDefaults synchronize];

    [[MPPersistenceController sharedInstance] moveContentFromMpidZeroToMpid:httpResponse.mpid];
    
    if (user) {
        NSDictionary *userInfo = @{mParticleUserKey:user};
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleIdentityStateChangeListenerNotification object:nil userInfo:userInfo];
    }
    
    completion(apiResult, nil);
}

- (MParticleUser *)currentUser {
    if (_currentUser) {
        return _currentUser;
    }

    NSNumber *mpid = [MPUtils mpId];
    MParticleUser *user = [[MParticleUser alloc] init];
    user.userId = mpid;
    _currentUser = user;
    return _currentUser;
}

- (void)identify:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager identify:identifyRequest completion:^(MPIdentityHTTPBaseSuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
        [self onIdentityRequestSuccess:identifyRequest httpResponse:(MPIdentityHTTPSuccessResponse *)httpResponse completion:completion];
    }];
}

- (void)identifyWithCompletion:(nullable MPIdentityApiResultCallback)completion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self identify:nil completion:completion];
#pragma clang diagnostic pop
}

- (void)login:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager loginRequest:loginRequest completion:^(MPIdentityHTTPBaseSuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
        [self onIdentityRequestSuccess:loginRequest httpResponse:(MPIdentityHTTPSuccessResponse *)httpResponse completion:completion];
    }];
}

- (void)loginWithCompletion:(nullable MPIdentityApiResultCallback)completion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self login:nil completion:completion];
#pragma clang diagnostic pop
}

- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager logout:logoutRequest completion:^(MPIdentityHTTPBaseSuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
        [self onIdentityRequestSuccess:logoutRequest httpResponse:(MPIdentityHTTPSuccessResponse *)httpResponse completion:completion];
    }];
}

- (void)logoutWithCompletion:(nullable MPIdentityApiResultCallback)completion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self logout:nil completion:completion];
#pragma clang diagnostic pop
}

- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager modify:modifyRequest completion:^(MPIdentityHTTPModifySuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
        [self onModifyRequestSuccess:modifyRequest httpResponse:httpResponse completion:completion];
    }];
}

@end
