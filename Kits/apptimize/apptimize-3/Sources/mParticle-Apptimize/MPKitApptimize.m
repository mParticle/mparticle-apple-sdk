#import "MPKitApptimize.h"
#if defined(__has_include) && __has_include(<Apptimize/Apptimize.h>)
#import <Apptimize/Apptimize.h>
#else
#import "Apptimize.h"
#endif

@interface MPKitApptimize()
@property (nonatomic, unsafe_unretained) BOOL started;
@end

@implementation MPKitApptimize

static NSString *const APP_MP_KEY = @"appKey";
static NSString *const DEVICE_PAIRING_MP_KEY = @"devicePairing";
static NSString *const DELAY_UNTIL_TESTS_ARE_AVAILABLE_MP_KEY = @"delayUntilTestsAreAvailable";
static NSString *const LOG_LEVEL_MP_KEY = @"logLevel";
static NSString *const INSTALL_TAG = @"install";
static NSString *const LOGOUT_TAG = @"logout";
static NSString *const UPDATE_TAG = @"update";
static NSString *const LTV_TAG = @"ltv";
static NSString *const VIEWED_TAG_FORMAT = @"screenView %@";
static NSString *const TRACK_EXPERIMENTS = @"trackExperiments";

+ (NSNumber *)kitCode {
    return @105;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Apptimize" className:@"MPKitApptimize"];
    [MParticle registerExtension:kitRegister];
}

- (MPKitExecStatus*) makeStatus:(MPKitReturnCode)code {
    return [[MPKitExecStatus alloc]
            initWithSDKCode:@(MPKitInstanceApptimize)
            returnCode:code];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;

    NSString *appKey = configuration[APP_MP_KEY];
    if (!appKey) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }

    _configuration = configuration;

    [self start];

    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)start {
    NSDictionary *options = [self buildApptimizeOptions];
    void(^start_block)(void) = ^{
        [Apptimize startApptimizeWithApplicationKey:self.configuration[APP_MP_KEY] options:options];
        self.started = YES;
        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    };
    static dispatch_once_t kitPredicate;
    dispatch_once(&kitPredicate, ^{
        if ([NSThread isMainThread]) {
            start_block();
        } else {
            dispatch_async(dispatch_get_main_queue(), start_block);
        }
    });
}

- (nonnull NSDictionary*)buildApptimizeOptions {
    NSMutableDictionary *o = [NSMutableDictionary new];
    [o setObject:[NSNumber numberWithBool:FALSE] forKey:ApptimizeEnableThirdPartyEventImportingOption];
    [o setObject:[NSNumber numberWithBool:FALSE] forKey:ApptimizeEnableThirdPartyEventExportingOption];
    [self configureApptimizeDevicePairing:o];
    [self configureApptimizeDelayUntilTestsAreAvailable:o];
    [self configureApptimizeLogLevel:o];
    [self configureExperimentTracking];
    return o;
}

- (void)configureApptimizeDevicePairing:(NSMutableDictionary*)o {
    NSString *pairing = [self configValueForKey:DEVICE_PAIRING_MP_KEY];
    if (pairing) {
        NSNumber *boxedPairing = [NSNumber numberWithBool:[pairing boolValue]];
        [o setObject:boxedPairing forKey:ApptimizeDevicePairingOption];
    }
}

- (void)configureApptimizeDelayUntilTestsAreAvailable:(NSMutableDictionary*)o {
    NSString *delay = [self configValueForKey:DELAY_UNTIL_TESTS_ARE_AVAILABLE_MP_KEY];
    if (delay) {
        NSNumber *boxedDelay = [NSNumber numberWithDouble:[delay doubleValue]];
        [o setObject:boxedDelay forKey:ApptimizeDelayUntilTestsAreAvailableOption];
    }
}

- (void)configureApptimizeLogLevel:(NSMutableDictionary*)o {
    NSString *logLevel = [self configValueForKey:LOG_LEVEL_MP_KEY];
    if (logLevel) {
        [o setObject:logLevel forKey:ApptimizeLogLevelOption];
    }
}

