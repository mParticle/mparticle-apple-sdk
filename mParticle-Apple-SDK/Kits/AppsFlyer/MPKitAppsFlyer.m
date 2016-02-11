//
//  MPKitAppsFlyer.m
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

#if defined(MP_KIT_APPSFLYER)

#import "MPKitAppsFlyer.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCommerceEventInstruction.h"
#import "MPEvent.h"
#import "MPProduct.h"
#import "MPTransactionAttributes.h"
#import "AppsFlyerTracker.h"

NSString *const afAppleAppId = @"appleAppId";
NSString *const afDevKey = @"devKey";

static AppsFlyerTracker *appsFlyerTracker = nil;

@implementation MPKitAppsFlyer

- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    self = [super initWithConfiguration:configuration];
    if (!self) {
        return nil;
    }
    
    NSString *appleAppId = configuration[afAppleAppId];
    NSString *devKey = configuration[afDevKey];
    if (!appleAppId || !devKey) {
        return nil;
    }
    
    appsFlyerTracker = [AppsFlyerTracker sharedTracker];
    appsFlyerTracker.appleAppID = appleAppId;
    appsFlyerTracker.appsFlyerDevKey = devKey;
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center removeObserver:self];
    [center addObserver:self
               selector:@selector(didBecomeActive)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];

    frameworkAvailable = YES;
    started = YES;
    self.forwardedEvents = YES;
    self.active = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceAppsFlyer),
                                   mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceAppsFlyer)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
    
    return self;
}

- (void)didBecomeActive {
    if (self.started && self.active) {
        [[AppsFlyerTracker sharedTracker] trackAppLaunch];
    }
}

- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url sourceApplication:(nonnull NSString *)sourceApplication annotation:(nullable id)annotation {
    [appsFlyerTracker handleOpenURL:url sourceApplication:sourceApplication withAnnotaion:annotation];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^__nonnull)(NSArray * __nullable restorableObjects))restorationHandler {
    [[AppsFlyerTracker sharedTracker] continueUserActivity:userActivity restorationHandler:restorationHandler];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}
- (nonnull MPKitExecStatus *)didUpdateUserActivity:(nonnull NSUserActivity *)userActivity {
    [[AppsFlyerTracker sharedTracker] didUpdateUserActivity:userActivity];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)receivedUserNotification:(nonnull NSDictionary *)userInfo {
    [appsFlyerTracker handlePushNotification:userInfo];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType {
    MPKitExecStatus *execStatus;
    if (identityType == MPUserIdentityCustomerId) {
        [appsFlyerTracker setCustomerUserID:identityString];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    } else if (identityType == MPUserIdentityEmail) {
        [appsFlyerTracker setUserEmails:@[identityString] withCryptType:EmailCryptTypeNone];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    } else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeFail];
    }
    return execStatus;
}

- (nonnull MPKitExecStatus *)logCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus;
    MPCommerceEventAction action = commerceEvent.action;
    if (    action == MPCommerceEventActionAddToCart
        ||  action == MPCommerceEventActionAddToWishList
        ||  action == MPCommerceEventActionCheckout
        ||  action == MPCommerceEventActionPurchase) {
        
        NSMutableDictionary *values = [NSMutableDictionary dictionary];
        if (commerceEvent.currency) {
            values[AFEventParamCurrency] = commerceEvent.currency;
        }
        
        if (action == MPCommerceEventActionAddToCart || action == MPCommerceEventActionAddToWishList) {
            NSArray<MPProduct *> *products = commerceEvent.products;
            if (products && [products count] != 0) {
                execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess forwardCount:0];
                NSString *appsFlyerEventName = action == MPCommerceEventActionAddToCart ? AFEventAddToCart : AFEventAddToWishlist;
                for (MPProduct *product in products) {
                    NSMutableDictionary *productValues = [values mutableCopy];
                    if (product.price) {
                        productValues[AFEventParamPrice] = product.price;
                    }
                    if (product.quantity) {
                        productValues[AFEventParamQuantity] = product.quantity;
                    }
                    if (product.sku) {
                        productValues[AFEventParamContentId] = product.sku;
                    }
                    if (product.category) {
                        productValues[AFEventParamContentType] = product.category;
                    }
                    [appsFlyerTracker trackEvent:appsFlyerEventName withValues:productValues];
                    [execStatus incrementForwardCount];
                }
            }
            else {
                execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeRequirementsNotMet];
            }
        } else {
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
            NSString *appsFlyerEventName = action == MPCommerceEventActionCheckout ? AFEventInitiatedCheckout : AFEventPurchase;
            if (commerceEvent.count) {
                values[AFEventParamQuantity] = @(commerceEvent.count);
            }
            NSNumber *revenue = commerceEvent.transactionAttributes.revenue;
            if (revenue) {
                NSString *appsFlyerParamName = MPCommerceEventActionPurchase ? AFEventParamRevenue : AFEventParamPrice;
                values[appsFlyerParamName] = revenue;
            }
            [appsFlyerTracker trackEvent:appsFlyerEventName withValues:values];
        }
    }
    else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess forwardCount:0];
        NSArray *expandedInstructions = [commerceEvent expandedInstructions];
        for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
            [self logEvent:commerceEventInstruction.event];
            [execStatus incrementForwardCount];
        }
    }
    return execStatus;
}

- (nonnull MPKitExecStatus *)logEvent:(nonnull MPEvent *)event {
    NSString *eventName = event.name;
    NSDictionary *eventValues = event.info;
    [appsFlyerTracker trackEvent:eventName withValues:eventValues];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)setOptOut:(BOOL)optOut {
    appsFlyerTracker.deviceTrackingDisabled = optOut;
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppsFlyer) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

@end

#endif