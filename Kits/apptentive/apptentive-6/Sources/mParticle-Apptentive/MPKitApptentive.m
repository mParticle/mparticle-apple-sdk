#import "MPKitApptentive.h"
#import "MPKitApptentiveUtils.h"

#if SWIFT_PACKAGE
    @import ApptentiveKit;
#else
#if __has_include(<ApptentiveKit/ApptentiveKit-Swift.h>)
    #import <ApptentiveKit/ApptentiveKit-Swift.h>
#else
    #import "ApptentiveKit-Swift.h"
#endif
#endif

static NSString * const apptentiveAppKeyKey = @"apptentiveAppKey";
static NSString * const apptentiveAppSignatureKey = @"apptentiveAppSignature";
static NSString * const apptentiveInitOnStart = @"apptentiveInitOnStart";
static NSString * const apptentiveEnableTypeDetectionKey = @"enableTypeDetection";

// we need to keep the credentials in order to init the SDK later on
static NSString * _apptentiveKey = nil;
static NSString * _apptentiveSignature = nil;

@interface MPKitApptentive ()

@property (strong, nonatomic) NSPersonNameComponents *nameComponents;
@property (strong, nonatomic) NSPersonNameComponentsFormatter *nameFormatter;
@property (assign, nonatomic) BOOL enableTypeDetection;

@end

@interface NSNumber (ApptentiveBoolean)

- (BOOL)apptentive_isBoolean;

@end

@implementation NSNumber (ApptentiveBoolean)

- (BOOL)apptentive_isBoolean {
    CFTypeID boolID = CFBooleanGetTypeID();
    CFTypeID numID = CFGetTypeID((__bridge CFTypeRef)(self));
    return numID == boolID;
}

@end

@implementation MPKitApptentive

+ (NSNumber *)kitCode {
    return @(97);
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Apptentive" className:@"MPKitApptentive"];
    [MParticle registerExtension:kitRegister];
}

- (MPKitExecStatus *)execStatus:(MPKitReturnCode)returnCode {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.class.kitCode returnCode:returnCode];
}

#pragma mark Private methods

// Server configuration is parsed JSON, and the container rewrites it on every config refresh, so
// neither the dictionary nor its values are guaranteed to have the type the mParticle UI collects.
- (id)configurationValueForKey:(NSString *)key {
    return [_configuration isKindOfClass:[NSDictionary class]] ? _configuration[key] : nil;
}

- (NSString *)configurationStringForKey:(NSString *)key {
    id value = [self configurationValueForKey:key];
    if (value != nil && ![value isKindOfClass:[NSString class]]) {
        NSLog(@"Ignoring configuration value for %@: expected a string, got %@", key, [value class]);
        return nil;
    }
    return value;
}

// An absent value and one that is neither a string nor a number both take the default.
- (BOOL)configurationBoolForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    id value = [self configurationValueForKey:key];
    if (value == nil) {
        return defaultValue;
    }
    if (!([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])) {
        NSLog(@"Ignoring configuration value for %@: expected a string or number, got %@", key, [value class]);
        return defaultValue;
    }
    return [value boolValue];
}

- (void)updateConfiguredSettings {
    self.enableTypeDetection = [self configurationBoolForKey:apptentiveEnableTypeDetectionKey defaultValue:YES];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    // Server configuration is parsed JSON, so a credential that is not a string is treated as missing.
    NSString *appKey = [configuration[apptentiveAppKeyKey] isKindOfClass:[NSString class]] ? configuration[apptentiveAppKeyKey] : nil;
    NSString *appSignature = [configuration[apptentiveAppSignatureKey] isKindOfClass:[NSString class]] ? configuration[apptentiveAppSignatureKey] : nil;

    if (appKey == nil || appSignature == nil) {
        if (appKey == nil) {
            NSLog(@"No Apptentive App Key provided.");
        }

        if (appSignature == nil) {
            NSLog(@"No Apptentive App Signature provided.");
        }

        NSLog(@"Please see the Apptentive mParticle integration guide: https://learn.apptentive.com/knowledge-base/mparticle-integration-ios/");
    }

    if (!appKey || !appSignature) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }
    
    _configuration = configuration;
    [self updateConfiguredSettings];

    [self start];

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (void)start {
    // The core also calls -start after a launch that reported RequirementsNotMet. Registration runs
    // once per process, so it must not be spent before there are credentials to register with.
    if ([self configurationStringForKey:apptentiveAppKeyKey].length == 0 ||
        [self configurationStringForKey:apptentiveAppSignatureKey].length == 0) {
        NSLog(@"mParticle -> Not starting Apptentive: the configuration has no app key or signature");
        return;
    }

    static dispatch_once_t kitPredicate;

    dispatch_once(&kitPredicate, ^{
        _apptentiveKey = [self configurationStringForKey:apptentiveAppKeyKey];
        _apptentiveSignature = [self configurationStringForKey:apptentiveAppSignatureKey];

        // do we need to init the SDK while the Kit starts
        BOOL initOnStart = [self configurationBoolForKey:apptentiveInitOnStart defaultValue:YES];

        if (initOnStart) {
            [[self class] registerSDK];
        } else {
            NSLog(@"Apptentive SDK was not initialized on startup");
        }

        self->_started = YES;

        if ([NSPersonNameComponents class]) {
            self->_nameFormatter = [[NSPersonNameComponentsFormatter alloc] init];
            self->_nameComponents = [[NSPersonNameComponents alloc] init];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];

            NSNumber *currentUserId = MParticle.sharedInstance.identity.currentUser.userId;
            [Apptentive.shared setMParticleID:[currentUserId isEqualToNumber:@0] ? nil : currentUserId.stringValue];
        });
    });
}

