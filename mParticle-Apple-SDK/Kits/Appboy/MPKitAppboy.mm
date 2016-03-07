//
//  MPKitAppboy.mm
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
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPLogger.h"
#include "MPHasher.h"
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
        
        NSString *eventTypeString = [@(event.type) stringValue];
        NSDictionary *eventInfo = [event.info transformValuesToString];
        
        for (NSString *key in eventInfo) {
            NSString *eventTypePlusNamePlusKey = [[NSString stringWithFormat:@"%@%@%@", eventTypeString, event.name, key] lowercaseString];
            NSString *hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([eventTypePlusNamePlusKey cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                                     encoding:NSUTF8StringEncoding];
            
            NSDictionary *forwardUserAttributes;
            
            // Delete from array
            forwardUserAttributes = self.configuration[@"ear"];
            if (forwardUserAttributes[hashValue]) {
                [appboyInstance.user removeFromCustomAttributeArrayWithKey:forwardUserAttributes[hashValue] value:eventInfo[key]];
            }
            
            // Add to array
            forwardUserAttributes = self.configuration[@"eaa"];
            if (forwardUserAttributes[hashValue]) {
                [appboyInstance.user addToCustomAttributeArrayWithKey:forwardUserAttributes[hashValue] value:eventInfo[key]];
            }
            
            // Add key/value pair
            forwardUserAttributes = self.configuration[@"eas"];
            if (forwardUserAttributes[hashValue]) {
                [appboyInstance.user setCustomAttributeWithKey:forwardUserAttributes[hashValue] andStringValue:eventInfo[key]];
            }
        }
    };
    
    if ([NSThread isMainThread]) {
        logCustomEvent();
    } else {
        dispatch_async(dispatch_get_main_queue(), logCustomEvent);
    }
    
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

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    MPKitReturnCode returnCode;
    
    if (optOut) {
        [appboyInstance.user setEmailNotificationSubscriptionType:ABKUnsubscribed];
        returnCode = MPKitReturnCodeSuccess;
    } else {
        returnCode = MPKitReturnCodeCannotExecute;
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:returnCode];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    MPKitExecStatus *execStatus;
    
    if ([key isEqualToString:mParticleUserAttributeFirstName]) {
        appboyInstance.user.firstName = value;
    } else if ([key isEqualToString:mParticleUserAttributeLastName]) {
        appboyInstance.user.lastName = value;
    } else if ([key isEqualToString:mParticleUserAttributeAge]) {
        NSDate *now = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear fromDate:now];
        NSInteger age = 0;
        
        @try {
            age = [value integerValue];
        } @catch (NSException *exception) {
            MPLogError(@"Invalid age: %@", value);
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeFail];
            return execStatus;
        }
        
        NSDateComponents *birthComponents = [[NSDateComponents alloc] init];
        birthComponents.year = dateComponents.year - age;
        birthComponents.month = 01;
        birthComponents.day = 01;
        
        appboyInstance.user.dateOfBirth = [calendar dateFromComponents:birthComponents];
    } else if ([key isEqualToString:mParticleUserAttributeCountry]) {
        appboyInstance.user.country = value;
    } else if ([key isEqualToString:mParticleUserAttributeCity]) {
        appboyInstance.user.homeCity = value;
    } else if ([key isEqualToString:mParticleUserAttributeGender]) {
        [appboyInstance.user setCustomAttributeWithKey:@"gender" andStringValue:value];
    } else if ([key isEqualToString:mParticleUserAttributeMobileNumber] || [key isEqualToString:@"$MPUserMobile"]) {
        appboyInstance.user.phone = value;
    } else if (value) {
        if ([value containsString:@"$"]) {
            NSMutableString *editedValue = [value mutableCopy];
            [editedValue replaceOccurrencesOfString:@"$" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, value.length)];
            value = editedValue;
        }
        
        [appboyInstance.user setCustomAttributeWithKey:key andStringValue:value];
    } else {
        [appboyInstance.user unsetCustomAttributeWithKey:key];
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
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
