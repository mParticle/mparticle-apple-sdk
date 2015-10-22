//
//  MPApplication.h
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

#import "MPConstants.h"
#import "MPEnums.h"

extern NSString *const kMPApplicationInformationKey;

@interface MPApplication : NSObject <NSCopying>

@property (nonatomic, strong) NSNumber *lastUseDate;
@property (nonatomic, strong) NSNumber *launchCount;
@property (nonatomic, strong) NSNumber *launchCountSinceUpgrade;
@property (nonatomic, strong) NSString *storedBuild;
@property (nonatomic, strong) NSString *storedVersion;
@property (nonatomic, strong) NSNumber *upgradeDate;
@property (nonatomic, strong, readonly) NSString *architecture;
@property (nonatomic, strong, readonly) NSString *build __attribute__((const));
@property (nonatomic, strong, readonly) NSString *buildUUID;
@property (nonatomic, strong, readonly) NSString *bundleIdentifier __attribute__((const));
@property (nonatomic, strong, readonly) NSNumber *firstSeenInstallation __attribute__((const));
@property (nonatomic, strong, readonly) NSNumber *initialLaunchTime;
@property (nonatomic, strong, readonly) NSString *name __attribute__((const));
@property (nonatomic, strong, readonly) NSNumber *pirated;
@property (nonatomic, strong, readonly) NSNumber *remoteNotificationTypes;
@property (nonatomic, strong, readonly) NSString *version __attribute__((const));
@property (nonatomic, unsafe_unretained, readonly) MPEnvironment environment __attribute__((const));

+ (NSString *)appStoreReceipt;
+ (void)markInitialLaunchTime;
+ (void)updateLastUseDate:(NSDate *)date;
+ (void)updateLaunchCountsAndDates;
+ (void)updateStoredVersionAndBuildNumbers;
- (NSDictionary *)dictionaryRepresentation;

@end
