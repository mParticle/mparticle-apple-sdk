//
//  MPKitBranchMetrics.m
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

#if defined(MP_KIT_BRANCHMETRICS)

#import "MPKitBranchMetrics.h"
#import "MPEnums.h"
#import "MPEvent.h"
#import "Branch.h"

NSString *const ekBMAppKey = @"branchKey";
NSString *const ekBMAForwardScreenViews = @"forwardScreenViews";

@interface MPKitBranchMetrics() {
    Branch *branchInstance;
    BOOL forwardScreenViews;
}

@end


@implementation MPKitBranchMetrics

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration startImmediately:(BOOL)startImmediately {
    self = [super initWithConfiguration:configuration startImmediately:startImmediately];
    if (!self) {
        return nil;
    }
    
    NSString *branchKey = configuration[ekBMAppKey];
    branchInstance = nil;
    
    BOOL validConfiguration = branchKey != nil && (NSNull *)branchKey != [NSNull null] && (branchKey.length > 0);
    if (!validConfiguration) {
        return nil;
    }
    
    forwardScreenViews = [configuration[ekBMAForwardScreenViews] boolValue];
    frameworkAvailable = YES;
    
    if (startImmediately) {
        [self start];
    }
    
    return self;
}

- (id const)kitInstance {
    return [self started] ? branchInstance : nil;
}

- (void)start {
    static dispatch_once_t branchMetricsPredicate;
    
    dispatch_once(&branchMetricsPredicate, ^{
        NSString *branchKey = [self.configuration[ekBMAppKey] copy];
        branchInstance = [Branch getInstance:branchKey];
        
        [branchInstance initSessionWithLaunchOptions:self.launchOptions isReferrable:YES andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableDictionary *userInfo = [@{mParticleKitInstanceKey:@(MPKitInstanceBranchMetrics),
                                                   mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceBranchMetrics),
                                                   @"branchKey":branchKey} mutableCopy];
                
                if (params && params.count > 0) {
                    userInfo[@"params"] = params;
                }
                
                if (error) {
                    userInfo[@"error"] = error;
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                    object:nil
                                                                  userInfo:userInfo];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
        }];
        
        started = YES;
        self.forwardedEvents = YES;
    });
}

- (MPKitExecStatus *)logout {
    [branchInstance logout];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceBranchMetrics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    if (event.info.count > 0) {
        [branchInstance userCompletedAction:event.name withState:event.info];
    } else {
        [branchInstance userCompletedAction:event.name];
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceBranchMetrics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    MPKitExecStatus *execStatus;

    if (!forwardScreenViews) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceBranchMetrics) returnCode:MPKitReturnCodeUnavailable];
        return execStatus;
    }
    
    NSString *actionName = [NSString stringWithFormat:@"Viewed %@", event.name];
    
    if (event.info.count > 0) {
        [branchInstance userCompletedAction:actionName withState:event.info];
    } else {
        [branchInstance userCompletedAction:actionName];
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceBranchMetrics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    MPKitExecStatus *execStatus;
    
    if (identityType != MPUserIdentityCustomerId || identityString.length == 0) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceBranchMetrics) returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
    [branchInstance setIdentity:identityString];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceBranchMetrics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

@end

#endif
