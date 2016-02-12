//
//  MPKitRegister.h
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
#import "MPKitProtocol.h"

@interface MPKitRegister : NSObject

@property (nonatomic, strong, nonnull, readonly) NSNumber *code;
@property (nonatomic, strong, nullable) id<MPKitProtocol> wrapperInstance;
@property (nonatomic, strong, nonnull, readonly) NSString *name;
@property (nonatomic, strong, nonnull, readonly) NSString *className;
@property (nonatomic, unsafe_unretained, readonly) BOOL active;
@property (nonatomic, unsafe_unretained, readonly) BOOL startImmediately;

- (nullable instancetype)initWithCode:(nonnull NSNumber *)code name:(nonnull NSString *)name className:(nonnull NSString *)className startImmediately:(BOOL)startImmediately __attribute__((objc_designated_initializer));
- (nullable instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration;
- (void)freeWrapperInstance;
- (void)setBracketConfiguration:(nullable NSDictionary *)bracketConfiguration;

@end
