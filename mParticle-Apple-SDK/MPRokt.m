//
//  MPRokt.m
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 4/22/25.
//

#import "MPRokt.h"
#import "mParticle.h"
#import "MPForwardQueueParameters.h"
#import "MPILogger.h"
#import "MPIConstants.h"

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;

@end

@implementation MPRoktEventCallback
@end

@implementation MPRoktEmbeddedView
@end

@implementation MPRoktConfig
@end

@implementation MPRokt

- (void)selectPlacements:(NSString *)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
    [self selectPlacements:identifier attributes:attributes embeddedViews:nil config:nil callbacks:nil];
}

- (void)selectPlacements:(NSString *)identifier
              attributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes
           embeddedViews:(NSDictionary<NSString *, MPRoktEmbeddedView *> * _Nullable)embeddedViews
                  config:(MPRoktConfig * _Nullable)config
               callbacks:(MPRoktEventCallback * _Nullable)callbacks {
    MParticleUser *currentUser = [MParticle sharedInstance].identity.currentUser;
    
    // If email is passed in as an attribute and it's different than the existing identity, identify with it
    [self confirmUser:attributes user:currentUser completion:^(MParticleUser *_Nullable resolvedUser) {
        NSArray<NSDictionary<NSString *, NSString *> *> *attributeMap = [self getRoktPlacementAttributesMapping];

        // If attributeMap is nil the kit hasn't been initialized
        if (attributeMap) {
            NSMutableDictionary *mappedAttributes = attributes.mutableCopy;
            for (NSDictionary<NSString *, NSString *> *map in attributeMap) {
                NSString *mapFrom = map[@"map"];
                NSString *mapTo = map[@"value"];
                if (mappedAttributes[mapFrom]) {
                    NSString * value = mappedAttributes[mapFrom];
                    [mappedAttributes removeObjectForKey:mapFrom];
                    mappedAttributes[mapTo] = value;
                }
            }
            for (NSString *key in mappedAttributes) {
                if (![key isEqual:@"sandbox"]) {
                    [resolvedUser setUserAttribute:key value:mappedAttributes[key]];
                }
            }
            
            dispatch_async([MParticle messageQueue], ^{
                // Forwarding call to kits
                MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
                [queueParameters addParameter:identifier];
                [queueParameters addParameter:[self confirmSandboxAttribute:mappedAttributes]];
                [queueParameters addParameter:embeddedViews];
                [queueParameters addParameter:config];
                [queueParameters addParameter:callbacks];
                
                SEL roktSelector = @selector(executeWithIdentifier:attributes:embeddedViews:config:callbacks:filteredUser:);
                [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                          event:nil
                                                                     parameters:queueParameters
                                                                    messageType:MPMessageTypeEvent
                                                                       userInfo:nil
                ];
            });
        } else {
            MPILogVerbose(@"[MParticle.Rokt selectPlacements: not performed since Kit not configured");
        }
    }];
}

- (void)purchaseFinalized:(NSString * _Nonnull)placementId catalogItemId:(NSString * _Nonnull)catalogItemId success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Forwarding call to kits
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:placementId];
        [queueParameters addParameter:catalogItemId];
        [queueParameters addParameter:@(success)];
        
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(purchaseFinalized:catalogItemId:success:)
                                                                  event:nil
                                                             parameters:queueParameters
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

- (void)events:(NSString * _Nonnull)identifier onEvent:(void (^ _Nullable)(MPRoktEvent * _Nonnull))onEvent {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Forwarding call to kits
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:identifier];
        [queueParameters addParameter:onEvent];

        SEL roktSelector = @selector(events:onEvent:);
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                  event:nil
                                                                 parameters:queueParameters
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

