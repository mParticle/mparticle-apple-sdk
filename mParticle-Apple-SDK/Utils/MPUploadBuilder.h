//
//  MPUploadBuilder.h
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

@class MPMessage;
@class MPUpload;
@class MPSession;

@interface MPUploadBuilder : NSObject

@property (nonatomic, strong, readonly, nullable) MPSession *session;
@property (nonatomic, strong, readonly, nonnull) NSMutableArray<NSNumber *> *preparedMessageIds;

+ (nonnull MPUploadBuilder *)newBuilderWithMpid: (nonnull NSNumber *) mpid messages:(nonnull NSArray<MPMessage *> *)messages uploadInterval:(NSTimeInterval)uploadInterval;
+ (nonnull MPUploadBuilder *)newBuilderWithMpid: (nonnull NSNumber *) mpid session:(nullable MPSession *)session messages:(nonnull NSArray<MPMessage *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval;
- (nonnull instancetype)initWithMpid: (nonnull NSNumber *) mpid session:(nullable MPSession *)session messages:(nonnull NSArray<MPMessage *> *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval;
- (void)build:(void (^ _Nonnull)(MPUpload * _Nullable upload))completionHandler;
- (void)buildAsync:(BOOL)asyncBuild completionHandler:(void (^ _Nonnull)(MPUpload * _Nullable upload))completionHandler;
- (nonnull MPUploadBuilder *)withUserAttributes:(nonnull NSDictionary<NSString *, id> *)userAttributes deletedUserAttributes:(nullable NSSet<NSString *> *)deletedUserAttributes;
- (nonnull MPUploadBuilder *)withUserIdentities:(nonnull NSArray<NSDictionary<NSString *, id> *> *)userIdentities;

@end