- (id const)providerKitInstance {
    return [self started] ? Apptentive.shared : nil;
}

+ (BOOL)registerSDK {
    if (_apptentiveKey.length == 0) {
        NSLog(@"Unable to initialize Apptentive SDK: apptentive key is nil or empty");
        return NO;
    }

    if (_apptentiveSignature.length == 0) {
        NSLog(@"Unable to initialize Apptentive SDK: apptentive signature is nil or empty");
        return NO;
    }

    NSLog(@"Registering Apptentive SDK");
    ApptentiveConfiguration *apptentiveConfig = [ApptentiveConfiguration configurationWithApptentiveKey:_apptentiveKey apptentiveSignature:_apptentiveSignature];

    apptentiveConfig.distributionName = @"mParticle";
    apptentiveConfig.distributionVersion = [MParticle sharedInstance].version;

    switch ([MParticle sharedInstance].logLevel) {
        case MPILogLevelNone:
            apptentiveConfig.logLevel = ApptentiveLogLevelCrit;
            break;

        case MPILogLevelError:
            apptentiveConfig.logLevel = ApptentiveLogLevelError;
            break;

        case MPILogLevelWarning:
            apptentiveConfig.logLevel = ApptentiveLogLevelWarn;
            break;

        case MPILogLevelDebug:
            apptentiveConfig.logLevel = ApptentiveLogLevelDebug;
            break;

        case MPILogLevelVerbose:
            apptentiveConfig.logLevel = ApptentiveLogLevelVerbose;
            break;
    }

    [Apptentive.shared registerWithConfiguration:apptentiveConfig completion:nil];

    return YES;
}

#pragma mark Application

// NOTE: Called when a remote notification is received
- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    BOOL handledByApptentive = [Apptentive.shared didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];

    NSLog(@"Apptentive %@ handle remote notification.", handledByApptentive ? @"did" : @"did not");

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    // TODO: use `setRemoteNotificationToken` after next ApptentiveKit release (missing @objc annotation).
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [Apptentive.shared setPushProvider:ApptentivePushProviderApptentive deviceToken:deviceToken];
#pragma clang diagnostic pop

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response {
    BOOL handledByApptentive = [Apptentive.shared didReceveUserNotificationResponse:response withCompletionHandler:^{}];

    NSLog(@"Apptentive %@ handle user notification response.", handledByApptentive ? @"did" : @"did not");

    return [self execStatus:MPKitReturnCodeSuccess];
}

#pragma mark User attributes and identities

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    if ([key isEqualToString:mParticleUserAttributeFirstName]) {
        self.nameComponents.givenName = value;
    } else if ([key isEqualToString:mParticleUserAttributeLastName]) {
        self.nameComponents.familyName = value;
    } else {
        [Apptentive.shared addCustomPersonDataString:value withKey:key];
        if (self.enableTypeDetection) {
            id typedValue = MPKitApptentiveParseValue(value);
            if ([typedValue isKindOfClass:[NSNumber class]]) {
                if ([typedValue apptentive_isBoolean]) {
                    [Apptentive.shared addCustomPersonDataBool:typedValue withKey:[NSString stringWithFormat:@"%@_flag", key]];
                } else {
                    [Apptentive.shared addCustomPersonDataNumber:typedValue withKey:[NSString stringWithFormat:@"%@_number", key]];
                }
            }
        }
    }

    NSString *name = [self.nameFormatter stringFromPersonNameComponents:self.nameComponents];

    if (name) {
        Apptentive.shared.personName = name;
    }

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    [Apptentive.shared removeCustomPersonDataWithKey:key];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    MPKitReturnCode returnCode;

    if (identityType == MPUserIdentityEmail) {
        Apptentive.shared.personEmailAddress = identityString;
        returnCode = MPKitReturnCodeSuccess;
    } else if (identityType == MPUserIdentityCustomerId) {
        if (Apptentive.shared.personName.length == 0) {
            Apptentive.shared.personName = identityString;
        }
        returnCode = MPKitReturnCodeSuccess;
    } else {
        returnCode = MPKitReturnCodeRequirementsNotMet;
    }

    return [self execStatus:returnCode];
}

#pragma mark Events

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else {
        return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceApptentive) returnCode:MPKitReturnCodeUnavailable];
    }
}

#pragma mark Events

- (MPKitExecStatus *)routeEvent:(MPEvent *)event {
    NSDictionary *eventValues = event.customAttributes;
    if ([eventValues count] > 0) {
        [Apptentive.shared engage:event.name withCustomData:[self parseEventInfoDictionary:eventValues] fromViewController:nil];
    } else {
        [Apptentive.shared engage:event.name fromViewController:nil];
    }
    return [self execStatus:MPKitReturnCodeSuccess];
}

#pragma mark Screen Events

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    return [self logBaseEvent:event];
}

#pragma mark Helpers

- (NSDictionary *)parseEventInfoDictionary:(NSDictionary *)info {
    NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
    for (id key in info) {
        id value = info[key];
        res[key] = value;
        
        if (self.enableTypeDetection) {
            id typedValue = MPKitApptentiveParseValue(value);
            if ([typedValue isKindOfClass:[NSNumber class]]) {
                if ([typedValue apptentive_isBoolean]) {
                    res[[NSString stringWithFormat:@"%@_flag", key]] = typedValue;
                } else {
                    res[[NSString stringWithFormat:@"%@_number", key]] = typedValue;
                }
            }
        }
    }
    return res;
}

@end
