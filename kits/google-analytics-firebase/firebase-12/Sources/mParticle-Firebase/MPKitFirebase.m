#import "MPKitFirebase.h"
#import <FirebaseAnalytics/FirebaseAnalytics.h>

static NSString *const MPKitFirebaseKitCode = @"243";

@implementation MPKitFirebase

+ (NSNumber *)kitCode {
    return @243;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Firebase Analytics"
                                                          className:@"MPKitFirebase"];
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
    NSString *eventName = [self sanitizeEventName:event.name];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (event.customAttributes) {
        [params addEntriesFromDictionary:[self sanitizeAttributes:event.customAttributes]];
    }
    [FIRAnalytics logEventWithName:eventName parameters:params];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    NSString *screenName = [self sanitizeEventName:event.name];
    [FIRAnalytics logEventWithName:kFIREventScreenView
                        parameters:@{kFIRParameterScreenName: screenName}];
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
    NSString *sanitizedKey = [self sanitizeAttributeKey:key];
    [FIRAnalytics setUserPropertyString:value forName:sanitizedKey];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    NSString *sanitizedKey = [self sanitizeAttributeKey:key];
    [FIRAnalytics setUserPropertyString:nil forName:sanitizedKey];
    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

#pragma mark - Private helpers

- (NSString *)sanitizeEventName:(NSString *)eventName {
    if (eventName.length > 40) {
        eventName = [eventName substringToIndex:40];
    }
    return eventName;
}

- (NSString *)sanitizeAttributeKey:(NSString *)key {
    if (key.length > 24) {
        key = [key substringToIndex:24];
    }
    return key;
}

- (NSDictionary *)sanitizeAttributes:(NSDictionary *)attributes {
    NSMutableDictionary *sanitized = [NSMutableDictionary dictionaryWithCapacity:attributes.count];
    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        NSString *sanitizedKey = [self sanitizeAttributeKey:key];
        sanitized[sanitizedKey] = value;
    }];
    return sanitized;
}

@end
