#import "MPKitFirebaseGA4.h"
#import <FirebaseAnalytics/FirebaseAnalytics.h>

@implementation MPKitFirebaseGA4

+ (NSNumber *)kitCode {
    return @243;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Firebase Analytics GA4"
                                                          className:@"MPKitFirebaseGA4"];
    [MParticle registerExtension:kitRegister];
}

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    _configuration = configuration;
    [self start];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (void)start {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _started = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey: [[self class] kitCode]};
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    NSString *eventName = event.name;
    if (eventName.length > 40) {
        eventName = [eventName substringToIndex:40];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (event.customAttributes) {
        [params addEntriesFromDictionary:event.customAttributes];
    }
    [FIRAnalytics logEventWithName:eventName parameters:params];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    [FIRAnalytics logEventWithName:kFIREventScreenView
                        parameters:@{kFIRParameterScreenName: event.name}];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    if (identityType == MPUserIdentityCustomerId) {
        [FIRAnalytics setUserID:identityString];
    }
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    [FIRAnalytics setUserPropertyString:value forName:key];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    [FIRAnalytics setUserPropertyString:nil forName:key];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

@end
