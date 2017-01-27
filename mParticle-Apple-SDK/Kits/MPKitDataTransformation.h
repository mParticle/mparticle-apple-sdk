//
//  MPKitDataTransformation.h
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
#import "MPExtensionProtocol.h"

@class MPCommerceEvent;
@class MPEventAbstract;
@class MPKitConfiguration;
@class MPKitFilter;

@interface MPKitDataTransformation : NSObject

- (void)filter:(nonnull id<MPExtensionKitProtocol>)kitRegister kitConfiguration:(nonnull MPKitConfiguration *)kitConfiguration forEvent:(nullable MPEventAbstract *const)event selector:(nonnull SEL)selector completionHandler:(void (^ _Nonnull)(MPKitFilter * _Nonnull kitFilter, BOOL finished))completionHandler;

- (void)filter:(nonnull id<MPExtensionKitProtocol>)kitRegister kitConfiguration:(nonnull MPKitConfiguration *)kitConfiguration forUserAttributes:(nonnull NSDictionary *)userAttributes completionHandler:(void (^ _Nonnull)(MPKitFilter * _Nonnull kitFilter, BOOL finished))completionHandler;

- (void)filter:(nonnull id<MPExtensionKitProtocol>)kitRegister kitConfiguration:(nonnull MPKitConfiguration *)kitConfiguration forUserAttributeKey:(nonnull NSString *)key value:(nonnull id)value completionHandler:(void (^ _Nonnull)(MPKitFilter * _Nonnull kitFilter, BOOL finished))completionHandler;

- (void)filter:(nonnull id<MPExtensionKitProtocol>)kitRegister kitConfiguration:(nonnull MPKitConfiguration *)kitConfiguration forUserIdentityKey:(nonnull NSString *)key identityType:(MPUserIdentity)identityType completionHandler:(void (^ _Nonnull)(MPKitFilter * _Nonnull kitFilter, BOOL finished))completionHandler;

@end
