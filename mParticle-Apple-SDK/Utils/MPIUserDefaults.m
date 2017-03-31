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

static NSString *const MPIUserDefaultsPrefix = @"mParticle::";

@implementation MPIUserDefaults

#pragma mark Private methods
- (NSString *)prefixedKey:(NSString *)key {
    NSString *prefixedKey = [NSString stringWithFormat:@"%@%@", MPIUserDefaultsPrefix, key];
    return prefixedKey;
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
- (BOOL)boolForKey:(nonnull NSString *)key {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

- (nullable NSDictionary<NSString *, id> *)dictionaryRepresentation {
    return [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
}

- (float)floatForKey:(nonnull NSString *)key {
    return [[NSUserDefaults standardUserDefaults] floatForKey:key];
}

- (NSInteger)integerForKey:(nonnull NSString *)key {
    return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}

- (id)mpObjectForKey:(NSString *)key {
    NSString *prefixedKey = [self prefixedKey:key];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefixedKey];
}

- (void)setMPObject:(id)value forKey:(NSString *)key {
    NSString *prefixedKey = [self prefixedKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:prefixedKey];
}

- (nullable id)objectForKey:(nonnull NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)removeMPObjectForKey:(NSString *)key {
    NSString *prefixedKey = [self prefixedKey:key];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:prefixedKey];
}

- (void)synchronize {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Objective-C Literals
- (id)objectForKeyedSubscript:(NSString *const)key {
    return [self mpObjectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
    if (obj) {
        [self setMPObject:obj forKey:key];
    } else {
        [self removeMPObjectForKey:key];
    }
}

@end
