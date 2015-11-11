//
//  MPKitLocalytics.m
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

#if defined(MP_KIT_LOCALYTICS)

#import "MPKitLocalytics.h"
#import "MPEnums.h"
#import "MPEvent.h"
#import <CoreLocation/CoreLocation.h>
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCommerceEventInstruction.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "Localytics.h"

@interface MPKitLocalytics() {
    BOOL multiplyByOneHundred;
}

@property (nonatomic, strong) NSMutableDictionary *customDimensions;

@end


@implementation MPKitLocalytics

- (NSMutableDictionary *)customDimensions {
    if (_customDimensions) {
        return _customDimensions;
    }
    
    _customDimensions = [[NSMutableDictionary alloc] initWithCapacity:1];
    return _customDimensions;
}

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration startImmediately:(BOOL)startImmediately {
    self = [super initWithConfiguration:configuration startImmediately:startImmediately];
    if (!self) {
        return nil;
    }
    
    if (!configuration[@"appKey"]) {
        return nil;
    }
    
    NSArray *dimensionsMapping = configuration[@"customDimensions"];
    if (dimensionsMapping) {
        for (NSDictionary *dimensionMap in dimensionsMapping) {
            NSRange dimensionRange = [dimensionMap[@"value"] rangeOfString:@"Dimension "];
            
            if (dimensionRange.location != NSNotFound) {
                NSString *key = dimensionMap[@"map"];
                NSNumber *value = @([[dimensionMap[@"value"] substringFromIndex:NSMaxRange(dimensionRange)] integerValue]);
                
                if (key && value) {
                    self.customDimensions[key] = value;
                }
            }
        }
    }
    
    multiplyByOneHundred = [configuration[@"trackClvAsRawValue"] caseInsensitiveCompare:@"true"] == NSOrderedSame;

    frameworkAvailable = YES;
    
    if (startImmediately) {
        [self start];
    }
    
    return self;
}

- (void)start {
    [Localytics autoIntegrate:self.configuration[@"appKey"] launchOptions:self.launchOptions];
    
    started = YES;
    self.forwardedEvents = YES;
    self.active = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceLocalytics),
                                   mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceLocalytics)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (MPKitExecStatus *)beginSession {
    [Localytics openSession];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)endSession {
    [Localytics closeSession];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess forwardCount:0];

    switch (commerceEvent.action) {
        case MPCommerceEventActionRefund:
        case MPCommerceEventActionPurchase: {
            NSDictionary *commerceEventAttributes = [commerceEvent beautifiedAttributes];
            NSString *eventName = [NSString stringWithFormat:@"eCommerce - %@", [[commerceEvent actionNameForAction:commerceEvent.action] capitalizedString]];
            long revenue = lround([commerceEvent.transactionAttributes.revenue doubleValue] * (multiplyByOneHundred ? 100 : 1));
            revenue = commerceEvent.action == MPCommerceEventActionPurchase ? : labs(revenue) * -1;
            
            [Localytics tagEvent:eventName attributes:commerceEventAttributes customerValueIncrease:@(revenue)];
            [execStatus incrementForwardCount];
        }
            break;
            
        default: {
            NSArray *expandedInstructions = [commerceEvent expandedInstructions];
            
            for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
                [self logEvent:commerceEventInstruction.event];
                [execStatus incrementForwardCount];
            }
        }
            break;
    }
    
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    if (event.info) {
        [Localytics tagEvent:event.name attributes:event.info];
    } else {
        [Localytics tagEvent:event.name];
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(MPEvent *)event {
    long amount = lround(increaseAmount * (multiplyByOneHundred ? 100 : 1));
    [Localytics tagEvent:event.name attributes:event.info customerValueIncrease:@(amount)];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    [Localytics tagScreen:event.name];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDebugMode:(BOOL)debugMode {
    [Localytics setLoggingEnabled:debugMode];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [Localytics setPushToken:deviceToken];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    [Localytics handlePushNotificationOpened:userInfo];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setLocation:(CLLocation *)location {
    [Localytics setLocation:location.coordinate];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    [Localytics setOptedOut:optOut];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    NSNumber *customDimensionValue = self.customDimensions[key];
    
    if (customDimensionValue) {
        [Localytics setValue:value forCustomDimension:[customDimensionValue integerValue]];
    } else {
        if ([key isEqualToString:mParticleUserAttributeFirstName]) {
            [Localytics setCustomerFirstName:value];
        } else if ([key isEqualToString:mParticleUserAttributeLastName]) {
            [Localytics setCustomerLastName:value];
        } else {
            [Localytics setValue:value forProfileAttribute:key];
        }
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    MPKitExecStatus *execStatus;
    NSNumber *customDimensionValue = self.customDimensions[key];
    
    if (customDimensionValue) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeCannotExecute];
        return execStatus;
    }
    
    [Localytics incrementValueBy:[value integerValue] forProfileAttribute:key];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    [Localytics deleteProfileAttribute:key];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    switch (identityType) {
        case MPUserIdentityCustomerId:
            [Localytics setCustomerId:identityString];
            break;
            
        case MPUserIdentityEmail:
            [Localytics setCustomerEmail:identityString];
            break;
            
        default: {
            NSArray *identifierStrings = @[@"Other", @"CustomerId", @"Facebook", @"Twitter", @"Google", @"Microsoft", @"Yahoo", @"Email", @"Alias", @"FacebookCustomAudienceId"];
            NSString *identifier = identifierStrings[(NSInteger)identityType];
            [Localytics setValue:identityString forIdentifier:identifier];
        }
            break;
    }

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

@end

#endif
