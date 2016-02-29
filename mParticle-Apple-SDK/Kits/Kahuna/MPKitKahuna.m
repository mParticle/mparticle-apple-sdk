//
//  MPKitKahuna.m
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if defined(MP_KIT_KAHUNA)

#import "MPKitKahuna.h"
#import "MPEnums.h"
#import "MPEvent.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPTransactionAttributes.h"
#import "MPPromotion.h"
#import "MPLogger.h"
#import "mParticle.h"
#import <Kahuna/Kahuna.h>

NSString *const khnSecretKey = @"secretKey";
NSString *const khnSendTransactionDataKey = @"sendTransactionData";
NSString *const khnSdkWrapper = @"mParticle";

@interface MPKitKahuna()

@property (nonatomic, strong, readonly) NSMutableDictionary *defaultEventNames;
@property (nonatomic, unsafe_unretained) BOOL sendTransactions;

@end


@implementation MPKitKahuna

@synthesize defaultEventNames = _defaultEventNames;

- (NSMutableDictionary *)defaultEventNames {
    if (_defaultEventNames) {
        return _defaultEventNames;
    }
    
    _defaultEventNames = [[NSMutableDictionary alloc] init];
    
    return _defaultEventNames;
}

- (void)setupWithConfiguration:(NSDictionary *)configuration {
    id sendTransactionData = configuration[khnSendTransactionDataKey];
    if (sendTransactionData) {
        if ([sendTransactionData isKindOfClass:[NSString class]]) {
            _sendTransactions = [[(NSString *)sendTransactionData lowercaseString] isEqualToString:@"true"];
        } else {
            _sendTransactions = [sendTransactionData boolValue];
        }
    } else {
        _sendTransactions = NO;
    }
    
    NSDictionary *mapOfKeyToEventType = @{@"defaultAddToCartEventName":@(MPEventTypeAddToCart),
                                          @"defaultRemoveFromCartEventName":@(MPEventTypeRemoveFromCart),
                                          @"defaultCheckoutEventName":@(MPEventTypeCheckout),
                                          @"defaultCheckoutOptionEventName":@(MPEventTypeCheckoutOption),
                                          @"defaultProductClickName":@(MPEventTypeClick),
                                          @"defaultViewDetailEventName":@(MPEventTypeViewDetail),
                                          @"defaultPurchaseEventName":@(MPEventTypePurchase),
                                          @"defaultRefundEventName":@(MPEventTypeRefund),
                                          @"defaultPromotionViewEventName":@(MPEventTypePromotionView),
                                          @"defaultPromotionClickEventName":@(MPEventTypePromotionClick),
                                          @"defaultAddToWishlistEventName":@(MPEventTypeAddToWishlist),
                                          @"defaultRemoveFromWishlistEventName":@(MPEventTypeRemoveFromWishlist),
                                          @"defaultImpressionEventName":@(MPEventTypeImpression)
                                          };
    
    [mapOfKeyToEventType enumerateKeysAndObjectsUsingBlock:^(NSString *defaultEventNameKey, NSNumber *eventTypeNumber, BOOL *stop) {
        NSString *defaultEventName = configuration[defaultEventNameKey];
        if (defaultEventName) {
            self.defaultEventNames[eventTypeNumber] = defaultEventName;
        }
    }];
}

- (void)setConfiguration:(NSDictionary *)configuration {
    if (!started) {
        return;
    }
    
    [super setConfiguration:configuration];
    
    [self setupWithConfiguration:configuration];
}

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    self = [super initWithConfiguration:configuration];
    if (!self) {
        return nil;
    }
    
    if (!configuration[khnSecretKey]) {
        return nil;
    }
    
    [self setupWithConfiguration:configuration];
    [[Kahuna sharedInstance] performSelector:@selector(setSDKWrapper:withVersion:) withObject:khnSdkWrapper withObject:[MParticle sharedInstance].version];
    [Kahuna launchWithKey:configuration[khnSecretKey]];
    [Kahuna setDeepIntegrationMode:false];
    
    frameworkAvailable = YES;
    started = YES;
    self.forwardedEvents = YES;
    self.active = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceKahuna),
                                   mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceKahuna)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
    
    return self;
}

