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

@interface MPIdentityApi ()

@property (nonatomic, strong) MPIdentityApiManager *apiManager;

@end

@interface MPIdentityApiResult ()

@property(nonatomic, strong, readwrite, nonnull) MParticleUser *user;

@end

@interface MParticleUser ()

@property(nonatomic, strong, readwrite, nullable) NSNumber *userId;

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

    NSMutableArray<NSDictionary<NSString *, id> *> *userIdentitiesArray = [MParticle sharedInstance].backendController.userIdentities;
    NSMutableDictionary *userIdentities = [NSMutableDictionary dictionary];
    [userIdentitiesArray enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *identity = obj[@"i"];
        NSNumber *type = obj[@"n"];
        
        [userIdentities setObject:identity forKey:type];
    }];
    NSDictionary<NSString *, id> *userAttributes = [[MParticle sharedInstance] userAttributes];
    
    user.userId = identifier;
    user.userIdentities = userIdentities;
    user.userAttributes = userAttributes;
    return user;
}

- (void)didChangeToIdentifier:(NSNumber *)newMPID completion:(MPIdentityApiResultCallback)completion {
//    NSNumber *currentIdentifier = [MParticle sharedInstance].identity.currentUser.userId;
//    NSNumber *newIdentifier = apiResult.user.userId;
//    if (currentIdentifier.intValue != newIdentifier.intValue) {
//        MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
//        userDefaults[@"mpid"] = 
//    }
    
    MParticleUser *user = [self userFromIdentifier:newMPID];
    _currentUser = user;
    
    if (user) {
        NSDictionary *userInfo = @{mParticleUserKey:user};
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleIdentityStateChangeListenerNotification object:nil userInfo:userInfo];
        MPSession *session = [MParticle sharedInstance].backendController.session;
        [session.sessionUserIds addObject:newMPID];
        [[MPPersistenceController sharedInstance] updateSession:session];
    }
    
    MPIdentityApiResult *apiResult = [[MPIdentityApiResult alloc] init];
    apiResult.user = user;
    completion(apiResult, nil);
}

- (MParticleUser *)currentUser {
    if (_currentUser) {
        return _currentUser;
    }
    
//    NSNumber *mpid = [MPStateMachine sharedInstance].consumerInfo.mpId;
    NSNumber *mpid = [MPUtils mpId];
    _currentUser = [self userFromIdentifier:mpid];
    return _currentUser;
}

- (void)identify:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager identify:identifyRequest completion:^(NSNumber * _Nullable newMPID, NSError * _Nullable error) {
        [self didChangeToIdentifier:newMPID completion:completion];
    }];
}

- (void)login:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager loginRequest:loginRequest completion:^(NSNumber * _Nullable newMPID, NSError * _Nullable error) {
        [self didChangeToIdentifier:newMPID completion:completion];
    }];
}

- (void)loginWithCompletion:(nullable MPIdentityApiResultCallback)completion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self login:nil completion:completion];
#pragma clang diagnostic pop
}

- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiResultCallback)completion {
    [_apiManager logout:logoutRequest completion:^(NSNumber * _Nullable newMPID, NSError * _Nullable error) {
        [self didChangeToIdentifier:newMPID completion:completion];
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
