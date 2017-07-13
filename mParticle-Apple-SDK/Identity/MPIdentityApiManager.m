//
//  MPIdentityApiManager.m
//

#import "MPIdentityApiManager.h"
#import "MPConnector.h"
#import "MPIConstants.h"
#import "MPNetworkCommunication.h"
#import "MPBackendController.h"
#import "mParticle.h"

@interface MParticle ()

@property (nonatomic, strong, nonnull) MPBackendController *backendController;

@end


@interface MPIdentityApiManager ()

@property (nonatomic, strong) NSString *context;

@end

@implementation MPIdentityApiManager

- (void)identify:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    [[MParticle sharedInstance].backendController.networkCommunication identify:identifyRequest completion:^(NSNumber * _Nullable newMPID, NSError * _Nullable error) {
        
    }];
}

- (void)loginRequest:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    [[MParticle sharedInstance].backendController.networkCommunication login:loginRequest completion:^(NSNumber * _Nullable newMPID, NSError * _Nullable error) {
        
    }];

}

- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    [[MParticle sharedInstance].backendController.networkCommunication logout:logoutRequest completion:^(NSNumber * _Nullable newMPID, NSError * _Nullable error) {
        
    }];
}

- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion {
    //TODO: implement modify
}

@end