- (nullable NSString*) configValueForKey:(NSString*)key {
    NSString *value = [self.launchOptions objectForKey:key];
    if (value == nil) {
        value = [self.configuration objectForKey:key];
    }
    return value;
}

- (void) configureExperimentTracking {
    BOOL enable = [self configValueForKey:TRACK_EXPERIMENTS] != nil;
    if (enable) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(experimentDidGetViewed:)
                                                     name:ApptimizeTestRunNotification
                                                   object:nil];
    }
}

- (void) experimentDidGetViewed:(NSNotification*)notification {
    if (![notification.userInfo[ApptimizeTestFirstRunUserInfoKey] boolValue]) {
        return;
    }

    NSMutableArray *profileAttributeStrings = [NSMutableArray new];

    for (id<ApptimizeTestInfo> test in [[Apptimize testInfo] allValues]) {
        if (test.userHasParticipated) {
            [profileAttributeStrings addObject:[NSString stringWithFormat:@"%@-%@", test.testName, test.enrolledVariantName]];
        }
    }

    [[MParticle sharedInstance].identity.currentUser setUserAttributeList:@"Apptimize experiment" values:profileAttributeStrings];

    NSString *name = notification.userInfo[ApptimizeTestNameUserInfoKey];
    NSString *variant = notification.userInfo[ApptimizeVariantNameUserInfoKey];
    [[Apptimize testInfo] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id<ApptimizeTestInfo> experiment = obj;
        BOOL match = [experiment.testName isEqualToString:name] && [experiment.enrolledVariantName isEqualToString:variant];
        if (!match) {
            return;
        }
        MPEvent *event = [[MPEvent alloc] initWithName:@"Apptimize experiment"
                                                type:MPEventTypeOther];
        event.customAttributes = @{@"Name" : [experiment testName],
                                   @"Variation" : [experiment enrolledVariantName],
                                   @"Name and Variation" : [NSString stringWithFormat:@"%@-%@", [experiment testName], [experiment enrolledVariantName]],
                                   @"ID" : [experiment testID],
                                   @"VariationID" : [experiment enrolledVariantID]};
        [[MParticle sharedInstance] logEvent:event];
        *stop = YES;
    }];
}

#pragma mark User attributes and identities

- (nonnull MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    [Apptimize setUserAttributeString:value forKey:key];
    return [self makeStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    [Apptimize removeUserAttributeForKey:key];
    return [self makeStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    switch (identityType) {
        case MPUserIdentityCustomerId:
        case MPUserIdentityAlias: {
            [Apptimize setPilotTargetingID:identityString];
            break;
        }

        default:
            return [self makeStatus:MPKitReturnCodeUnavailable];
            break;
    }

    return [self makeStatus:MPKitReturnCodeSuccess];
}

#pragma mark Events

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        MPEvent *mpEvent = (MPEvent*)event;
        [Apptimize track:mpEvent.name];
        return [self makeStatus:MPKitReturnCodeSuccess];
    }
    return [self makeStatus:MPKitReturnCodeUnavailable];
}

- (nonnull MPKitExecStatus *)logScreen:(MPEvent *)event {
    NSString *screenEvent = [NSString stringWithFormat:VIEWED_TAG_FORMAT, event.name];
    [Apptimize track:screenEvent];
    return [self makeStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)logInstall {
    [Apptimize track:INSTALL_TAG];
    return [self makeStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)logout {
    [Apptimize track:LOGOUT_TAG];
    return [self makeStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)logUpdate {
    [Apptimize track:UPDATE_TAG];
    return [self makeStatus:MPKitReturnCodeSuccess];
}

#pragma mark e-Commerce

- (nonnull MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(nonnull MPEvent *)event {
    [Apptimize track:LTV_TAG value:increaseAmount];
    return [self makeStatus:MPKitReturnCodeSuccess];
}

#pragma mark Assorted

- (nonnull MPKitExecStatus *)setOptOut:(BOOL)optOut {
    if (optOut) {
        [Apptimize disable];
    }
    return [self makeStatus:MPKitReturnCodeSuccess];
}

@end
