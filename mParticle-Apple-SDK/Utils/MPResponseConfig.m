#import "MPResponseConfig.h"
#import "mParticle.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPKitContainer.h"
#import "MPStateMachine.h"
#import "MPIUserDefaults.h"

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

@implementation MPResponseConfig

- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    return [self initWithConfiguration:configuration dataReceivedFromServer:YES];
}

- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration dataReceivedFromServer:(BOOL)dataReceivedFromServer {
    self = [super init];
    if (!self || MPIsNull(configuration)) {
        return nil;
    }

    _configuration = [configuration copy];
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    if (dataReceivedFromServer) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[MPKitContainer sharedInstance] configureKits:_configuration[kMPRemoteConfigKitsKey]];
        });
    }
    
    [stateMachine configureCustomModules:_configuration[kMPRemoteConfigCustomModuleSettingsKey]];
    [stateMachine configureRampPercentage:_configuration[kMPRemoteConfigRampKey]];
    [stateMachine configureTriggers:_configuration[kMPRemoteConfigTriggerKey]];
    [stateMachine configureRestrictIDFA:_configuration[kMPRemoteConfigRestrictIDFA]];
        
    // Exception handling
    NSString *auxString = !MPIsNull(_configuration[kMPRemoteConfigExceptionHandlingModeKey]) ? _configuration[kMPRemoteConfigExceptionHandlingModeKey] : nil;
    if (auxString) {
        stateMachine.exceptionHandlingMode = [auxString copy];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMPConfigureExceptionHandlingNotification
                                                            object:nil
                                                          userInfo:nil];
    }
    
    // Session timeout
    NSNumber *auxNumber = _configuration[kMPRemoteConfigSessionTimeoutKey];
    if (auxNumber != nil) {
        [MParticle sharedInstance].sessionTimeout = [auxNumber doubleValue];
    }
    
#if TARGET_OS_IOS == 1
    // Push notifications
    NSDictionary *auxDictionary = !MPIsNull(_configuration[kMPRemoteConfigPushNotificationDictionaryKey]) ? _configuration[kMPRemoteConfigPushNotificationDictionaryKey] : nil;
    if (auxDictionary) {
        [self configurePushNotifications:auxDictionary];
    }
    
    // Location tracking
    auxDictionary = !MPIsNull(_configuration[kMPRemoteConfigLocationKey]) ? _configuration[kMPRemoteConfigLocationKey] : nil;
    if (auxDictionary) {
        [self configureLocationTracking:auxDictionary];
    }
#endif
    
    return self;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_configuration forKey:@"configuration"];
}

- (id)initWithCoder:(NSCoder *)coder {
    NSDictionary *configuration = [coder decodeObjectForKey:@"configuration"];
    self = [[MPResponseConfig alloc] initWithConfiguration:configuration dataReceivedFromServer:NO];
    
    return self;
}

#pragma mark Private methods

#pragma mark Public class methods
+ (void)save:(nonnull MPResponseConfig *)responseConfig {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    if (![fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        [fileManager createDirectoryAtPath:stateMachineDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    if (!responseConfig || !responseConfig.configuration) {
        // If a kit is registered against the core SDK, there is an eTag present, and there is no corresponding kit configuration, then
        // delete the saved eTag, thus "forcing" a config refresh on the next call to the server
        MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
        NSString *eTag = userDefaults[kMPHTTPETagHeaderKey];
        if (!eTag) {
            return;
        }

        NSArray<NSNumber *> *supportedKits = [[MPKitContainer sharedInstance] supportedKits];
        for (NSNumber *kitCode in supportedKits) {
            NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"EmbeddedKit%@.eks", kitCode]];

            if (![fileManager fileExistsAtPath:kitPath]) {
                [userDefaults removeMPObjectForKey:kMPHTTPETagHeaderKey];
                break;
            }
        }

        return;
    }

    NSString *configurationPath = [stateMachineDirectoryPath stringByAppendingPathComponent:@"RequestConfig.cfg"];
    
    if ([fileManager fileExistsAtPath:configurationPath]) {
        [fileManager removeItemAtPath:configurationPath error:nil];
    }
    
    BOOL configurationArchived = [NSKeyedArchiver archiveRootObject:responseConfig.configuration toFile:configurationPath];
    if (!configurationArchived) {
        MPILogError(@"RequestConfig could not be archived.");
    }
}

+ (nullable MPResponseConfig *)restore {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *configurationPath = [stateMachineDirectoryPath stringByAppendingPathComponent:@"RequestConfig.cfg"];

    if (![fileManager fileExistsAtPath:configurationPath]) {
        return nil;
    }
    
    NSDictionary *configuration = [NSKeyedUnarchiver unarchiveObjectWithFile:configurationPath];
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration dataReceivedFromServer:NO];
    
    return responseConfig;
}

#pragma mark Public instance methods
#if TARGET_OS_IOS == 1
- (void)configureLocationTracking:(NSDictionary *)locationDictionary {
    NSString *locationMode = locationDictionary[kMPRemoteConfigLocationModeKey];
    [MPStateMachine sharedInstance].locationTrackingMode = locationMode;
    
    if ([locationMode isEqualToString:kMPRemoteConfigForceTrue]) {
        NSNumber *accurary = locationDictionary[kMPRemoteConfigLocationAccuracyKey];
        NSNumber *minimumDistance = locationDictionary[kMPRemoteConfigLocationMinimumDistanceKey];
        
        [[MParticle sharedInstance] beginLocationTracking:[accurary doubleValue] minDistance:[minimumDistance doubleValue] authorizationRequest:MPLocationAuthorizationRequestAlways];
    } else if ([locationMode isEqualToString:kMPRemoteConfigForceFalse]) {
        [[MParticle sharedInstance] endLocationTracking];
    }
}

- (void)configurePushNotifications:(NSDictionary *)pushNotificationDictionary {
    NSString *pushNotificationMode = pushNotificationDictionary[kMPRemoteConfigPushNotificationModeKey];
    [MPStateMachine sharedInstance].pushNotificationMode = pushNotificationMode;
#if !defined(MPARTICLE_APP_EXTENSIONS)
    UIApplication *app = [UIApplication sharedApplication];
    
    if ([pushNotificationMode isEqualToString:kMPRemoteConfigForceTrue]) {
        NSNumber *pushNotificationType = pushNotificationDictionary[kMPRemoteConfigPushNotificationTypeKey];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [app registerForRemoteNotificationTypes:[pushNotificationType integerValue]];
#pragma clang diagnostic pop
    } else if ([pushNotificationMode isEqualToString:kMPRemoteConfigForceFalse]) {
        [app unregisterForRemoteNotifications];
    }
#endif
}
#endif

@end
