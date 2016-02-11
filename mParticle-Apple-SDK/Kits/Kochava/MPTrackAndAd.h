//
//  MPTrackAndAd.h
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
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TrackAndAd.h"

@interface MPKochavaTracker : NSObject <KochavaNetworkAccessDelegate, KochavaLocationManagerDelegate, KochavaiAdAttributionDelegate>

#pragma mark - Swift Bridge
- (KochavaTracker*) swiftInitKochavaWithParams:(id)initDict;
- (void) swiftEnableConsoleLogging:(bool)enableLogging;
- (void) swiftTrackEvent:(id)eventTitle :(id)eventValue;
- (void) swiftIdentityLinkEvent:(id)identityLinkData;
- (void) swiftSpatialEvent:(id)eventTitle :(float)x :(float)y :(float)z;
- (void) swiftSetLimitAdTracking:(bool)limitAdTracking;
- (NSString*) swiftRetrieveAttribution;
- (void) swiftSendDeepLink:(id)url :(id)sourceApplication;


#pragma mark - ObjC
- (id) initWithKochavaAppId:(NSString*)appId;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency :(bool)enableLogging;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency :(bool)enableLogging :(bool)limitAdTracking;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency :(bool)enableLogging :(bool)limitAdTracking :(bool)isNewUser;
- (id) initKochavaWithParams:(NSDictionary*)initDict;

- (void) enableConsoleLogging:(bool)enableLogging;

- (void) trackEvent:(NSString*)eventTitle :(NSString*)eventValue;
- (void) identityLinkEvent:(NSDictionary*)identityLinkData;
- (void) spatialEvent:(NSString*)eventTitle :(float)x :(float)y :(float)z;
- (void) setLimitAdTracking:(bool)limitAdTracking;
- (id) retrieveAttribution;
- (void) sendDeepLink:(NSURL*)url :(NSString*)sourceApplication;

- (NSString*) getKochavaDeviceId;

// Apple Watch
- (void) handleWatchEvents;
- (void) handleWatchEvents:(NSString*)watchLink;
- (void) handleWatchEvents:(NSString*)watchLink :(bool)calledByTrackEvent;

- (void) trackWatchEvent:(NSString*)eventTitle :(NSString*)eventValue;


@property (nonatomic, assign) id <KochavaTrackerClientDelegate> trackerDelegate;

@end