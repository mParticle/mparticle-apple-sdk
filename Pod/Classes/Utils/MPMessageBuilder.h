//
//  MPMessageBuilder.h
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

#import <CoreLocation/CoreLocation.h>
#import "MPConstants.h"
#import "MPMediaTrack+Internal.h"

@class MPSession;
@class MPDataModelAbstract;
@class MPMediaTrack;
@class MPCommerceEvent;

@interface MPMessageBuilder : NSObject

@property (nonatomic, strong, readonly) NSString *messageType;
@property (nonatomic, strong, readonly) MPSession *session;
@property (nonatomic, strong, readonly) NSDictionary *messageInfo;
@property (nonatomic, unsafe_unretained, readonly) NSTimeInterval timestamp;

+ (MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(MPSession *)session commerceEvent:(MPCommerceEvent *)commerceEvent;
+ (MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(MPSession *)session messageInfo:(NSDictionary *)messageInfo;
+ (MPMessageBuilder *)newBuilderWithMessageType:(MPMessageType)messageType session:(MPSession *)session mediaTrack:(MPMediaTrack *)mediaTrack mediaAction:(MPMediaAction)mediaAction;
- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session;
- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session commerceEvent:(MPCommerceEvent *)commerceEvent;
- (instancetype)initWithMessageType:(MPMessageType)messageType session:(MPSession *)session messageInfo:(NSDictionary *)messageInfo;
- (MPMessageBuilder *)withLaunchInfo:(NSDictionary *)launchInfo;
- (MPMessageBuilder *)withLocation:(CLLocation *)location;
- (MPMessageBuilder *)withTimestamp:(NSTimeInterval)timestamp;
- (MPMessageBuilder *)withStateTransition:(BOOL)sessionFinalized previousSession:(MPSession *)previousSession;
- (MPDataModelAbstract *)build;

@end
