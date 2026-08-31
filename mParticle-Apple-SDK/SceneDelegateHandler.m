#import "SceneDelegateHandler.h"
#import "MPILogger.h"
#import "mParticle.h"
@import mParticle_Apple_SDK_Swift;

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

// Non-extractable: MPILogDebug is an ObjC macro that captures the call site and reads
// MParticle's log level, so Swift composes the messages and this emits them unchanged.
- (void)logLines:(NSArray<NSString *> *)lines {
    for (NSString *line in lines) {
        MPILogDebug(@"%@", line);
    }
}

#if TARGET_OS_IOS
- (void)handleURLContext:(UIOpenURLContext *)urlContext API_AVAILABLE(ios(13.0)) {
    NSString *eventAttribution = nil;
    if (@available(iOS 14.5, *)) {
        eventAttribution = [NSString stringWithFormat:@"%@", urlContext.options.eventAttribution];
    }

    [self logLines:[MPSceneDelegateLogic urlContextLogLinesWithURL:[NSString stringWithFormat:@"%@", urlContext.URL]
                                                 sourceApplication:urlContext.options.sourceApplication
                                                        annotation:[NSString stringWithFormat:@"%@", urlContext.options.annotation]
                                                  eventAttribution:eventAttribution
                                                       openInPlace:urlContext.options.openInPlace]];

    NSDictionary<NSString *, id> *options = [MPSceneDelegateLogic openURLOptionsWithSourceApplication:urlContext.options.sourceApplication];

    [self.appNotificationHandler openURL:urlContext.URL options:options];
}
#endif

- (void)handleUserActivity:(NSUserActivity *)userActivity {
    NSString *userInfoDescription = userActivity.userInfo
        ? [NSString stringWithFormat:@"%@", userActivity.userInfo]
        : [NSString stringWithFormat:@"%@", @{}];

    [self logLines:[MPSceneDelegateLogic userActivityLogLinesWithActivityType:userActivity.activityType
                                                                        title:userActivity.title
                                                          userInfoDescription:userInfoDescription
                                                                   webpageURL:userActivity.webpageURL.absoluteString]];

    (void)[self.appNotificationHandler continueUserActivity:userActivity
                                        restorationHandler:^(__unused NSArray<id<UIUserActivityRestoring>> * _Nullable restorableObjects) {
                                        }];
}

@end
