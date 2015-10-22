//
//  MPUploadBuilder.h
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

#import <Foundation/Foundation.h>

@class MPDataModelAbstract;
@class MPUpload;
@class MPSession;

@interface MPUploadBuilder : NSObject

@property (nonatomic, strong, readonly) MPSession *session;
@property (nonatomic, strong, readonly) NSMutableArray *preparedMessageIds;

+ (MPUploadBuilder *)newBuilderWithMessages:(NSArray *)messages uploadInterval:(NSTimeInterval)uploadInterval;
+ (MPUploadBuilder *)newBuilderWithSession:(MPSession *)session messages:(NSArray *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval;
- (instancetype)initWithSession:(MPSession *)session messages:(NSArray *)messages sessionTimeout:(NSTimeInterval)sessionTimeout uploadInterval:(NSTimeInterval)uploadInterval;
- (void)build:(void (^)(MPDataModelAbstract *upload))completionHandler;
- (MPUploadBuilder *)withUserAttributes:(NSDictionary *)userAttributes deletedUserAttributes:(NSSet *)deletedUserAttributes;
- (MPUploadBuilder *)withUserIdentities:(NSArray *)userIdentities;

@end
