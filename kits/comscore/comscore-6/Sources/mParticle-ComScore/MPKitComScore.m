#import "MPKitComScore.h"
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import "mParticle.h"
#endif
#if defined(__has_include) && __has_include(<ComScore/ComScore.h>)
#import <ComScore/ComScore.h>
#else
#import "ComScore.h"
#endif

typedef NS_ENUM(NSUInteger, MPcomScoreProduct) {
    MPcomScoreProductDirect = 1,
    MPcomScoreProductEnterprise
};

NSString *const ecsCustomerC2 = @"CustomerC2Value";
NSString *const ecsSecret = @"PublisherSecret";
NSString *const ecsAutoUpdateMode = @"autoUpdateMode";
NSString *const ecsAutoUpdateInterval = @"autoUpdateInterval";
NSString *const escAppName = @"appName";
NSString *const escProduct = @"product";
NSString *const ecsPartnerId = @"partnerId";

@interface MPKitComScore()

@property (nonatomic, unsafe_unretained) MPcomScoreProduct product;

@end

@implementation MPKitComScore

+ (NSNumber *)kitCode {
    return @39;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"comScore" className:@"MPKitComScore"];
    [MParticle registerExtension:kitRegister];
}

- (void)setupWithConfiguration:(NSDictionary *)configuration {
    SCORPublisherConfiguration *publisherConfig = [SCORPublisherConfiguration publisherConfigurationWithBuilderBlock:^(SCORPublisherConfigurationBuilder *builder) {
        builder.publisherId = configuration[ecsCustomerC2];
        builder.secureTransmissionEnabled = YES;
    }];
    [[SCORAnalytics configuration] addClientWithConfiguration:publisherConfig];

    SCORPartnerConfiguration *partnerConfig = [SCORPartnerConfiguration partnerConfigurationWithBuilderBlock:^(SCORPartnerConfigurationBuilder *builder) {
        builder.partnerId = configuration[ecsPartnerId];
    }];
    [[SCORAnalytics configuration] addClientWithConfiguration:partnerConfig];

    [SCORAnalytics configuration].usagePropertiesAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeForegroundOnly;
    [SCORAnalytics configuration].usagePropertiesAutoUpdateInterval = [configuration[ecsAutoUpdateInterval] intValue];

    if ([[configuration[ecsAutoUpdateMode] lowercaseString] isEqualToString:@"foreback"]) {
        [SCORAnalytics configuration].usagePropertiesAutoUpdateMode = SCORUsagePropertiesAutoUpdateModeForegroundAndBackground;
    }

    if (configuration[escAppName]) {
        [SCORAnalytics configuration].applicationName = configuration[escAppName];
    }

    [SCORAnalytics start];

    if (configuration[escProduct]) {
        self.product = [configuration[escProduct] isEqualToString:@"enterprise"] ? MPcomScoreProductEnterprise : MPcomScoreProductDirect;
    }
}

#pragma mark Private methods
- (BOOL)isValidConfiguration:(NSDictionary *)configuration {
    NSString *customerC2 = configuration[ecsCustomerC2];
    NSString *secret = configuration[ecsSecret];

    BOOL validConfiguration = customerC2 != nil && (customerC2.length > 0) &&
        secret != nil && (secret.length > 0);

    return validConfiguration;
}

- (NSDictionary *)convertAllValuesToString:(NSDictionary *)originalDictionary {
    NSMutableDictionary *convertedDictionary = [[NSMutableDictionary alloc] initWithCapacity:originalDictionary.count];
    NSEnumerator *originalEnumerator = [originalDictionary keyEnumerator];
    NSString *key;
    id value;
    Class NSStringClass = [NSString class];

    while ((key = [originalEnumerator nextObject])) {
        value = originalDictionary[key];

        if ([value isKindOfClass:NSStringClass]) {
            convertedDictionary[key] = value;
        } else {
            convertedDictionary[key] = [NSString stringWithFormat:@"%@", value];
        }
    }

    return convertedDictionary;
}

#pragma mark MPKitInstanceProtocol methods
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;

    if (![self isValidConfiguration:configuration]) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }

    self.product = MPcomScoreProductDirect;

    [self setupWithConfiguration:configuration];

    _configuration = configuration;
    _started = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });

    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logBaseEvent:(MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else {
        return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeUnavailable];
    }
}

- (MPKitExecStatus *)routeEvent:(MPEvent *)event {
    MPKitExecStatus *execStatus;

    if (self.product != MPcomScoreProductEnterprise) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeIncorrectProductVersion];
        return execStatus;
    }

    if (event.type == MPEventTypeNavigation) {
        return [self logScreen:event];
    } else {
        NSMutableDictionary *labelsDictionary = [@{@"name":event.name} mutableCopy];
        if (event.customAttributes) {
            [labelsDictionary addEntriesFromDictionary:[self convertAllValuesToString:event.customAttributes]];
        }
        [SCORAnalytics notifyHiddenEventWithLabels:labelsDictionary];
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
        return execStatus;
    }
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    MPKitExecStatus *execStatus;

    if (self.product != MPcomScoreProductEnterprise) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeIncorrectProductVersion];
        return execStatus;
    }

    NSMutableDictionary *labelsDictionary = [@{@"name":event.name} mutableCopy];
    if (event.customAttributes) {
        [labelsDictionary addEntriesFromDictionary:[self convertAllValuesToString:event.customAttributes]];
    }
    [SCORAnalytics notifyViewEventWithLabels:labelsDictionary];
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDebugMode:(BOOL)debugMode {
    [SCORAnalytics setLogLevel:SCORLogLevelDebug];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    if (optOut) {
        [[SCORAnalytics configuration] disable];
    }
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    MPKitExecStatus *execStatus;

    if (self.product != MPcomScoreProductEnterprise) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeIncorrectProductVersion];
        return execStatus;
    }

    if (value != nil) {
        [[SCORAnalytics configuration] setPersistentLabelWithName:key value:value];
    }
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserTag:(NSString *)tag {
    MPKitExecStatus *execStatus;

    if (self.product != MPcomScoreProductEnterprise) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeIncorrectProductVersion];
        return execStatus;
    }

    [[SCORAnalytics configuration] setPersistentLabelWithName:tag value:@""];
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

@end
