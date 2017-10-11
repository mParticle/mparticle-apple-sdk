//
//  MPKitSecondTestClass.m
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

#import "MPKitSecondTestClass.h"
#import "MPKitExecStatus.h"

@implementation MPKitSecondTestClass

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;
    if (!self) {
        return nil;
    }
    
    _started = YES;
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

+ (nonnull NSNumber *)kitCode {
    return @314;
}

- (void)deinit {
    
}

- (MPKitExecStatus *)didBecomeActive {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)start {
    _started = YES;
}

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDebugMode:(BOOL)debugMode {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    NSMutableDictionary *tempUserAttributes = self.userAttributes ? [self.userAttributes mutableCopy] : [[NSMutableDictionary alloc] initWithCapacity:1];
    tempUserAttributes[key] = value;
    self.userAttributes = tempUserAttributes;
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

@end
