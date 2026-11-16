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

    // An app key that is not a string, or is empty, is treated as missing. It would otherwise reach the
    // Apptimize SDK inside start's dispatch_once, and a raise inside dispatch_once cannot be recovered.
    if ([self appKeyFromConfiguration:configuration] == nil) {
        NSLog(@"mParticle -> Not starting Apptimize: the configuration has no app key");
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }

    _configuration = configuration;

    [self start];

    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)start {
    // The Apptimize SDK is a process-wide singleton, so the start stays behind one dispatch_once.
    // Every configuration read runs before it, so no configuration read inside the block can raise.
    NSString *appKey = [self appKeyFromConfiguration:self.configuration];
    if (appKey == nil) {
        return;
    }
    NSDictionary *options = [self buildApptimizeOptions];
    void(^start_block)(void) = ^{
        [Apptimize startApptimizeWithApplicationKey:appKey options:options];
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
    NSNumber *pairing = [self configBoolForKey:DEVICE_PAIRING_MP_KEY];
    if (pairing) {
        [o setObject:pairing forKey:ApptimizeDevicePairingOption];
    }
}

- (void)configureApptimizeDelayUntilTestsAreAvailable:(NSMutableDictionary*)o {
    NSNumber *delay = [self configDoubleForKey:DELAY_UNTIL_TESTS_ARE_AVAILABLE_MP_KEY];
    if (delay) {
        [o setObject:delay forKey:ApptimizeDelayUntilTestsAreAvailableOption];
    }
}

- (void)configureApptimizeLogLevel:(NSMutableDictionary*)o {
    NSString *logLevel = [self configStringForKey:LOG_LEVEL_MP_KEY];
    if (logLevel) {
        [o setObject:logLevel forKey:ApptimizeLogLevelOption];
    }
}

#pragma mark Configuration values

// Server configuration is parsed JSON, so neither the dictionary nor its values are guaranteed to have
// the type the mParticle UI collects. A wrong-typed value is logged and treated as unset, which leaves
// the Apptimize default in place.
- (nullable NSString *)appKeyFromConfiguration:(id)configuration {
    id value = [configuration isKindOfClass:[NSDictionary class]] ? configuration[APP_MP_KEY] : nil;
    if (![value isKindOfClass:[NSString class]] || [(NSString *)value length] == 0) {
        return nil;
    }
    return value;
}

- (nullable id) configValueForKey:(NSString*)key {
    id value = [self.launchOptions isKindOfClass:[NSDictionary class]] ? self.launchOptions[key] : nil;
    if (value == nil) {
        value = [self.configuration isKindOfClass:[NSDictionary class]] ? self.configuration[key] : nil;
    }
    return value;
}

- (nullable NSString *)configStringForKey:(NSString *)key {
    id value = [self configValueForKey:key];
    if (value != nil && ![value isKindOfClass:[NSString class]]) {
        NSLog(@"Ignoring configuration value for %@: expected a string, got %@", key, [value class]);
        return nil;
    }
    return value;
}

// Returns the value as a boolean NSNumber, from a string or a number, the forms other kits accept.
- (nullable NSNumber *)configBoolForKey:(NSString *)key {
    id value = [self configValueForKey:key];
    if (value == nil) {
        return nil;
    }
    if (!([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])) {
        NSLog(@"Ignoring configuration value for %@: expected a string or number, got %@", key, [value class]);
        return nil;
    }
    return @([value boolValue]);
}

// Returns the value as a double NSNumber, from a string or a number.
- (nullable NSNumber *)configDoubleForKey:(NSString *)key {
    id value = [self configValueForKey:key];
    if (value == nil) {
        return nil;
    }
    if (!([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])) {
        NSLog(@"Ignoring configuration value for %@: expected a string or number, got %@", key, [value class]);
        return nil;
    }
    return @([value doubleValue]);
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
