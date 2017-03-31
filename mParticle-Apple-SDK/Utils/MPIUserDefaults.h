//
//  MPIUserDefaults.h
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

#import <Foundation/Foundation.h>

@interface MPIUserDefaults : NSObject

+ (nonnull instancetype)standardUserDefaults;
- (BOOL)boolForKey:(nonnull NSString *)key;
- (nullable NSDictionary<NSString *, id> *)dictionaryRepresentation;
- (float)floatForKey:(nonnull NSString *)key;
- (NSInteger)integerForKey:(nonnull NSString *)key;
- (nullable id)mpObjectForKey:(nonnull NSString *)key;
- (void)setMPObject:(nullable id)value forKey:(nonnull NSString *)key;
- (nullable id)objectForKey:(nonnull NSString *)key;
- (void)removeMPObjectForKey:(nonnull NSString *)key;
- (nullable id)objectForKeyedSubscript:(nonnull NSString *const)key;
- (void)setObject:(nullable id)obj forKeyedSubscript:(nonnull NSString *)key;
- (void)synchronize;

@end
