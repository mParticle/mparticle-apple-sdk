//
//  MPTrackAndAd.h
//  TrackAndAd
//
//  Copyright (c) 2013-2014 Kochava. All rights reserved.
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