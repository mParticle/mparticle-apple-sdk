//
//  MPKitCrittercism.m
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

#if defined(MP_KIT_CRITTERCISM)

#import "MPKitCrittercism.h"
#import "MPEnums.h"
#import "MPEvent.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPEnums.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCommerceEventInstruction.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "Crittercism.h"

@implementation MPKitCrittercism

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    self = [super initWithConfiguration:configuration];
    if (!self) {
        return nil;
    }
    
    NSString *appId = configuration[@"appid"];
    
    BOOL validConfiguration = appId != nil && (NSNull *)appId != [NSNull null] && (appId.length > 0);
    if (!validConfiguration) {
        return nil;
    }
    
    [Crittercism enableWithAppID:appId];
    
    frameworkAvailable = YES;
    started = YES;
    self.forwardedEvents = YES;
    self.active = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceCrittercism),
                                   mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceCrittercism)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
    
    return self;
}

- (MPKitExecStatus *)leaveBreadcrumb:(MPEvent *)event {
    [Crittercism leaveBreadcrumb:event.name];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceCrittercism) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceCrittercism) returnCode:MPKitReturnCodeSuccess forwardCount:0];
    
    if (commerceEvent.action == MPCommerceEventActionPurchase || commerceEvent.action == MPCommerceEventActionRefund) {
        NSString *name = [commerceEvent actionNameForAction:commerceEvent.action];
        int revenueInCents = (int)floor([commerceEvent.transactionAttributes.revenue doubleValue] * 100);
        [Crittercism beginTransaction:name withValue:revenueInCents];
        
        if (commerceEvent.action == MPCommerceEventActionPurchase) {
            [Crittercism endTransaction:name];
        } else {
            [Crittercism failTransaction:name];
        }
        
        [execStatus incrementForwardCount];
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
    [Crittercism leaveBreadcrumb:event.name];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceCrittercism) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    [Crittercism leaveBreadcrumb:event.name];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceCrittercism) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logException:(NSException *)exception {
    [Crittercism logHandledException:exception];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceCrittercism) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setLocation:(CLLocation *)location {
    [Crittercism updateLocation:location];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceCrittercism) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    [Crittercism setOptOutStatus:optOut];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceCrittercism) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    [Crittercism setValue:value forKey:key];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceCrittercism) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    MPKitReturnCode returnCode;
    
    if (identityType == MPUserIdentityCustomerId) {
        [Crittercism setUsername:identityString];
        returnCode = MPKitReturnCodeSuccess;
    } else {
        returnCode = MPKitReturnCodeUnavailable;
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceCrittercism) returnCode:returnCode];
    return execStatus;
}

@end

#endif
