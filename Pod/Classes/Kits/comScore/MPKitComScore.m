//
//  MPKitComScore.m
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

#if defined(MP_KIT_COMSCORE)

#import "MPKitComScore.h"
#import "MPEvent.h"
#import "MPEnums.h"
#import "CSComScore.h"

typedef NS_ENUM(NSUInteger, MPcomScoreProduct) {
    MPcomScoreProductDirect = 1,
    MPcomScoreProductEnterprise
};

NSString *const ecsCustomerC2 = @"CustomerC2Value";
NSString *const ecsSecret = @"PublisherSecret";
NSString *const ecsUseHTTPS = @"UseHttps";
NSString *const ecsAutoUpdateMode = @"autoUpdateMode";
NSString *const ecsAutoUpdateInterval = @"autoUpdateInterval";
NSString *const escAppName = @"appName";
NSString *const escProduct = @"product";

@interface MPKitComScore()

@property (nonatomic, unsafe_unretained) MPcomScoreProduct product;

@end


@implementation MPKitComScore

- (void)setupWithConfiguration:(NSDictionary *)configuration {
    [CSComScore setCustomerC2:configuration[ecsCustomerC2]];
    [CSComScore setPublisherSecret:configuration[ecsSecret]];
    
    if ([[configuration[ecsAutoUpdateMode] lowercaseString] isEqualToString:@"foreonly"]) {
        [CSComScore enableAutoUpdate:[configuration[ecsAutoUpdateInterval] intValue] foregroundOnly:YES];
    } else if ([[configuration[ecsAutoUpdateMode] lowercaseString] isEqualToString:@"foreback"]) {
        [CSComScore enableAutoUpdate:[configuration[ecsAutoUpdateInterval] intValue] foregroundOnly:NO];
    } else {
        [CSComScore disableAutoUpdate];
    }
    
    if (configuration[ecsUseHTTPS]) {
        BOOL useHTTPS = [[configuration[ecsUseHTTPS] lowercaseString] isEqualToString:@"true"];
        [CSComScore setSecure:useHTTPS];
    }
    
    if (configuration[escAppName]) {
        [CSComScore setAppName:configuration[escAppName]];
    }
    
    if (configuration[escProduct]) {
        self.product = [configuration[escProduct] isEqualToString:@"enterprise"] ? MPcomScoreProductEnterprise : MPcomScoreProductDirect;
    }
}

- (void)setConfiguration:(NSDictionary *)configuration {
    if (!started || ![self isValidConfiguration:configuration]) {
        return;
    }
    
    [super setConfiguration:configuration];
    
    [self setupWithConfiguration:configuration];
}

#pragma mark Private methods
- (BOOL)isValidConfiguration:(NSDictionary *)configuration {
    NSString *customerC2 = configuration[ecsCustomerC2];
    NSString *secret = configuration[ecsSecret];
    
    BOOL validConfiguration = customerC2 != nil && (customerC2.length > 0) &&
                              secret != nil && (secret.length > 0);
    
    return validConfiguration;
}

- (NSDictionary *)convertAllValuesToString:(NSDictionary *)originalDictionary {
    NSMutableDictionary *convertedDictionary = [[NSMutableDictionary alloc] initWithCapacity:originalDictionary.count];
    NSEnumerator *originalEnumerator = [originalDictionary keyEnumerator];
    NSString *key;
    id value;
    Class NSStringClass = [NSString class];
    
    while ((key = [originalEnumerator nextObject])) {
        value = originalDictionary[key];
        
        if ([value isKindOfClass:NSStringClass]) {
            convertedDictionary[key] = value;
        } else {
            convertedDictionary[key] = [NSString stringWithFormat:@"%@", value];
        }
    }
    
    return convertedDictionary;
}

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    self = [super initWithConfiguration:configuration];
    if (!self || ![self isValidConfiguration:configuration]) {
        return nil;
    }
    
    self.product = MPcomScoreProductDirect;
    
    [CSComScore setAppContext];
    
    [self setupWithConfiguration:configuration];

    frameworkAvailable = YES;
    started = YES;
    self.forwardedEvents = YES;
    self.active = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceComScore),
                                   mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceComScore)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });

    return self;
}

- (MPKitExecStatus *)beginSession {
    [CSComScore onUxActive];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)endSession {
    [CSComScore onUxInactive];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    MPKitExecStatus *execStatus;

    if (self.product != MPcomScoreProductEnterprise) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeIncorrectProductVersion];
        return execStatus;
    }
    
    if (event.type == MPEventTypeNavigation) {
        return [self logScreen:event];
    } else {
        NSMutableDictionary *labelsDictionary = [@{@"name":event.name} mutableCopy];
        if (event.info) {
            [labelsDictionary addEntriesFromDictionary:[self convertAllValuesToString:event.info]];
        }
    
        [CSComScore hiddenWithLabels:labelsDictionary];
        
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
        return execStatus;
    }
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    MPKitExecStatus *execStatus;

    if (self.product != MPcomScoreProductEnterprise) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeIncorrectProductVersion];
        return execStatus;
    }
    
    NSMutableDictionary *labelsDictionary = [@{@"name":event.name} mutableCopy];
    if (event.info) {
        [labelsDictionary addEntriesFromDictionary:[self convertAllValuesToString:event.info]];
    }
    
    [CSComScore viewWithLabels:labelsDictionary];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDebugMode:(BOOL)debugMode {
    [CSComScore setDebug:debugMode];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    [CSComScore setEnabled:!optOut];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    MPKitExecStatus *execStatus;

    if (self.product != MPcomScoreProductEnterprise) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeIncorrectProductVersion];
        return execStatus;
    }
    
    if (value != nil) {
        [CSComScore setLabel:key value:value];
    }
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserTag:(NSString *)tag {
    MPKitExecStatus *execStatus;

    if (self.product != MPcomScoreProductEnterprise) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeIncorrectProductVersion];
        return execStatus;
    }
    
    [CSComScore setLabel:tag value:@""];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

@end

#endif
