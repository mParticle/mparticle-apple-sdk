@import Foundation;
#import "mParticle.h"
#import "MParticleOptions+MParticlePrivate.h"
#import "MPIConstants.h"
#import "MPILogger.h"

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

- (void)setPersistenceMaxAgeSeconds:(NSNumber *)persistenceMaxAgeSeconds {
    if (persistenceMaxAgeSeconds != nil && [persistenceMaxAgeSeconds doubleValue] <= 0) {
        MPILogWarning(@"Persistence Max Age must be a positive number, disregarding value.");
    } else {
        _persistenceMaxAgeSeconds = persistenceMaxAgeSeconds;
    }
}

@end
