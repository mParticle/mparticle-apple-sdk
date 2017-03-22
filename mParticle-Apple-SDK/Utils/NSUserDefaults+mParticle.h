//
//  NSUserDefaults+mParticle.h
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

#import <Foundation/Foundation.h>

@interface NSUserDefaults(mParticle)

- (nullable id)mpObjectForKey:(nonnull NSString *)defaultName;
- (void)setMPObject:(nullable id)value forKey:(nonnull NSString *)defaultName;
- (void)removeMPObjectForKey:(nonnull NSString *)defaultName;
- (void)setMPKey:(nonnull NSString *)key value:(nullable id)obj;

@end
