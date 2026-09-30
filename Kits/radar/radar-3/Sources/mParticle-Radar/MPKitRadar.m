#import "MPKitRadar.h"
#import <CoreLocation/CoreLocation.h>

#if defined(__has_include) && __has_include(<RadarSDK/Radar.h>)
    #import <RadarSDK/Radar.h>
#else
    #import "Radar.h"
#endif

NSString *const KEY_PUBLISHABLE_KEY = @"publishableKey";
NSString *const KEY_RUN_AUTOMATICALLY = @"runAutomatically";

@interface MPKitRadar () {
    BOOL runAutomatically;
}

@end

@implementation MPKitRadar

+ (NSNumber *)kitCode {
    return @117;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Radar" className:@"MPKitRadar"];
    [MParticle registerExtension:kitRegister];
}

- (void)tryStartTracking {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    BOOL hasAuthorized = status == kCLAuthorizationStatusAuthorizedAlways;

    if (hasAuthorized) {
        [Radar startTrackingWithOptions:RadarTrackingOptions.presetEfficient];
    }
}

- (void)tryTrackOnce {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    BOOL hasAuthorized = status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse;

    if (hasAuthorized) {
        [Radar trackOnceWithCompletionHandler:nil];
    }
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

- (BOOL)configurationBoolForKey:(NSString *)key {
    id value = [self configurationValueForKey:key];
    if (value != nil && !([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])) {
        NSLog(@"Ignoring configuration value for %@: expected a string or number, got %@", key, [value class]);
        return NO;
    }
    return [value boolValue];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle

- (void)updateConfiguredSettings {
    runAutomatically = [self configurationBoolForKey:KEY_RUN_AUTOMATICALLY];
}

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    if (![configuration isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Ignoring launch configuration: expected a dictionary, got %@", [configuration class]);
        _configuration = @{};
        return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
    }

    _configuration = [configuration copy];

    NSString *publishableKey = [self configurationStringForKey:KEY_PUBLISHABLE_KEY];
    if (publishableKey.length == 0) {
        return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
    }

    // After the requirements check, so a rejected configuration leaves no tracking state behind.
    [self updateConfiguredSettings];

    [Radar initializeWithPublishableKey:publishableKey];

    [self start];

    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
}

- (void)start {
    static dispatch_once_t kitPredicate;

    dispatch_once(&kitPredicate, ^{
        FilteredMParticleUser *user = [[self kitApi] getCurrentUserWithKit:self];
        NSString *mpId = [self getMpId:user];
        if (mpId != nil) {
            NSDictionary *metadata = @{@"mParticleId": mpId};
            [Radar setMetadata:metadata];
        }
        if (self->runAutomatically) {
            [self tryStartTracking];
        } else {
            [Radar stopTracking];
        }
    });

    self->_started = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey: [[self class] kitCode]};
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification object:nil userInfo:userInfo];
    });
}

- (MPKitAPI *)kitApi {
    if (_kitApi == nil) {
        _kitApi = [[MPKitAPI alloc] init];
    }

    return _kitApi;
}

- (id const)providerKitInstance {
    return nil;
}

#pragma mark Application

- (MPKitExecStatus *)didBecomeActive {
    if (runAutomatically) {
        [self tryTrackOnce];
    }

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitRadar kitCode] returnCode:MPKitReturnCodeSuccess];
}

#pragma mark User attributes and identities

- (NSString *)getMpId:(FilteredMParticleUser *)user {
    if (user != nil && user.userId != nil && user.userId.integerValue != 0) {
        return [user.userId stringValue];
    } else {
        return nil;
    }
}

- (void)setRadarMetadata:(NSString *)mpId {
    if ([Radar getMetadata] != nil) {
        NSMutableDictionary *metadata = [[Radar getMetadata] mutableCopy];
        [metadata setObject:mpId forKey:@"mParticleId"];
        [Radar setMetadata:metadata];
    } else {
        NSDictionary *metadata = @{@"mParticleId": mpId};
        [Radar setMetadata:metadata];
    }
}

- (void)setRadarUserId:(FilteredMParticleUser *)user {
    NSString *customerId = [user.userIdentities objectForKey:[NSNumber numberWithInt:MPUserIdentityCustomerId]];
    [Radar setUserId:customerId];
}

- (void)setUserAndTrack:(FilteredMParticleUser *)user {
    NSString *mpId = [self getMpId:user];
    if (mpId != nil) {
        [self setRadarMetadata:mpId];
        [self setRadarUserId:user];
    }
    if (runAutomatically) {
        [self tryTrackOnce];
        [self tryStartTracking];
    }
}

- (MPKitExecStatus *)onLoginComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    [self setUserAndTrack:user];
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitRadar kitCode] returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)onLogoutComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    [self setUserAndTrack:user];
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitRadar kitCode] returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)onIdentifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    [self setUserAndTrack:user];
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitRadar kitCode] returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)onModifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    [self setUserAndTrack:user];
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitRadar kitCode] returnCode:MPKitReturnCodeSuccess];
}

#pragma mark Assorted

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    if (runAutomatically) {
        [Radar stopTracking];
    }

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitRadar kitCode] returnCode:MPKitReturnCodeSuccess];
}

@end
