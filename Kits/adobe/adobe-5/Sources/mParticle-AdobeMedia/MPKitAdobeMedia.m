#import "MPKitAdobeMedia.h"
#import "MPIAdobe.h"
#if defined(__has_include) && __has_include(<AEPCore/AEPCore.h>)
#import <AEPCore/AEPCore.h>
#elif defined(__has_include) && __has_include("AEPCore.h")
#import "AEPCore.h"
#else
@import AEPCore;
#endif
#if defined(__has_include) && __has_include(<AEPAnalytics/AEPAnalytics.h>)
#import <AEPAnalytics/AEPAnalytics.h>
#elif defined(__has_include) && __has_include("AEPAnalytics.h")
#import "AEPAnalytics.h"
#else
@import AEPAnalytics;
#endif
#if defined(__has_include) && __has_include(<AEPMedia/AEPMedia.h>)
#import <AEPMedia/AEPMedia.h>
#elif defined(__has_include) && __has_include("AEPMedia.h")
#import "AEPMedia.h"
#else
@import AEPMedia;
#endif
#if defined(__has_include) && __has_include(<AEPUserProfile/AEPUserProfile.h>)
#import <AEPUserProfile/AEPUserProfile.h>
#elif defined(__has_include) && __has_include("AEPUserProfile.h")
#import "AEPUserProfile.h"
#else
@import AEPUserProfile;
#endif
#if defined(__has_include) && __has_include(<AEPIdentity/AEPIdentity.h>)
#import <AEPIdentity/AEPIdentity.h>
#elif defined(__has_include) && __has_include("AEPIdentity.h")
#import "AEPIdentity.h"
#else
@import AEPIdentity;
#endif
#if defined(__has_include) && __has_include(<AEPLifecycle/AEPLifecycle.h>)
#import <AEPLifecycle/AEPLifecycle.h>
#elif defined(__has_include) && __has_include("AEPLifecycle.h")
#import "AEPLifecycle.h"
#else
@import AEPLifecycle;
#endif
#if defined(__has_include) && __has_include(<AEPSignal/AEPSignal.h>)
#import <AEPSignal/AEPSignal.h>
#elif defined(__has_include) && __has_include("AEPSignal.h")
#import "AEPSignal.h"
#else
@import AEPSignal;
#endif
#if defined(__has_include) && __has_include(<AEPServices/AEPServices.h>)
#import <AEPServices/AEPServices.h>
#elif defined(__has_include) && __has_include("AEPServices.h")
#import "AEPServices.h"
#else
@import AEPServices;
#endif

@import mParticle_Apple_Media_SDK;

static NSString *const marketingCloudIdIntegrationAttributeKey = @"mid";
static NSString *const blobIntegrationAttributeKey = @"aamb";
static NSString *const locationHintIntegrationAttributeKey = @"aamlh";
static NSString *const organizationIdConfigurationKey = @"organizationID";
static NSString *const launchAppIdKey = @"launchAppId";
static NSString *const audienceManagerServerConfigurationKey = @"audienceManagerServer";

#pragma mark - MPIAdobeApi
@implementation MPIAdobeApi

@synthesize marketingCloudID;

@end

@interface MPKitAdobeMedia ()

@property (nonatomic) NSString *organizationId;
@property id<AEPMediaTracker> defaultMediaTracker;
@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString *, id<AEPMediaTracker>> *mediaTrackers;
@property (nonatomic) NSString *pushToken;
@property (nonatomic) NSString *audienceManagerServer;
@property (atomic) BOOL syncingId;

@end

@implementation MPKitAdobeMedia

+ (NSNumber *)kitCode {
    return @124;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AdobeMedia" className:NSStringFromClass(self)];
    [MParticle registerExtension:kitRegister];
}

