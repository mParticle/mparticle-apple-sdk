//
//  MPKitKochava.m
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

#if defined(MP_KIT_KOCHAVA)

#import "MPKitKochava.h"
#import "MPKochavaSpatialCoordinate.h"
#import "MPEnums.h"
#import "MPTrackAndAd.h"

NSString *const kvAppId = @"appId";
NSString *const kvCurrency = @"currency";
NSString *const kvUseCustomerId = @"useCustomerId";
NSString *const kvIncludeOtherUserIds = @"passAllOtherUserIdentities";
NSString *const kvRetrieveAttributionData = @"retrieveAttributionData";
NSString *const kvEnableLogging = @"enableLogging";
NSString *const kvLimitAdTracking = @"limitAdTracking";
NSString *const kvLogScreenFormat = @"Viewed %@";
NSString *const kvEcommerce = @"eCommerce";

NSString *const MPUserIdentityIdKey = @"i";
NSString *const MPUserIdentityTypeKey = @"n";

static MPKochavaTracker *kochavaTracker = nil;

@interface MPKitKochava() {
    BOOL isNewUser;
}

@end


@implementation MPKitKochava

#pragma mark Accessors and private methods
- (void)kochavaTracker:(void (^)(MPKochavaTracker *const kochavaTracker))completionHandler {
    static dispatch_once_t kochavaPredicate;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_once(&kochavaPredicate, ^{
            NSMutableDictionary *kochavaInfo = [@{@"kochavaAppId":self.configuration[kvAppId]
                                                  } mutableCopy];
            
            if (self.configuration[kvCurrency]) {
                kochavaInfo[@"currency"] = self.configuration[kvCurrency];
            }
            
            if (self.configuration[kvLimitAdTracking]) {
                kochavaInfo[@"limitAdTracking"] = [self.configuration[kvLimitAdTracking] boolValue] ? @"1" : @"0";
            }
            
            if (self.configuration[kvEnableLogging]) {
                kochavaInfo[@"enableLogging"] = [self.configuration[kvEnableLogging] boolValue] ? @"1" : @"0";
            }
            
            if (self.configuration[kvRetrieveAttributionData]) {
                kochavaInfo[@"retrieveAttribution"] = [self.configuration[kvRetrieveAttributionData] boolValue] ? @"1" : @"0";
            }
            
            // Don't know whether setting this property in the dictionary will work, since it is not in the documentation
            if (isNewUser) {
                kochavaInfo[@"isNewUser"] = isNewUser ? @"1" : @"0";
            }
            
            CFTypeRef kochavaTrackRef = CFRetain((__bridge CFTypeRef)[[NSClassFromString(@"KochavaTracker") alloc] initKochavaWithParams:kochavaInfo]);
            kochavaTracker = (__bridge MPKochavaTracker *)kochavaTrackRef;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceKochava),
                                           mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceKochava)};
                
                [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                    object:nil
                                                                  userInfo:userInfo];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
        });
        
        completionHandler(kochavaTracker);
    });
}

- (void)identityLinkCustomerId {
    if (!self.userIdentities || self.userIdentities.count == 0) {
        return;
    }
    
    NSMutableDictionary *identityInfo = [[NSMutableDictionary alloc] initWithCapacity:self.userIdentities.count];
    NSString *identityKey;
    MPUserIdentity userIdentity;
    for (NSDictionary *userIdentityDictionary in self.userIdentities) {
        userIdentity = [userIdentityDictionary[MPUserIdentityTypeKey] integerValue];
        
        switch (userIdentity) {
            case MPUserIdentityCustomerId:
                identityKey = @"CustomerId";
                break;
                
            default:
                continue;
                break;
        }
        
        identityInfo[identityKey] = userIdentityDictionary[MPUserIdentityIdKey];
    }
    
    if (identityInfo.count > 0) {
        [self kochavaTracker:^(MPKochavaTracker *const kochavaTracker) {
            [kochavaTracker identityLinkEvent:(NSDictionary *)identityInfo];
        }];
    }
}

