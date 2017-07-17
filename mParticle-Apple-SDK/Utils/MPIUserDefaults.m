//
//  MPIUserDefaults.m
//
//  Copyright 2017 mParticle, Inc.
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

#import "MPIUserDefaults.h"
#import "MPUtils.h"

static NSString *const NSUserDefaultsPrefix = @"mParticle::";

@implementation MPIUserDefaults

#pragma mark Private methods
- (NSArray<NSString *> *)userSpecificKeys {
    NSArray<NSString *> *userSpecificKeys = @[
                                              @"lud",               /* kMPAppLastUseDateKey */
                                              @"lc",                /* kMPAppLaunchCountKey */
                                              @"lcu",               /* kMPAppLaunchCountSinceUpgradeKey */
                                              @"ua",                /* kMPUserAttributeKey */
                                              @"ui",                /* kMPUserIdentityArrayKey */
                                              @"ck",                /* kMPRemoteConfigCookiesKey */
                                              @"ltv",               /* kMPLifeTimeValueKey */
                                              @"is_ephemeral"       /* kMPIsEphemeralKey */
                                              ];
    return userSpecificKeys;
}

- (NSString *)globalKeyForKey:(NSString *)key {
    NSString *globalKey = [NSString stringWithFormat:@"%@%@", NSUserDefaultsPrefix, key];
    return globalKey;
}

- (NSString *)userKeyForKey:(NSString *)key userId:(NSNumber *)userId {
    NSString *userKey = [NSString stringWithFormat:@"%@%@::%@", NSUserDefaultsPrefix, userId, key];
    return userKey;
}

- (BOOL)isUserSpecificKey:(NSString *)keyName {
    NSArray<NSString *> *userSpecificKeys = [self userSpecificKeys];
    
    if ([userSpecificKeys containsObject:keyName]) {
        return YES;
    }
    else {
        return NO;
    }
}

- (NSString *)prefixedKey:(NSString *)keyName userId:(NSNumber *)userId {
    NSString *prefixedKey = nil;
    if (![self isUserSpecificKey:keyName]) {
        prefixedKey = [self globalKeyForKey:keyName];
        return prefixedKey;
    }
    else {
        NSString *prefixedKey = [self userKeyForKey:keyName userId:userId];
        return prefixedKey;
    }
}

#pragma mark Public class methods
+ (nonnull instancetype)standardUserDefaults {
    static MPIUserDefaults *standardUserDefaults = nil;
    static dispatch_once_t predicate;

    dispatch_once(&predicate, ^{
        standardUserDefaults = [[MPIUserDefaults alloc] init];
    });

    return standardUserDefaults;
}

#pragma mark Public methods

- (id)mpObjectForKey:(NSString *)key userId:(NSNumber *)userId {
    NSString *prefixedKey = [self prefixedKey:key userId:userId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefixedKey];
}

- (void)setMPObject:(id)value forKey:(NSString *)key userId:(nonnull NSNumber *)userId {
    NSString *prefixedKey = [self prefixedKey:key userId:userId];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:prefixedKey];
}

- (void)removeMPObjectForKey:(NSString *)key userId:(nonnull NSNumber *)userId {
    NSString *prefixedKey = [self prefixedKey:key userId:userId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:prefixedKey];
}

- (void)removeMPObjectForKey:(NSString *)key {
    [self removeMPObjectForKey:key userId:[MPUtils mpId]];
}

- (void)synchronize {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)migrateUserKeysWithUserId:(NSNumber *)userId {
    NSArray<NSString *> *userSpecificKeys = [self userSpecificKeys];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userSpecificKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *globalKey = [self globalKeyForKey:key];
        NSString *userKey = [self userKeyForKey:key userId:userId];
        id value = [userDefaults objectForKey:globalKey];
        [userDefaults setObject:value forKey:userKey];
        [userDefaults removeObjectForKey:globalKey];
    }];
    [userDefaults synchronize];
}

#pragma mark Objective-C Literals
- (id)objectForKeyedSubscript:(NSString *const)key {
    if ([key isEqualToString:@"mpid"]) {
        return [self mpObjectForKey:key userId:@0];
    }
    return [self mpObjectForKey:key userId:[MPUtils mpId]];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    if (obj) {
        [self setMPObject:obj forKey:key userId:[MPUtils mpId]];
    } else {
        [self removeMPObjectForKey:key userId:[MPUtils mpId]];
    }
}


@end
