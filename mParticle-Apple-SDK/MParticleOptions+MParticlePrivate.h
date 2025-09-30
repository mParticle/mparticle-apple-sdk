@interface MParticleOptions ()

@property(nonatomic, readwrite) BOOL isProxyAppDelegateSet;
@property(nonatomic, readwrite) BOOL isCollectUserAgentSet;
@property(nonatomic, readwrite) BOOL isCollectSearchAdsAttributionSet;
@property(nonatomic, readwrite) BOOL isTrackNotificationsSet;
@property(nonatomic, readwrite) BOOL isAutomaticSessionTrackingSet;
@property(nonatomic, readwrite) BOOL isStartKitsAsyncSet;
@property(nonatomic, readwrite) BOOL isUploadIntervalSet;
@property(nonatomic, readwrite) BOOL isSessionTimeoutSet;

+ (id)optionsWithKey:(NSString *)apiKey secret:(NSString *)secret;

- (void)setProxyAppDelegate:(BOOL)proxyAppDelegate;
- (void)setCollectUserAgent:(BOOL)collectUserAgent;
- (void)setCollectSearchAdsAttribution:(BOOL)collectSearchAdsAttribution;
- (void)setTrackNotifications:(BOOL)trackNotifications;
- (void)setAutomaticSessionTracking:(BOOL)automaticSessionTracking;
- (void)setStartKitsAsync:(BOOL)startKitsAsync;
- (void)setUploadInterval:(NSTimeInterval)uploadInterval;
- (void)setSessionTimeout:(NSTimeInterval)sessionTimeout;
- (void)setConfigMaxAgeSeconds:(NSNumber *)configMaxAgeSeconds;
- (void)setPersistenceMaxAgeSeconds:(NSNumber *)persistenceMaxAgeSeconds;

@end
