//
//  MPKitWootric.m
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

#if defined(MP_KIT_WOOTRIC)

#import "MPKitWootric.h"
#import <WootricSDK/WootricSDK.h>

@implementation MPKitWootric

- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    self = [super initWithConfiguration:configuration];
    if (!self) {
        return nil;
    }

    NSString *accountToken = configuration[@"accountToken"];
    NSString *clientSecret = configuration[@"clientSecret"];
    NSString *clientId = configuration[@"clientId"];

    [Wootric configureWithClientID:clientId clientSecret:clientSecret accountToken:accountToken];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceWootric),
                                   mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceWootric)};

        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];

        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });

    return self;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    switch (identityType) {
        case MPUserIdentityCustomerId:
            [Wootric setEndUserEmail:identityString];
            break;

        case MPUserIdentityEmail:
            [Wootric setEndUserEmail:identityString];
            break;

        default:
            break;
    }

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceWootric) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    if (value != nil) {
        NSDictionary *currentProperties = [Wootric endUserProperties];
        NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:currentProperties];
        newProperties[key] = value;
        [Wootric setEndUserProperties:newProperties];
    }

    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceWootric) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}


@end

#endif