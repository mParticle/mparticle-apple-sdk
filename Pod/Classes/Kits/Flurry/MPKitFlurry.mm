//
//  MPKitFlurry.mm
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

#if defined(MP_KIT_FLURRY)

#import "MPKitFlurry.h"
#import "MPEnums.h"
#import "MPEvent.h"
#import <CoreLocation/CoreLocation.h>
#include "Hasher.h"
#import "Flurry.h"

@implementation MPKitFlurry

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration startImmediately:(BOOL)startImmediately {
    self = [super initWithConfiguration:configuration startImmediately:startImmediately];
    if (!self) {
        return nil;
    }
    
    if (!configuration[@"apiKey"]) {
        return nil;
    }
    
    frameworkAvailable = YES;

    if (startImmediately) {
        [self start];
    }
    
    return self;
}

- (void)start {
    if ([[self.configuration[@"captureExceptions"] lowercaseString] isEqualToString:@"true"]) {
        [Flurry setCrashReportingEnabled:YES];
    }
    
    [Flurry startSession:self.configuration[@"apiKey"] withOptions:self.launchOptions];
    
    started = YES;
    self.forwardedEvents = YES;
    self.active = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceFlurry),
                                   mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceFlurry)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (MPKitExecStatus *)beginTimedEvent:(MPEvent *)event {
    FlurryEventRecordStatus flurryRecordStatus = FlurryEventFailed;
    
    if (event.info) {
        flurryRecordStatus = [Flurry logEvent:event.name withParameters:event.info timed:YES];
    } else {
        flurryRecordStatus = [Flurry logEvent:event.name timed:YES];
    }
    
    MPKitReturnCode kitReturnCode = flurryRecordStatus != FlurryEventFailed ? MPKitReturnCodeSuccess : MPKitReturnCodeFail;
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:kitReturnCode];
    
    return execStatus;
}

- (MPKitExecStatus *)endTimedEvent:(MPEvent *)event {
    [Flurry endTimedEvent:event.name withParameters:event.info];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    FlurryEventRecordStatus flurryRecordStatus = FlurryEventFailed;
    
    if (event.info) {
        flurryRecordStatus = [Flurry logEvent:event.name withParameters:event.info];
    } else {
        flurryRecordStatus = [Flurry logEvent:event.name];
    }
    
    MPKitReturnCode kitReturnCode = flurryRecordStatus != FlurryEventFailed ? MPKitReturnCodeSuccess : MPKitReturnCodeFail;
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:kitReturnCode];
    
    return execStatus;
}

- (MPKitExecStatus *)logError:(NSString *)message eventInfo:(NSDictionary *)eventInfo {
    NSError *error = [NSError errorWithDomain:message code:1 userInfo:eventInfo];
    [Flurry logError:message message:message error:error];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logException:(NSException *)exception {
    [Flurry logError:[exception name] message:[exception reason] exception:exception];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    [Flurry logPageView];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setLocation:(CLLocation *)location {
    MPKitExecStatus *execStatus;
    
    if ([[self.configuration[@"includeLocation"] lowercaseString] isEqualToString:@"true"]) {
        [Flurry setLatitude:location.coordinate.latitude longitude:location.coordinate.longitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeSuccess];
    } else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeUnavailable];
    }

    return execStatus;
}

- (MPKitExecStatus *)setDebugMode:(BOOL)debugMode {
    [Flurry setDebugLogEnabled:debugMode];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [Flurry addSessionOrigin:sourceApplication withDeepLink:[url absoluteString]];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    MPKitExecStatus *execStatus;
    
    if ([key isEqualToString:mParticleUserAttributeAge]) {
        [Flurry setAge:(int)[value integerValue]];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeSuccess];
    } else if ([key isEqualToString:mParticleUserAttributeGender]) {
        [Flurry setGender:value];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeSuccess];
    } else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeUnavailable];
    }
    
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    MPKitExecStatus *execStatus;
    
    if (identityType == MPUserIdentityCustomerId && identityString.length > 0) {
        NSString *idString = nil;
        if ([self.configuration[@"hashCustomerId"] caseInsensitiveCompare:@"true"]) {
            NSData *identityData = [identityString dataUsingEncoding:NSUTF8StringEncoding];
            
            uint64_t identityHash = mParticle::Hasher::hashFNV1a((const char *)[identityData bytes], (int)[identityData length]);
            idString = [@(identityHash) stringValue];
        } else {
            idString = identityString;
        }
        
        if (idString) {
            [Flurry setUserID:idString];
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeSuccess];
        } else {
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeFail];
        }
    } else {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceFlurry) returnCode:MPKitReturnCodeUnavailable];
    }
    
    return execStatus;
}

@end

#endif