- (MPKitExecStatus *)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter {
    [Kahuna enableLocationServices:KAHRegionMonitoringServices withReason:nil];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)endLocationTracking {
    [Kahuna disableLocationServices:KAHRegionMonitoringServices];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)failedToRegisterForUserNotifications:(NSError *)error {
    [Kahuna handleNotificationRegistrationFailure:error];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    NSString *eventName = self.defaultEventNames[@(commerceEvent.type)];
    MPKitExecStatus *execStatus;
    
    if (!eventName) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
    MPCommerceEventKind kindOfCommerceEvent = [commerceEvent kind];
    int sumQuantity = -1;
    int revenueInCents = -1;
    switch (kindOfCommerceEvent) {
        case MPCommerceEventKindProduct:
            if (commerceEvent.action == MPCommerceEventActionPurchase) {
                NSArray *products = [commerceEvent products];
                
                sumQuantity = 0;
                for (MPProduct *product in products) {
                    sumQuantity += [product.quantity intValue];
                }
                
                revenueInCents = (int)floor([commerceEvent.transactionAttributes.revenue doubleValue] * 100);
            }
            break;
            
        case MPCommerceEventKindImpression:
        case MPCommerceEventKindPromotion:
            break;
            
        default:
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeUnavailable];
            return execStatus;
            break;
    }
    
    [self trackKahunaEvent:eventName withCount:sumQuantity withValue:revenueInCents withProperties:[commerceEvent userDefinedAttributes]];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    [self trackKahunaEvent:event.name withCount:-1 withValue:-1 withProperties:event.info];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logout {
    [Kahuna logout];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    [Kahuna handleNotification:userInfo withApplicationState:[UIApplication sharedApplication].applicationState];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [Kahuna setDeviceToken:deviceToken];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDebugMode:(BOOL)debugMode {
    kitDebugMode = debugMode;
    
    [Kahuna setDebugMode:debugMode];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    [Kahuna setUserAttributes:@{key:value}];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    NSString *kahunaCredential = nil;
    switch (identityType) {
        case MPUserIdentityCustomerId:
            kahunaCredential = KAHUNA_CREDENTIAL_USERNAME;
            break;
            
        case MPUserIdentityEmail:
            kahunaCredential = KAHUNA_CREDENTIAL_EMAIL;
            break;
            
        case MPUserIdentityFacebook:
            kahunaCredential = KAHUNA_CREDENTIAL_FACEBOOK;
            break;
            
        case MPUserIdentityTwitter:
            kahunaCredential = KAHUNA_CREDENTIAL_TWITTER;
            break;
            
        case MPUserIdentityGoogle:
            kahunaCredential = KAHUNA_CREDENTIAL_GOOGLE_PLUS;
            break;
            
        case MPUserIdentityFacebookCustomAudienceId:
            kahunaCredential = @"fb_app_user_id";
            break;
            
        case MPUserIdentityMicrosoft:
            kahunaCredential = @"msft_id";
            break;
            
        case MPUserIdentityYahoo:
            kahunaCredential = @"yahoo_id";
            break;
            
        case MPUserIdentityOther:
            kahunaCredential = @"mp_other_id";
            break;
            
        default:
            break;
    }
    
    MPKitExecStatus *execStatus;
    
    if (!kahunaCredential) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
    if (identityString) {
        KahunaUserCredentials *kuc = [Kahuna getUserCredentials];
        [kuc addCredential:kahunaCredential withValue:identityString];
        NSError *error = nil;
        [Kahuna loginWithCredentials:kuc error:&error];
        if (error) {
            MPLogDebug(@"Kahuna Login Error : %@", error.description);
        }
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void) trackKahunaEvent:(NSString*)eventName withCount:(int)count withValue:(int)value withProperties:(NSDictionary*) properties {
    if (!eventName) return;
    
    KAHEventBuilder *builder = [KAHEventBuilder eventWithName:eventName];
    [builder setPurchaseCount:count andPurchaseValue:value];
    for (NSString* eachKey in properties) {
        NSString *eachValue = properties[eachKey];
        [builder addProperty:eachKey withValue:eachValue];
    }
    
    [Kahuna track:[builder build]];
}

@end

#endif
