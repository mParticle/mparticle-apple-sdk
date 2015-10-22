//
//  MPStateMachine.h
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
#import "MPLaunchInfo.h"
#import "MParticleReachability.h"

@class MPSession;
@class MPNotificationController;
@class MPConsumerInfo;
@class MPBags;
@class MPLocationManager;

typedef NS_ENUM(NSUInteger, MPConsoleLogging) {
    MPConsoleLoggingAutoDetect = 0,
    MPConsoleLoggingDisplay,
    MPConsoleLoggingSuppress
};

@interface MPStateMachine : NSObject

@property (nonatomic, strong) NSString *apiKey __attribute__((const));
@property (nonatomic, strong) MPBags *bags;
@property (nonatomic, strong) MPConsumerInfo *consumerInfo;
@property (nonatomic, weak) MPSession *currentSession;
@property (nonatomic, strong) NSArray *customModules;
@property (nonatomic, strong) NSString *exceptionHandlingMode;
@property (nonatomic, strong) NSString *locationTrackingMode;
@property (nonatomic, strong) NSString *latestSDKVersion;
@property (nonatomic, strong) NSDictionary *launchOptions;
@property (nonatomic, strong) MPLocationManager *locationManager;
@property (nonatomic, strong) NSDate *minUploadDate;
@property (nonatomic, strong) NSString *networkPerformanceMeasuringMode;
@property (nonatomic, strong) NSString *pushNotificationMode;
@property (nonatomic, strong) NSString *secret __attribute__((const));
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) MPLaunchInfo *launchInfo;
@property (nonatomic, strong, readonly) NSString *deviceTokenType;
@property (nonatomic, strong, readonly) NSNumber *firstSeenInstallation;
@property (nonatomic, strong, readonly) NSDate *launchDate;
@property (nonatomic, strong, readonly) NSArray *triggerEventTypes;
@property (nonatomic, strong, readonly) NSArray *triggerMessageTypes;
@property (nonatomic, unsafe_unretained) MPConsoleLogging consoleLogging;
@property (nonatomic, unsafe_unretained) MPLogLevel logLevel;
@property (nonatomic, unsafe_unretained) MPInstallationType installationType;
@property (nonatomic, unsafe_unretained, readonly) NetworkStatus networkStatus;
@property (nonatomic, unsafe_unretained) MPUploadStatus uploadStatus;
@property (nonatomic, unsafe_unretained, readonly) BOOL backgrounded;
@property (nonatomic, unsafe_unretained, readonly) BOOL dataRamped;
@property (nonatomic, unsafe_unretained) BOOL optOut;

+ (instancetype)sharedInstance;
+ (MPEnvironment)environment;
+ (void)setEnvironment:(MPEnvironment)environment;
+ (NSString *)provisioningProfileString;
+ (BOOL)runningInBackground;
+ (void)setRunningInBackground:(BOOL)background;
- (void)configureCustomModules:(NSArray *)customModuleSettings;
- (void)configureRampPercentage:(NSNumber *)rampPercentage;
- (void)configureTriggers:(NSDictionary *)triggerDictionary;

@end
