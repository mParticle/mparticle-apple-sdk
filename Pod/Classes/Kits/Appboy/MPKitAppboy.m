//
//  MPKitAppboy.m
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

#if defined(MP_KIT_APPBOY)

#import "MPKitAppboy.h"
#import "MPEvent.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPEnums.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCommerceEventInstruction.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "AppboyKit.h"

NSString *const eabAPIKey = @"apiKey";
NSString *const eabOptions = @"options";

@interface MPKitAppboy() {
    Appboy *appboyInstance;
}

@end


@implementation MPKitAppboy

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration startImmediately:(BOOL)startImmediately {
    self = [super initWithConfiguration:configuration startImmediately:startImmediately];
    if (!self) {
        return nil;
    }
    
    if (!configuration[eabAPIKey]) {
        return nil;
    }

    frameworkAvailable = YES;

    if (startImmediately) {
        [self start];
    }
    
    return self;
}

- (id const)kitInstance {
    return [self started] ? appboyInstance : nil;
}

- (void)start {
    static dispatch_once_t appboyPredicate;
    
    dispatch_once(&appboyPredicate, ^{
        [Appboy startWithApiKey:self.configuration[eabAPIKey]
                  inApplication:[UIApplication sharedApplication]
              withLaunchOptions:self.launchOptions
              withAppboyOptions:self.configuration[eabOptions]];
        
        CFTypeRef appboyRef = CFRetain((__bridge CFTypeRef)[Appboy sharedInstance]);
        appboyInstance = (__bridge Appboy *)appboyRef;
        
        started = YES;
        self.forwardedEvents = YES;
        self.active = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceAppboy),
                                       mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceAppboy)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

- (MPKitExecStatus *)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    [appboyInstance getActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:^{}];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    [appboyInstance.user incrementCustomUserAttribute:key by:[value integerValue]];

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess forwardCount:0];

    if (commerceEvent.action == MPCommerceEventActionPurchase) {
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
        NSString *currency = commerceEvent.currency ? : @"USD";
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
            
            // Strips key/values already being passed to Appboy, plus key/values initialized to default values
            keys = @[kMPExpProductSKU, kMPProductCurrency, kMPExpProductUnitPrice, kMPExpProductQuantity, kMPProductAffiliation, kMPExpProductCategory, kMPExpProductName];
            [properties removeObjectsForKeys:keys];

            [appboyInstance logPurchase:product.sku
                             inCurrency:currency
                                atPrice:[NSDecimalNumber decimalNumberWithDecimal:[product.price decimalValue]]
                           withQuantity:[product.quantity integerValue]
                          andProperties:properties];
            
            [execStatus incrementForwardCount];
        }
    } else {
        NSArray *expandedInstructions = [commerceEvent expandedInstructions];
        
        for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
            [self logEvent:commerceEventInstruction.event];
            [execStatus incrementForwardCount];
        }
    }
    
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    void (^logCustomEvent)(void) = ^{
        [appboyInstance logCustomEvent:event.name withProperties:event.info];

        [event.info enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            [appboyInstance.user setCustomAttributeWithKey:key andStringValue:value];
        }];
    };
    
    if ([NSThread isMainThread]) {
        logCustomEvent();
    } else {
        dispatch_async(dispatch_get_main_queue(), logCustomEvent);
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logTransaction:(NSString *)productName affiliation:(NSString *)affiliation sku:(NSString *)sku unitPrice:(double)unitPrice quantity:(NSInteger)quantity revenueAmount:(double)revenueAmount taxAmount:(double)taxAmount shippingAmount:(double)shippingAmount transactionId:(NSString *)transactionId productCategory:(NSString *)productCategory currencyCode:(NSString *)currencyCode {
    NSString *productId = sku ? sku : productName;
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] initWithCapacity:1];
    if (affiliation.length > 0) {
        properties[kMPProductAffiliation] = affiliation;
    }
    
    if (productName.length > 0) {
        properties[kMPProductName] = productName;
    }
    
    if (productCategory.length > 0) {
        properties[kMPProductCategory] = productCategory;
    }
    
    if (transactionId.length > 0) {
        properties[kMPProductTransactionId] = transactionId;
    }
    
    if (revenueAmount > 0) {
        properties[kMPProductRevenue] = @(revenueAmount);
    }
    
    if (taxAmount > 0) {
        properties[kMPProductTax] = @(taxAmount);
    }
    
    if (shippingAmount > 0) {
        properties[kMPProductShipping] = @(shippingAmount);
    }
    
    [appboyInstance logPurchase:productId
                     inCurrency:currencyCode
                        atPrice:[[NSDecimalNumber alloc] initWithDouble:unitPrice]
                   withQuantity:quantity
                  andProperties:properties];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logTransaction:(MPProduct *)product {
    NSString *productId = product.sku ? product.sku : product.name;
    
    __block NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    NSDictionary *productDictionary = [product beautifiedDictionaryRepresentation];
    if (productDictionary) {
        [properties addEntriesFromDictionary:productDictionary];
    }
    
    NSArray *removeKeys = @[@"ProductSKU", @"CurrencyCode", @"ProductUnitPrice", @"ProductQuantity", @"TransactionAffiliation", @"ProductCategory", @"ProductName",
                            kMPExpProductSKU, kMPProductCurrency, kMPExpProductUnitPrice, kMPExpProductQuantity, kMPProductAffiliation, kMPExpProductCategory, kMPExpProductName];
    [properties removeObjectsForKeys:removeKeys];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [appboyInstance logPurchase:productId
                     inCurrency:product.currency ? : @"USD"
                        atPrice:[NSDecimalNumber decimalNumberWithDecimal:[product.price decimalValue]]
                   withQuantity:[product.quantity integerValue]
                  andProperties:properties];
#pragma clang diagnostic pop
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    [appboyInstance registerApplication:[UIApplication sharedApplication] didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult fetchResult) {}];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    [appboyInstance.user unsetCustomAttributeWithKey:key];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [appboyInstance registerPushToken:[NSString stringWithFormat:@"%@", deviceToken]];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    if (value) {
        [appboyInstance.user setCustomAttributeWithKey:key andStringValue:value];
    } else {
        [appboyInstance.user unsetCustomAttributeWithKey:key];
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    MPKitExecStatus *execStatus = nil;

    switch (identityType) {
        case MPUserIdentityCustomerId: {
            void (^changeUser)(void) = ^ {
                [appboyInstance changeUser:identityString];
            };
            
            if ([NSThread isMainThread]) {
                changeUser();
            } else {
                dispatch_async(dispatch_get_main_queue(), changeUser);
            }
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
        }
            break;
            
        case MPUserIdentityEmail:
            appboyInstance.user.email = identityString;
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
            break;
            
        default:
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeUnavailable];
            break;
    }
    
    return execStatus;
}

@end

#endif
