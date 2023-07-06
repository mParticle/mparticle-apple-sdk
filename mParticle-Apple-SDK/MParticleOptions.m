//
//  MParticleOptions.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import "MParticleOptions.h"
#import "MPEnums.h"
#import "MParticle.h"
#import "MPILogger.h"
#import "MPIConstants.h"

@interface MParticleOptions ()

@property (nonatomic, readwrite) BOOL isProxyAppDelegateSet;
@property (nonatomic, readwrite) BOOL isCollectUserAgentSet;
@property (nonatomic, readwrite) BOOL isCollectSearchAdsAttributionSet;
@property (nonatomic, readwrite) BOOL isTrackNotificationsSet;
@property (nonatomic, readwrite) BOOL isAutomaticSessionTrackingSet;
@property (nonatomic, readwrite) BOOL isStartKitsAsyncSet;
@property (nonatomic, readwrite) BOOL isUploadIntervalSet;
@property (nonatomic, readwrite) BOOL isSessionTimeoutSet;

@end

@implementation MParticleOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        _proxyAppDelegate = YES;
        _collectUserAgent = YES;
        _collectSearchAdsAttribution = NO;
        _trackNotifications = YES;
        _automaticSessionTracking = YES;
        _shouldBeginSession = YES;
        _startKitsAsync = NO;
        _logLevel = MPILogLevelNone;
        _uploadInterval = 0.0;
        _sessionTimeout = DEFAULT_SESSION_TIMEOUT;
    }
    return self;
}

+ (id)optionsWithKey:(NSString *)apiKey secret:(NSString *)secret {
    MParticleOptions *options = [[self alloc] init];
    options.apiKey = apiKey;
    options.apiSecret = secret;
    return options;
}

- (void)setProxyAppDelegate:(BOOL)proxyAppDelegate {
    _proxyAppDelegate = proxyAppDelegate;
    _isProxyAppDelegateSet = YES;
}

- (void)setCollectUserAgent:(BOOL)collectUserAgent {
    _collectUserAgent = collectUserAgent;
    _isCollectUserAgentSet = YES;
}

- (void)setCollectSearchAdsAttribution:(BOOL)collectSearchAdsAttribution {
    _collectSearchAdsAttribution = collectSearchAdsAttribution;
    _isCollectSearchAdsAttributionSet = YES;
}

- (void)setTrackNotifications:(BOOL)trackNotifications {
    _trackNotifications = trackNotifications;
    _isTrackNotificationsSet = YES;
}

- (void)setAutomaticSessionTracking:(BOOL)automaticSessionTracking {
    _automaticSessionTracking = automaticSessionTracking;
    _isAutomaticSessionTrackingSet = YES;
}

- (void)setStartKitsAsync:(BOOL)startKitsAsync {
    _startKitsAsync = startKitsAsync;
    _isStartKitsAsyncSet = YES;
}

- (void)setUploadInterval:(NSTimeInterval)uploadInterval {
    _uploadInterval = uploadInterval;
    _isUploadIntervalSet = YES;
}

- (void)setSessionTimeout:(NSTimeInterval)sessionTimeout {
    _sessionTimeout = sessionTimeout;
    _isSessionTimeoutSet = YES;
}

- (void)setConfigMaxAgeSeconds:(NSNumber *)configMaxAgeSeconds {
    if (configMaxAgeSeconds != nil && [configMaxAgeSeconds doubleValue] <= 0) {
        MPILogWarning(@"Config Max Age must be a positive number, disregarding value.");
    } else {
        _configMaxAgeSeconds = configMaxAgeSeconds;
    }
}

@end