- (MPKitExecStatus *)execStatus:(MPKitReturnCode)returnCode {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.class.kitCode returnCode:returnCode];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    _organizationId = [configuration[organizationIdConfigurationKey] copy];
    if (!_organizationId) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }
    
    if (!_organizationId.length) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }

    _audienceManagerServer = [configuration[audienceManagerServerConfigurationKey] copy];

    _configuration = configuration;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    [self start];

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (void)start {
    static dispatch_once_t kitPredicate;

    NSString *launchAppId  = _configuration[launchAppIdKey];
    
    dispatch_once(&kitPredicate, ^{
        [AEPMobileCore setLogLevel:AEPLogLevelDebug];
        if (launchAppId != nil) {
            [AEPMobileCore registerExtensions:@[AEPMobileAnalytics.class, AEPMobileMedia.class, AEPMobileUserProfile.class, AEPMobileSignal.class, AEPMobileLifecycle.class, AEPMobileIdentity.class] completion:^{
                [AEPMobileCore configureWithAppId:launchAppId];
                NSMutableDictionary* config = [NSMutableDictionary dictionary];
                self.defaultMediaTracker = [AEPMobileMedia createTrackerWithConfig:config];
                self.mediaTrackers = [[NSMutableDictionary<NSString *, id<AEPMediaTracker>> alloc] init];
                NSLog(@"mParticle -> Adobe Media configured");
            }];
        } else {
            NSLog(@"mParticle -> Adobe Media not configured");
        }

        self->_started = YES;
        
        [self syncId];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

- (id const)providerKitInstance {
    if (![self started]) {
        return nil;
    }

    MPIAdobeApi *adobeApi = [[MPIAdobeApi alloc] init];
    adobeApi.marketingCloudID = [self marketingCloudIdFromIntegrationAttributes];
    return adobeApi;
}

#pragma mark Base events
 - (MPKitExecStatus *)logBaseEvent:(MPBaseEvent *)event {
     MPKitExecStatus *status = nil;
     if ([event isKindOfClass:[MPMediaEvent class]]) {
         MPMediaEvent *mediaEvent = (MPMediaEvent *)event;
         status = [self routeMediaEvent:mediaEvent];
     } else if ([event isKindOfClass:[MPEvent class]]) {
         status = [self execStatus:MPKitReturnCodeSuccess];
     } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
         status = [self execStatus:MPKitReturnCodeSuccess];
     }

     if (!status) {
         status = [self execStatus:MPKitReturnCodeFail];
     }
     return status;
 }

- (MPKitExecStatus *)routeMediaEvent:(MPMediaEvent *)mediaEvent {
    if (_mediaTrackers[mediaEvent.mediaSessionId] == nil && mediaEvent.mediaEventName != MPMediaEventNameSessionStart) {
        NSLog(@"mParticle -> Adobe media kit event was called before Session Start or after Session End");
        return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitAdobeMedia kitCode] returnCode:MPKitReturnCodeSuccess];
    }
    
    switch (mediaEvent.mediaEventName) {
        case MPMediaEventNameSessionStart: {
            NSString *streamType = [self streamTypeForMediaEvent:mediaEvent];
            AEPMediaType contentType = [self contentTypeForMediaEvent:mediaEvent];
            
            NSDictionary *mediaObject = [AEPMobileMedia createMediaObjectWith:mediaEvent.mediaContentTitle id:mediaEvent.mediaContentId length:mediaEvent.duration.doubleValue streamType:streamType mediaType:contentType];

            NSMutableDictionary *mediaMetadata = [[NSMutableDictionary alloc] init];
            
            _mediaTrackers[mediaEvent.mediaSessionId] = [AEPMobileMedia createTrackerWithConfig:[NSMutableDictionary dictionary]];

            [_mediaTrackers[mediaEvent.mediaSessionId] trackSessionStart:mediaObject metadata:mediaMetadata];
            break;
        }
        case MPMediaEventNamePlay:
            [_mediaTrackers[mediaEvent.mediaSessionId] trackPlay];
            break;
        case MPMediaEventNamePause:
            [_mediaTrackers[mediaEvent.mediaSessionId] trackPause];
            break;
        case MPMediaEventNameSessionEnd:
            [_mediaTrackers[mediaEvent.mediaSessionId] trackSessionEnd];
            [_mediaTrackers removeObjectForKey:mediaEvent.mediaSessionId];
            break;
        case MPMediaEventNameSeekStart: {
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventSeekStart info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameSeekEnd: {
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventSeekComplete info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameBufferStart: {
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventBufferStart info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameBufferEnd: {
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventBufferComplete info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameUpdatePlayheadPosition:
            [_mediaTrackers[mediaEvent.mediaSessionId] updateCurrentPlayhead:mediaEvent.playheadPosition.doubleValue];
            break;
        case MPMediaEventNameAdClick:
            break;
        case MPMediaEventNameAdBreakStart: {
            NSDictionary* adBreakObject = [AEPMobileMedia createAdBreakObjectWith:mediaEvent.adBreak.title position:1 startTime:0];
            
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventAdBreakStart info:adBreakObject metadata:nil];
            break;
        }
        case MPMediaEventNameAdBreakEnd: {
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventAdBreakComplete info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameAdStart: {
            NSDictionary* adObject = [AEPMobileMedia createAdObjectWith:mediaEvent.adContent.title id:mediaEvent.adContent.id position:mediaEvent.adContent.position.doubleValue length:mediaEvent.adContent.duration.doubleValue];
            NSMutableDictionary* adMetadata = [[NSMutableDictionary alloc] init];
            
            if (mediaEvent.adContent.advertiser != nil) {
                [adMetadata setObject:mediaEvent.adContent.advertiser forKey:AEPAdMetadataKeys.ADVERTISER];
            }
            if (mediaEvent.adContent.campaign != nil) {
                [adMetadata setObject:mediaEvent.adContent.campaign forKey:AEPAdMetadataKeys.CAMPAIGN_ID];
            }
            if (mediaEvent.adContent.creative != nil) {
                [adMetadata setObject:mediaEvent.adContent.creative forKey:AEPAdMetadataKeys.CREATIVE_ID];
            }
            if (mediaEvent.adContent.placement != nil) {
                [adMetadata setObject:mediaEvent.adContent.placement forKey:AEPAdMetadataKeys.PLACEMENT_ID];
            }
            if (mediaEvent.adContent.siteId != nil) {
                [adMetadata setObject:mediaEvent.adContent.siteId forKey:AEPAdMetadataKeys.CREATIVE_URL];
            }
            
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventAdStart info:adObject metadata:adMetadata];
            break;
        }
        case MPMediaEventNameAdEnd: {
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventAdComplete info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameAdSkip: {
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventAdSkip info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameSegmentStart: {
            NSDictionary* chapterObject = [AEPMobileMedia createChapterObjectWith:mediaEvent.segment.title position:mediaEvent.segment.index length:mediaEvent.segment.duration.doubleValue startTime:mediaEvent.playheadPosition.doubleValue];
            
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventChapterStart info:chapterObject metadata:nil];
            break;
        }
        case MPMediaEventNameSegmentSkip: {
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventChapterSkip info:nil metadata:nil];
           break;
       }
        case MPMediaEventNameSegmentEnd:  {
            [_mediaTrackers[mediaEvent.mediaSessionId] trackEvent:AEPMediaEventChapterComplete info:nil metadata:nil];
           break;
       }
        case MPMediaEventNameUpdateQoS: {
            NSDictionary* mediaQoS = [AEPMobileMedia createQoEObjectWith:mediaEvent.qos.bitRate.doubleValue startTime:mediaEvent.qos.startupTime.doubleValue fps:mediaEvent.qos.fps.doubleValue droppedFrames:mediaEvent.qos.droppedFrames.doubleValue];
            
            [_mediaTrackers[mediaEvent.mediaSessionId] updateQoEObject:mediaQoS];
           break;
       }
        default:
            break;
    }

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitAdobeMedia kitCode] returnCode:MPKitReturnCodeSuccess];
}

#pragma mark Private Methods
- (NSString *)streamTypeForMediaEvent:(MPMediaEvent *)mediaEvent  {
    if (mediaEvent.streamType == MPMediaStreamTypeOnDemand) {
        if (mediaEvent.contentType == MPMediaContentTypeVideo) {
            return AEPMediaStreamType.VOD;
        } else {
            return AEPMediaStreamType.AOD;
        }
    } else if (mediaEvent.streamType == MPMediaStreamTypeLinear) {
        return AEPMediaStreamType.LINEAR;
    } else if (mediaEvent.streamType == MPMediaStreamTypePodcast) {
        return AEPMediaStreamType.PODCAST;
    } else if (mediaEvent.streamType == MPMediaStreamTypeAudiobook) {
        return AEPMediaStreamType.AUDIOBOOK;
    } else {
        return AEPMediaStreamType.LIVE;
    }
}

- (AEPMediaType)contentTypeForMediaEvent:(MPMediaEvent *)mediaEvent  {
    if (mediaEvent.contentType == MPMediaContentTypeVideo) {
        return AEPMediaTypeVideo;
    } else {
        return AEPMediaTypeAudio;
    }
}

- (void)didEnterBackground:(NSNotification *)notification {
    [self syncId];
}

- (void)willTerminate:(NSNotification *)notification {
    [self syncId];
}

- (FilteredMParticleUser *)currentUser {
    return [[self kitApi] getCurrentUserWithKit:self];
}

- (NSString *)marketingCloudIdFromIntegrationAttributes {
    NSDictionary *dictionary = _kitApi.integrationAttributes;
    return dictionary[marketingCloudIdIntegrationAttributeKey];
}

- (NSString *)advertiserId {
    NSString *advertiserId = nil;
    Class MPIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    
    if (MPIdentifierManager) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"sharedManager");
        id<NSObject> adIdentityManager = [MPIdentifierManager performSelector:selector];
        
        selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL advertisingTrackingEnabled = (BOOL)[adIdentityManager performSelector:selector];
        if (advertisingTrackingEnabled) {
            selector = NSSelectorFromString(@"advertisingIdentifier");
            advertiserId = [[adIdentityManager performSelector:selector] UUIDString];
        }
#pragma clang diagnostic pop
#pragma clang diagnostic pop
    }
    
    return advertiserId;
}

