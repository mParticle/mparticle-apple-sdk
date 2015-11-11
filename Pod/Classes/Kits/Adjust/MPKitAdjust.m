//
//  MPKitAdjust.m
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

#if defined(MP_KIT_ADJUST)

#import "MPKitAdjust.h"
#import "MPEnums.h"
#import "Adjust.h"

@implementation MPKitAdjust

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    self = [super initWithConfiguration:configuration];
    if (!self) {
        return nil;
    }
    
    NSString *appToken = configuration[@"appToken"];
    
    BOOL validConfiguration = appToken != nil && (NSNull *)appToken != [NSNull null] && (appToken.length > 0);
    if (!validConfiguration) {
        return nil;
    }
    
    NSString *adjEnvironment = [configuration[@"mpEnv"] integerValue] == MPEnvironmentProduction ? ADJEnvironmentProduction : ADJEnvironmentSandbox;
    
    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:appToken
                                                environment:adjEnvironment];
    
    [Adjust appDidLaunch:adjustConfig];
    
    frameworkAvailable = YES;
    started = YES;
    self.forwardedEvents = YES;
    self.active = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceAdjust),
                                   mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceAdjust)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });

    return self;
}

- (void)setConfiguration:(NSDictionary *)configuration {
    [super setConfiguration:configuration];
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    [Adjust setEnabled:!optOut];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAdjust) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [Adjust setDeviceToken:deviceToken];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAdjust) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

@end

#endif
