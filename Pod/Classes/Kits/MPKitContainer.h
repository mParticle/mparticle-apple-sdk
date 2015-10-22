//
//  MPKitContainer.h
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
#import "MPEnums.h"

@class MPKitAbstract;
@class MPKitFilter;
@class MPKitExecStatus;
@class MPCommerceEvent;
@class MPEvent;

@interface MPKitContainer : NSObject

@property (nonatomic, strong) NSMutableArray *kits;

+ (MPKitContainer *)sharedInstance;
- (NSArray *)activeKits;
- (void)configureKits:(NSArray *)kitsConfiguration;
- (NSArray *)supportedKits;

- (void)forwardCommerceEventCall:(MPCommerceEvent *)commerceEvent kitHandler:(void (^)(MPKitAbstract *kit, MPKitFilter *kitFilter, MPKitExecStatus **execStatus))kitHandler;
- (void)forwardSDKCall:(SEL)selector event:(MPEvent *)event messageType:(MPMessageType)messageType userInfo:(NSDictionary *)userInfo kitHandler:(void (^)(MPKitAbstract *kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus))kitHandler;
- (void)forwardSDKCall:(SEL)selector userAttributeKey:(NSString *)key value:(id)value kitHandler:(void (^)(MPKitAbstract *kit))kitHandler;
- (void)forwardSDKCall:(SEL)selector userAttributes:(NSDictionary *)userAttributes kitHandler:(void (^)(MPKitAbstract *kit, NSDictionary *forwardAttributes))kitHandler;
- (void)forwardSDKCall:(SEL)selector userIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType kitHandler:(void (^)(MPKitAbstract *kit))kitHandler;
- (void)forwardSDKCall:(SEL)selector errorMessage:(NSString *)errorMessage exception:(NSException *)exception eventInfo:(NSDictionary *)eventInfo kitHandler:(void (^)(MPKitAbstract *kit, MPKitExecStatus **execStatus))kitHandler;

@end