- (NSString *)pushToken {
    return _pushToken;
}

- (void)syncId {
    if (self.syncingId) return;
    
    self.syncingId = YES;
    [AEPMobileIdentity getExperienceCloudId:^(NSString * _Nullable mid, NSError * _Nullable error) {
        if (error) {
            NSLog(@"mParticle -> Adobe Media - Error getting Adobe cloud experience Id (marketing cloud Id): %@", error);
        } else {
            NSString *existingMid = [self marketingCloudIdFromIntegrationAttributes];
            if (mid.length > 0 && ![mid isEqualToString:existingMid]) {
                [[MParticle sharedInstance] setIntegrationAttributes:@{marketingCloudIdIntegrationAttributeKey: mid} forKit:[[self class] kitCode]];
            }
        }
        self.syncingId = NO;
    }];
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    _pushToken = [[NSString alloc] initWithData:deviceToken encoding:NSUTF8StringEncoding];
    [self syncId];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    [self syncId];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)didBecomeActive {
    [self syncId];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAdobe) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (BOOL)shouldDelayMParticleUpload {
    NSString *marketingCloudId = [self marketingCloudIdFromIntegrationAttributes];
    return marketingCloudId.length == 0 || self.syncingId;
}

- (MPKitAPI *)kitApi {
    if (_kitApi == nil) {
        _kitApi = [[MPKitAPI alloc] init];
    }
    return _kitApi;
}

@end
