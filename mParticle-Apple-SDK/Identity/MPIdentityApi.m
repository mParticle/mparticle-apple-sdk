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

@interface MPIdentityApi ()

@property (nonatomic, strong) MPIdentityApiManager *apiManager;
@property(nonatomic, strong, readwrite, nonnull) MParticleUser *currentUser;

@end

@interface MParticle ()

@property (nonatomic, strong, nonnull) MPBackendController *backendController;

- (nullable NSDictionary <NSString *, id> *)userAttributes;

@end

@interface MPBackendController ()

- (NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentities;

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

- (MParticleUser *)userFromIdentifier:(NSNumber *)identifier {
    MParticleUser *user = [[MParticleUser alloc] init];

    NSMutableArray<NSDictionary<NSString *, id> *> *userIdentitiesArray = [[MParticle sharedInstance].backendController userIdentitiesForUserId:identifier];
    NSMutableDictionary *userIdentities = [NSMutableDictionary dictionary];
    [userIdentitiesArray enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *identity = obj[@"i"];
        NSNumber *type = obj[@"n"];
        
        [userIdentities setObject:identity forKey:type];
    }];
    NSDictionary<NSString *, id> *userAttributes = [[MParticle sharedInstance].backendController userAttributesForUserId:identifier];
    
    user.userId = identifier;
    user.userIdentities = userIdentities;
    user.userAttributes = userAttributes;
    return user;
}

- (void)onIdentityRequestSuccess:(MPIdentityApiRequest *)request httpResponse:(MPIdentityHTTPSuccessResponse *) httpResponse completion:(MPIdentityApiResultCallback)completion {
    
    NSNumber *previousMPID = [MPUtils mpId];
    
    MPIdentityApiResult *apiResult = [[MPIdentityApiResult alloc] init];
    MParticleUser *user = [self userFromIdentifier:httpResponse.mpid];
    apiResult.user = user;
    self.currentUser = user;
    
    if (httpResponse.mpid.intValue == previousMPID.intValue) {
        completion(apiResult, nil);
        return;
    }
    
    [MPUtils setMpid:httpResponse.mpid];
    
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
    _currentUser = [self userFromIdentifier:mpid];
    return _currentUser;
}

- (void)identify:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager identify:identifyRequest completion:^(MPIdentityHTTPSuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
        [self onIdentityRequestSuccess:identifyRequest httpResponse:httpResponse completion:completion];
    }];
}

- (void)identifyWithCompletion:(nullable MPIdentityApiResultCallback)completion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self identify:nil completion:completion];
#pragma clang diagnostic pop
}

- (void)login:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager loginRequest:loginRequest completion:^(MPIdentityHTTPSuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
        [self onIdentityRequestSuccess:loginRequest httpResponse:httpResponse completion:completion];
    }];
}

- (void)loginWithCompletion:(nullable MPIdentityApiResultCallback)completion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self login:nil completion:completion];
#pragma clang diagnostic pop
}

- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager logout:logoutRequest completion:^(MPIdentityHTTPSuccessResponse * _Nonnull httpResponse, NSError * _Nullable error) {
        [self onIdentityRequestSuccess:logoutRequest httpResponse:httpResponse completion:completion];
    }];
}

- (void)logoutWithCompletion:(nullable MPIdentityApiResultCallback)completion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self logout:nil completion:completion];
#pragma clang diagnostic pop
}

- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager modify:modifyRequest completion:^(NSError * _Nullable error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

@end
