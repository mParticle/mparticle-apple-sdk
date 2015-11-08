//
//  MPKitKahuna.m
//
//  Copyright 2015 mParticle, Inc.
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
#import "KahunaAnalytics.h"

NSString *const khnSecretKey = @"secretKey";
NSString *const khnEventListKey = @"eventList";
NSString *const khnSendTransactionDataKey = @"sendTransactionData";
NSString *const khnTransactionName = @"purchase";
NSString *const khnEventAttributeListKey = @"eventAttributeList";

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
    
    [KahunaAnalytics launchWithKey:configuration[khnSecretKey]];
    [KahunaAnalytics setDeepIntegrationMode:false];
    
    frameworkAvailable = YES;
    started = YES;
    self.forwardedEvents = YES;

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
    [KahunaAnalytics enableLocationServices:KAHRegionMonitoringServices withReason:nil];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)endLocationTracking {
    [KahunaAnalytics clearLocationServicesUserPermissions];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)failedToRegisterForUserNotifications:(NSError *)error {
    [KahunaAnalytics handleNotificationRegistrationFailure:error];
    
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
    
    NSDictionary *userAttributes = [commerceEvent userDefinedAttributes];
    MPCommerceEventKind kindOfCommerceEvent = [commerceEvent kind];
    
    switch (kindOfCommerceEvent) {
        case MPCommerceEventKindProduct:
            if (commerceEvent.action == MPCommerceEventActionPurchase) {
                NSArray *products = [commerceEvent products];
                int sumQuantity = 0;
                
                for (MPProduct *product in products) {
                    sumQuantity += [product.quantity intValue];
                }
                
                int revenueInCents = (int)floor([commerceEvent.transactionAttributes.revenue doubleValue] * 100);
                [KahunaAnalytics trackEvent:eventName withCount:sumQuantity andValue:revenueInCents];
            } else {
                [KahunaAnalytics trackEvent:eventName];
            }
            break;
            
        case MPCommerceEventKindImpression:
            [KahunaAnalytics trackEvent:eventName];
            break;
            
        case MPCommerceEventKindPromotion:
            [KahunaAnalytics trackEvent:eventName];
            break;
            
        default:
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeUnavailable];
            return execStatus;
            break;
    }
    
    if (userAttributes.count > 0) {
        [KahunaAnalytics setUserAttributes:userAttributes];
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    [KahunaAnalytics trackEvent:event.name];

    if (event.info.count > 0) {
        [KahunaAnalytics setUserAttributes:event.info];
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logout {
    [KahunaAnalytics logout];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logTransaction:(NSString *)productName affiliation:(NSString *)affiliation sku:(NSString *)sku unitPrice:(double)unitPrice quantity:(NSInteger)quantity revenueAmount:(double)revenueAmount taxAmount:(double)taxAmount shippingAmount:(double)shippingAmount transactionId:(NSString *)transactionId productCategory:(NSString *)productCategory currencyCode:(NSString *)currencyCode {
    MPKitExecStatus *execStatus;

    if (!_sendTransactions) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }

    int revenueInCents = (int)floor(revenueAmount * 100);
    [KahunaAnalytics trackEvent:khnTransactionName withCount:(int)quantity andValue:revenueInCents];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logTransaction:(MPProduct *)product {
    MPKitExecStatus *execStatus;
    
    if (!_sendTransactions) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    double revenueAmount = product.totalAmount;
    if (revenueAmount == 0.0) {
        revenueAmount = [product.price doubleValue] * [product.quantity doubleValue] + product.shippingAmount + product.taxAmount;
    }
#pragma clang diagnostic pop
    
    int revenueInCents = (int)floor(revenueAmount * 100);
    [KahunaAnalytics trackEvent:khnTransactionName withCount:(int)[product.quantity integerValue] andValue:revenueInCents];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    [KahunaAnalytics handleNotification:userInfo withApplicationState:[UIApplication sharedApplication].applicationState];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [KahunaAnalytics setDeviceToken:deviceToken];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDebugMode:(BOOL)debugMode {
    kitDebugMode = debugMode;
    
    [KahunaAnalytics setDebugMode:debugMode];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    [KahunaAnalytics setUserAttributes:@{key:value}];
    
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
            
        case MPUserIdentityOther:
            kahunaCredential = @"user_id";
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
        [KahunaAnalytics setUserCredentialsWithKey:kahunaCredential andValue:identityString];
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKahuna) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

@end

#endif
