#import "MPNetworkCommunication.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPIdentityApiRequest.h"
#import "mParticle.h"
#import "MPEnums.h"
#import "MPIdentityDTO.h"
@import mParticle_Apple_SDK_Swift;

@implementation MPNetworkCommunication_PRIVATE (ObjCBoundary)

- (void)identify:(MPIdentityApiRequest *_Nonnull)identifyRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    MPUserDefaults *userDefaults = self.host.userDefaults;
    if (!userDefaults[kMPATT] && identifyRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }

    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:identifyRequest];
    [self identityRequestToEndpoint:MPEndpointIdentityIdentify requestDictionary:[request dictionaryRepresentation] blockOtherRequests:YES completion:completion];
}

- (void)login:(MPIdentityApiRequest *_Nullable)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    MPUserDefaults *userDefaults = self.host.userDefaults;
    if (!userDefaults[kMPATT] && loginRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }

    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:loginRequest];
    [self identityRequestToEndpoint:MPEndpointIdentityLogin requestDictionary:[request dictionaryRepresentation] blockOtherRequests:YES completion:completion];
}

- (void)logout:(MPIdentityApiRequest *_Nullable)logoutRequest completion:(nullable
                                                                          MPIdentityApiManagerCallback)completion {
    MPUserDefaults *userDefaults = self.host.userDefaults;
    if (!userDefaults[kMPATT] && logoutRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }

    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:logoutRequest];
    [self identityRequestToEndpoint:MPEndpointIdentityLogout requestDictionary:[request dictionaryRepresentation] blockOtherRequests:YES completion:completion];
}

- (void)modify:(MPIdentityApiRequest *_Nonnull)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion {
    MPUserDefaults *userDefaults = self.host.userDefaults;
    if (!userDefaults[kMPATT] && modifyRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }

    NSMutableArray *identityChanges = [NSMutableArray array];

    NSDictionary *identitiesDictionary = modifyRequest.identities;
    NSDictionary *existingIdentities = [MParticle sharedInstance].identity.currentUser.identities;

    [identitiesDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull identityType, NSString *value, BOOL * _Nonnull stop) {
        NSString *oldValue = existingIdentities[identityType];

        if ((NSNull *)value == [NSNull null]) {
            value = nil;
        }

        if (!oldValue || ![value isEqualToString:oldValue]) {
            MPIdentity userIdentity = (MPIdentity)[identityType intValue];
            NSString *stringType = [MPIdentityHTTPIdentities stringForIdentityType:userIdentity];
            MPIdentityHTTPIdentityChange *identityChange = [[MPIdentityHTTPIdentityChange alloc] initWithOldValue:oldValue value:value identityType:stringType];
            [identityChanges addObject:identityChange];
        }
    }];

    [self modifyWithIdentityChanges:identityChanges blockOtherRequests:YES completion:completion];

}

- (void)modifyDeviceID:(NSString *_Nonnull)deviceIdType value:(NSString *_Nonnull)value oldValue:(NSString *_Nonnull)oldValue {
    NSMutableArray *identityChanges = [NSMutableArray array];
    MPIdentityHTTPIdentityChange *identityChange = [[MPIdentityHTTPIdentityChange alloc] initWithOldValue:oldValue value:value identityType:deviceIdType];
    [identityChanges addObject:identityChange];
    [self modifyWithIdentityChanges:identityChanges blockOtherRequests:NO completion:nil];
}

- (void)modifyWithIdentityChanges:(NSArray *)identityChanges blockOtherRequests:(BOOL)blockOtherRequests completion:(nullable MPIdentityApiManagerModifyCallback)completion {

    if (identityChanges == nil || identityChanges.count == 0) {
        if (completion) {
            completion([[MPIdentityHTTPModifySuccessResponse alloc] init], nil);
        }
        return;
    }

    MPIdentityHTTPModifyRequest *request = [[MPIdentityHTTPModifyRequest alloc] initWithIdentityChanges:[identityChanges copy]];
    [self identityRequestToEndpoint:MPEndpointIdentityModify requestDictionary:[request dictionaryRepresentation] blockOtherRequests:blockOtherRequests completion:^(MPIdentityHTTPBaseSuccessResponse * _Nullable httpResponse, NSError * _Nullable error) {
        if (completion) {
            completion((MPIdentityHTTPModifySuccessResponse *)httpResponse, error);
        }
    }];
}

@end