- (void)identityLinkOtherUserIds {
    if (!self.userIdentities || self.userIdentities.count == 0) {
        return;
    }
    
    NSMutableDictionary *identityInfo = [[NSMutableDictionary alloc] initWithCapacity:self.userIdentities.count];
    NSString *identityKey;
    MPUserIdentity userIdentity;
    for (NSDictionary *userIdentityDictionary in self.userIdentities) {
        userIdentity = [userIdentityDictionary[MPUserIdentityTypeKey] integerValue];
        
        switch (userIdentity) {
            case MPUserIdentityEmail:
                identityKey = @"Email";
                break;
                
            case MPUserIdentityOther:
                identityKey = @"OtherId";
                break;
                
            case MPUserIdentityFacebook:
                identityKey = @"Facebook";
                break;
                
            case MPUserIdentityTwitter:
                identityKey = @"Twitter";
                break;
                
            case MPUserIdentityGoogle:
                identityKey = @"Google";
                break;
                
            case MPUserIdentityYahoo:
                identityKey = @"Yahoo";
                break;
                
            case MPUserIdentityMicrosoft:
                identityKey = @"Microsoft";
                break;
                
            default:
                continue;
                break;
        }
        
        identityInfo[identityKey] = userIdentityDictionary[MPUserIdentityIdKey];
    }
    
    if (identityInfo.count > 0) {
        [self kochavaTracker:^(MPKochavaTracker *const kochavaTracker) {
            [kochavaTracker identityLinkEvent:(NSDictionary *)identityInfo];
        }];
    }
}

- (void)retrieveAttributionWithCompletionHandler:(void(^)(NSDictionary *attribution))completionHandler {
    [self kochavaTracker:^(MPKochavaTracker *const kochavaTracker) {
        NSDictionary *attribution = [kochavaTracker retrieveAttribution];
        completionHandler(attribution);
    }];
}

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    self = [super initWithConfiguration:configuration];
    if (!self) {
        return nil;
    }
    
    if (!configuration[kvAppId]) {
        return nil;
    }
    
    isNewUser = NO;
    
    __weak MPKitKochava *weakSelf = self;
    [self kochavaTracker:^(MPKochavaTracker *const kochavaTracker) {
        __strong MPKitKochava *strongSelf = weakSelf;
        
        if (!strongSelf) {
            return;
        }
        
        if (kochavaTracker) {
            strongSelf->frameworkAvailable = YES;
            strongSelf->started = YES;
            strongSelf.forwardedEvents = YES;
            strongSelf.active = YES;

            if ([configuration[kvUseCustomerId] boolValue] || [configuration[kvIncludeOtherUserIds] boolValue]) {
                [strongSelf synchronize];
            }
        }
    }];
    
    return self;
}

- (id const)kitInstance {
    return [self started] ? kochavaTracker : nil;
}

- (void)setConfiguration:(NSDictionary *)configuration {
    [super setConfiguration:configuration];
}

- (MPKitExecStatus *)setDebugMode:(BOOL)debugMode {
    kitDebugMode = debugMode;
    [self kochavaTracker:^(MPKochavaTracker *const kochavaTracker) {
        [kochavaTracker enableConsoleLogging:debugMode];
    }];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKochava) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    [self kochavaTracker:^(MPKochavaTracker *const kochavaTracker) {
        [kochavaTracker setLimitAdTracking:optOut];
    }];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKochava) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    MPKitExecStatus *execStatus = nil;
    if (!identityString) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKochava) returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    NSDictionary *userIdentityDictionary = @{MPUserIdentityTypeKey:@(identityType),
                                             MPUserIdentityIdKey:identityString};
    
    if ([self.userIdentities containsObject:userIdentityDictionary]) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKochava) returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
    self.userIdentities = nil;
    cachedUserIdentities = self.userIdentities;
    
    if (identityType == MPUserIdentityCustomerId) {
        if ([self.configuration[kvUseCustomerId] boolValue]) {
            [self identityLinkCustomerId];
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKochava) returnCode:MPKitReturnCodeSuccess];
        }
    } else {
        if ([self.configuration[kvIncludeOtherUserIds] boolValue]) {
            [self identityLinkOtherUserIds];
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceKochava) returnCode:MPKitReturnCodeSuccess];
        }
    }
    
    if (!execStatus) {
        execStatus = [[MPKitExecStatus alloc] init];
    }
    
    return execStatus;
}

- (void)synchronize {
    if ([cachedUserIdentities isEqualToArray:self.userIdentities]) {
        return;
    }
    
    cachedUserIdentities = self.userIdentities;
    
    if ([self.configuration[kvUseCustomerId] boolValue]) {
        [self identityLinkCustomerId];
    }
    
    if ([self.configuration[kvIncludeOtherUserIds] boolValue]) {
        [self identityLinkOtherUserIds];
    }
}

@end

#endif
