//
//  MPIdentityApiManager.m
//

#import "MPIdentityApiManager.h"
#import "MPConnector.h"
#import "MPIConstants.h"

NSString *identityHost = @"identity.mparticle.com";
NSString *path = @"/v1";

@interface MPIdentityApiManager ()

@property (nonatomic, strong) NSString *context;

@end

@implementation MPIdentityApiManager

- (void)sendRequestForAction:(NSString *)action request:(MPIdentityApiRequest *)identityRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", @"https://", identityHost, path, action]];
    MPConnector *connector = [[MPConnector alloc] init];
//    NSString *message = nil;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *clientSDK = [NSMutableDictionary dictionary];
    
#if TARGET_OS_IOS == 1
    clientSDK[@"platform"] = @"ios";
#elif TARGET_OS_TVOS == 1
    clientSDK[@"platform"] = @"tvos";
#endif
    
    clientSDK[@"sdk_vendor"] = @"mparticle";
    clientSDK[@"sdk_version"] = kMParticleSDKVersion;
    
    dictionary[@"client_sdk"] = clientSDK;
    
    dictionary[@"known_identities"] = [identityRequest dictionaryRepresentation];
    
    dictionary[@"context"] = _context;
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    
    [connector asyncPostDataFromURL:url message:(NSString *)[NSNull null] serializedParams:data completionHandler:^(NSData * _Nullable data, NSError * _Nullable error, NSTimeInterval downloadTime, NSHTTPURLResponse * _Nullable httpResponse) {
        if (error) {
            completion(nil, error);
            return;
        }
        if (httpResponse.statusCode > 199 && httpResponse.statusCode < 300) {
            NSNumber *mpid = nil;
            
            _context = nil; //TODO
            completion(mpid, nil);
        }
    }];
}

- (void)identify:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    //TODO
}

- (void)loginRequest:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    //TODO
}

- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    //TODO
}

- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion {
    //TODO
}

@end
