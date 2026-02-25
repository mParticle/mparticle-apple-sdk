#import "MPKitLeanplum.h"

#if defined(__has_include) && __has_include(<Leanplum/Leanplum.h>)
#import <Leanplum/Leanplum.h>
#else
#import "Leanplum.h"
#endif

// Per Leanplum's docs - you must send email as a user attribute for email campaigns to function.
// https://support.leanplum.com/hc/en-us/articles/217075086-Setup-Email-Messaging#verify-leanplum-has-your-users'-email-addresses
static NSString * const kMPLeanplumEmailUserAttributeKey = @"email";

@implementation MPKitLeanplum

+ (NSNumber *)kitCode {
    return @98;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Leanplum" className:@"MPKitLeanplum"];
    [MParticle registerExtension:kitRegister];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;
    
    NSString *appId = configuration[@"appId"];
    NSString *clientKey = configuration[@"clientKey"];
    NSString *userIdField = configuration[@"userIdField"];
    if (!appId || !clientKey || !userIdField) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
    _configuration = configuration;
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (bool)isPreferredIdentityType: (MPUserIdentity) identityType {
    NSString *userIdField = self.configuration[@"userIdField"];
    if ([userIdField isEqual:@"customerId"]) {
        return identityType == MPUserIdentityCustomerId;
    } else if ([userIdField isEqual:@"email"]) {
        return identityType == MPUserIdentityEmail;
    } else {
        return false;
    }
}

- (NSString*) generateUserId:(NSDictionary *) configuration user:(FilteredMParticleUser*)user {
    NSString *userIdField = configuration[@"userIdField"];
    if ([userIdField isEqual:@"mpid"]) {
        if (user != nil && user.userId != nil && user.userId.integerValue != 0) {
            return [user.userId stringValue];
        } else {
            return nil;
        }
    }
    
    MPUserIdentity idType = 0;
    if ([userIdField isEqual:@"customerId"]) {
        idType = MPUserIdentityCustomerId;
    } else if ([userIdField isEqual:@"email"]) {
        idType = MPUserIdentityEmail;
    } else {
        return nil;
    }
    
    return [user.userIdentities objectForKey:[NSNumber numberWithInt:(int)idType]];
}

- (void)start {
    static dispatch_once_t kitPredicate;
    
    dispatch_once(&kitPredicate, ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserIdentified:) name:mParticleIdentityStateChangeListenerNotification object:nil];
        NSDictionary *identities = [[self currentUser] userIdentities];
        NSString *advertiserId = identities[@(MPIdentityIOSAdvertiserId)];

        if ([MParticle sharedInstance].environment == MPEnvironmentDevelopment) {
            [Leanplum setAppId:self.configuration[@"appId"] withDevelopmentKey:self.configuration[@"clientKey"]];
        } else {
            [Leanplum setAppId:self.configuration[@"appId"] withProductionKey:self.configuration[@"clientKey"]];
        }
        
        NSString *deviceIdType = self.configuration[@"iosDeviceId"];
        if (deviceIdType == nil) {
            deviceIdType = @"";
        }
        if ([deviceIdType isEqualToString:@"idfa"] && advertiserId != nil) {
            [Leanplum setDeviceId:advertiserId];
        } else if ([deviceIdType isEqualToString:@"das"]) {
            [Leanplum setDeviceId:[MParticle sharedInstance].identity.deviceApplicationStamp];
        }
        
        FilteredMParticleUser *user = [self currentUser];
        NSString *userId = [self generateUserId:self.configuration
                                           user:user];
        
        NSString *email = [user.userIdentities objectForKey:[NSNumber numberWithInt:MPUserIdentityEmail]];
        
        NSDictionary<NSString *, id> *attributes = user.userAttributes;
        if (email != nil) {
            if (attributes == nil) {
                attributes = [NSMutableDictionary dictionary];
            }
            [attributes setValue:email forKey:kMPLeanplumEmailUserAttributeKey];
        }
        if (userId && attributes) {
            [Leanplum startWithUserId:userId userAttributes:attributes];
        }
        else if (attributes) {
            [Leanplum startWithUserAttributes:attributes];
        }
        else if (userId) {
            [Leanplum startWithUserId:userId];
        }
        else {
            [Leanplum start];
        }
    });
    
    self->_started = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (id const)kitInstance {
    return nil;
}

- (MPKitAPI *)kitApi {
    if (_kitApi == nil) {
        _kitApi = [[MPKitAPI alloc] init];
    }
    
    return _kitApi;
}

