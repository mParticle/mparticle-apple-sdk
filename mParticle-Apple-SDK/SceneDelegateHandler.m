#import "SceneDelegateHandler.h"
#import "MPILogger.h"
#import "mParticle.h"

@interface SceneDelegateHandler ()
@property (nonatomic, strong) id<OpenURLHandlerProtocol> appNotificationHandler;
@end

@implementation SceneDelegateHandler

- (instancetype)initWithAppNotificationHandler:(id<OpenURLHandlerProtocol>)appNotificationHandler {
    self = [super init];
    if (self) {
        _appNotificationHandler = appNotificationHandler;
    }
    return self;
}

#if TARGET_OS_IOS
- (void)handleWithUrlContext:(UIOpenURLContext *)urlContext API_AVAILABLE(ios(13.0)) {
    
    MPILogDebug(@"Opening URLContext URL: %@", urlContext.URL);
    MPILogDebug(@"Source: %@", urlContext.options.sourceApplication ?: @"unknown");
    MPILogDebug(@"Annotation: %@", urlContext.options.annotation);

    if (@available(iOS 14.5, *)) {
        MPILogDebug(@"Event Attribution: %@", urlContext.options.eventAttribution);
    }

    MPILogDebug(@"Open in place: %@", urlContext.options.openInPlace ? @"True" : @"False");
    
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    if (urlContext.options.sourceApplication) {
        options[@"UIApplicationOpenURLOptionsSourceApplicationKey"] = urlContext.options.sourceApplication;
    }

    [self.appNotificationHandler open:urlContext.URL options:options];
}
#endif

- (void)handleUserActivity:(NSUserActivity *)userActivity {
    MPILogDebug(@"User Activity Received");
    MPILogDebug(@"User Activity Type: %@", userActivity.activityType);
    MPILogDebug(@"User Activity Title: %@", userActivity.title ?: @"");
    MPILogDebug(@"User Activity User Info: %@", userActivity.userInfo ?: @{});

    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        MPILogDebug(@"Opening UserActivity URL: %@", userActivity.webpageURL.absoluteString ?: @"");
    }

    (void)[self.appNotificationHandler continueUserActivity:userActivity
                                        restorationHandler:^(__unused NSArray<id<UIUserActivityRestoring>> * _Nullable restorableObjects) {
                                        }];
}

@end