- (void)close {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Forwarding call to kits
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:@selector(close)
                                                                  event:nil
                                                             parameters:nil
                                                            messageType:MPMessageTypeEvent
                                                               userInfo:nil
        ];
    });
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)getRoktPlacementAttributesMapping {
    NSArray<NSDictionary<NSString *, NSString *> *> *attributeMap = nil;
    
    // Get the kit configuration
    NSArray<NSDictionary *> *kitConfigs = [MParticle sharedInstance].kitContainer_PRIVATE.originalConfig.copy;
    NSDictionary *roktKitConfig;
    for (NSDictionary *kitConfig in kitConfigs) {
        if (kitConfig[@"id"] != nil && [kitConfig[@"id"] integerValue] == 181) {
            roktKitConfig = kitConfig;
        }
    }
    
    // Return nil if no Rokt Kit configuration found
    if (!roktKitConfig) {
        MPILogVerbose(@"Rokt kit configuration not found");
        return nil;
    }
    
    // Get the placement attributes map
    NSString *strAttributeMap;
    NSData *dataAttributeMap;
    // Rokt Kit is available though there may not be an attribute map
    attributeMap = @[];
    if (roktKitConfig[kMPPlacementAttributesMapping] != [NSNull null]) {
        strAttributeMap = [roktKitConfig[kMPPlacementAttributesMapping] stringByRemovingPercentEncoding];
        dataAttributeMap = [strAttributeMap dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if (dataAttributeMap != nil) {
        // Convert it to an array of dictionaries
        NSError *error = nil;
        
        @try {
            attributeMap = [NSJSONSerialization JSONObjectWithData:dataAttributeMap options:kNilOptions error:&error];
        } @catch (NSException *exception) {
        }
        
        if (attributeMap && !error) {
            NSLog(@"%@", attributeMap);
        } else {
            NSLog(@"%@", error);
        }
    }
    
    return attributeMap;
}

- (NSDictionary<NSString *, NSString *> *)confirmSandboxAttribute:(NSDictionary<NSString *, NSString *> * _Nullable)attributes {
    NSMutableDictionary<NSString *, NSString *> *finalAttributes = attributes.mutableCopy;
    NSString *sandboxKey = @"sandbox";
    
    // Determine the value of the sandbox attribute based off the current environment
    NSString *sandboxValue = ([[MParticle sharedInstance] environment] == MPEnvironmentDevelopment) ? @"true" : @"false";
    
    if (finalAttributes != nil) {
        // Only set sandbox if it`s not set by the client
        if (![finalAttributes.allKeys containsObject:sandboxKey]) {
            finalAttributes[sandboxKey] = sandboxValue;
        }
    } else {
        finalAttributes = [[NSMutableDictionary alloc] initWithDictionary:@{sandboxKey: sandboxValue}];
    }
    
    return finalAttributes;
}

- (void)confirmUser:(NSDictionary<NSString *, NSString *> * _Nullable)attributes user:(MParticleUser * _Nullable)user completion:(void (^)(MParticleUser *_Nullable))completion {
    NSString *email = attributes[@"email"];
    NSString *hashedEmail = attributes[@"emailsha256"];
    
    if ((email && ![email isEqualToString:user.identities[@(MPIdentityEmail)]]) || (hashedEmail && ![hashedEmail isEqualToString: user.identities[@(MPIdentityOther)]])) {
        // If there is an existing email or hashed email but it doesn't match the what was passed in, warn the customer
        if (email && user.identities[@(MPIdentityEmail)]) {
            NSLog(@"The existing email on the user (%@) does not match the email passed in to `selectPlacements:` (%@). Please remember to sync the email identity to mParticle as soon as you receive it. We will now identify the user before contuing to `selectPlacements:`", user.identities[@(MPIdentityEmail)], email);
        } else if (hashedEmail && user.identities[@(MPIdentityOther)]) {
            NSLog(@"The existing hashed email on the user (%@) does not match the email passed in to `selectPlacements:` (%@). Please remember to sync the email identity to mParticle as soon as you receive it. We will now identify the user before contuing to `selectPlacements:`", user.identities[@(MPIdentityOther)], hashedEmail);
        }
        
        MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithUser:user];
        [identityRequest setIdentity:email identityType:MPIdentityEmail];
        [identityRequest setIdentity:hashedEmail identityType:MPIdentityOther];
        
        [[[MParticle sharedInstance] identity] identify:identityRequest completion:^(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error) {
            if (error) {
                NSLog(@"Failed to sync email from selectPlacement to user: %@", error);
                completion(user);
            } else {
                NSLog(@"Updated user identity based off selectPlacement's attributes: %@", apiResult.user.identities);
                completion(apiResult.user);
            }
        }];
    } else {
        completion(user);
    }
}

@end