- (MPKitExecStatus *)onUserIdentified:(NSNotification*) notification {
    FilteredMParticleUser *user = [self currentUser];
    NSString *userId = [self generateUserId:self.configuration user:user];
    if (userId != nil) {
        [Leanplum setUserId:userId];
        [Leanplum forceContentUpdate];
        return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    } else {
        return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeFail];
    }
}
 
#pragma mark Application
- (MPKitExecStatus *)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    [Leanplum handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:^(UIBackgroundFetchResult result){
    }];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

#pragma mark User attributes and identities
- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    NSDictionary *attributes = @{key: value};
    [Leanplum setUserAttributes:attributes];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    [Leanplum startWithUserAttributes:@{key: [NSNull null]}];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)onLoginComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self onIdentityComplete:user request:request];
}

- (MPKitExecStatus *)onIdentifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self onIdentityComplete:user request:request];
}

- (MPKitExecStatus *)onModifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self onIdentityComplete:user request:request];
}

- (MPKitExecStatus *)onIdentityComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeSuccess];
    
    NSString *userIdField = self.configuration[@"userIdField"];
    if ([userIdField isEqual:@"customerId"] && request.customerId) {
        [Leanplum setUserId:request.customerId];
    } else if ([userIdField isEqual:@"email"] && request.email) {
        [Leanplum setUserId:request.email];
    } else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeUnavailable];
    }
    
    if (request.email) {
        [self setUserAttribute:kMPLeanplumEmailUserAttributeKey value:request.email];
    }
    
    return execStatus;
}

#pragma mark e-Commerce
- (MPKitExecStatus *)routeCommerceEvent:(MPCommerceEvent *)commerceEvent {
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeSuccess forwardCount:0];
    
    if (commerceEvent.type == MPEventTypePurchase) {
        NSMutableDictionary *baseProductAttributes = [[NSMutableDictionary alloc] init];
        NSDictionary *transactionAttributes = [commerceEvent.transactionAttributes beautifiedDictionaryRepresentation];
        
        if (transactionAttributes) {
            [baseProductAttributes addEntriesFromDictionary:transactionAttributes];
        }
        
        NSDictionary *commerceEventAttributes = [commerceEvent beautifiedAttributes];
        NSArray *keys = @[kMPExpCECheckoutOptions, kMPExpCECheckoutStep, kMPExpCEProductListName, kMPExpCEProductListSource];
        
        for (NSString *key in keys) {
            if (commerceEventAttributes[key]) {
                baseProductAttributes[key] = commerceEventAttributes[key];
            }
        }
        
        NSArray *products = commerceEvent.products;
        NSMutableDictionary *properties;
        
        for (MPProduct *product in products) {
            // Add relevant attributes from the commerce event
            properties = [[NSMutableDictionary alloc] init];
            if (baseProductAttributes.count > 0) {
                [properties addEntriesFromDictionary:baseProductAttributes];
            }
            
            // Add attributes from the product itself
            NSDictionary *productDictionary = [product beautifiedDictionaryRepresentation];
            if (productDictionary) {
                [properties addEntriesFromDictionary:productDictionary];
            }
            
            // Strips key/values already being passed, plus key/values initialized to default values
            keys = @[kMPProductAffiliation, kMPExpProductCategory, kMPExpProductName];
            [properties removeObjectsForKeys:keys];
            
            double value = [product.price doubleValue] * [product.quantity doubleValue];
            
            [Leanplum track:LP_PURCHASE_EVENT withValue:value andInfo:product.name andParameters:properties];
            [execStatus incrementForwardCount];
        }
    } else {
        NSArray *expandedInstructions = [commerceEvent expandedInstructions];
        
        for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
            [self logBaseEvent:commerceEventInstruction.event];
            [execStatus incrementForwardCount];
        }
    }
    
    return execStatus;
}

- (MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(MPEvent *)event {
    [Leanplum track:event.name withValue:increaseAmount andParameters:event.customAttributes];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    [Leanplum didReceiveRemoteNotification:userInfo];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
#if TARGET_OS_IOS == 1
    [Leanplum didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
#endif

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

#pragma mark Events

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        return [self routeCommerceEvent:(MPCommerceEvent *)event];
    } else {
        return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeUnavailable];
    }
}

- (MPKitExecStatus *)routeEvent:(MPEvent *)event {
    [Leanplum track:event.name withParameters:event.customAttributes];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)logScreen:(nonnull MPEvent *)event {
    [Leanplum advanceTo:event.name withParameters:event.customAttributes];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLeanplum) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

#pragma helper methods

- (FilteredMParticleUser *)currentUser {
    return [[self kitApi] getCurrentUserWithKit:self];
}

@end
