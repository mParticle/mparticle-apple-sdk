#import "MPUploadSettings.h"
#import "MPStateMachine.h"
#import "mParticle.h"
#import "MPILogger.h"

@import mParticle_Apple_SDK_Swift;

@interface MPUploadSettings ()
@property (nonatomic, strong, nonnull) MPUploadSettingsPRIVATE *impl;
@end

@implementation MPUploadSettings

+ (void)initialize {
    if (self == [MPUploadSettings class]) {
        [NSKeyedUnarchiver setClass:[MPUploadSettings class]
                       forClassName:@"mParticle_Apple_SDK.MPUploadSettings"];
        [NSKeyedUnarchiver setClass:[MPUploadSettings class]
                       forClassName:@"mParticle_Apple_SDK_NoLocation.MPUploadSettings"];
    }
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _impl = [[MPUploadSettingsPRIVATE alloc] init];
    }
    return self;
}

- (NSString *)apiKey { return self.impl.apiKey; }
- (void)setApiKey:(NSString *)apiKey { self.impl.apiKey = apiKey; }
- (NSString *)secret { return self.impl.secret; }
- (void)setSecret:(NSString *)secret { self.impl.secret = secret; }
- (NSString *)eventsHost { return self.impl.eventsHost; }
- (void)setEventsHost:(NSString *)eventsHost { self.impl.eventsHost = eventsHost; }
- (NSString *)eventsTrackingHost { return self.impl.eventsTrackingHost; }
- (void)setEventsTrackingHost:(NSString *)eventsTrackingHost { self.impl.eventsTrackingHost = eventsTrackingHost; }
- (BOOL)overridesEventsSubdirectory { return self.impl.overridesEventsSubdirectory; }
- (void)setOverridesEventsSubdirectory:(BOOL)overridesEventsSubdirectory { self.impl.overridesEventsSubdirectory = overridesEventsSubdirectory; }
- (NSString *)aliasHost { return self.impl.aliasHost; }
- (void)setAliasHost:(NSString *)aliasHost { self.impl.aliasHost = aliasHost; }
- (NSString *)aliasTrackingHost { return self.impl.aliasTrackingHost; }
- (void)setAliasTrackingHost:(NSString *)aliasTrackingHost { self.impl.aliasTrackingHost = aliasTrackingHost; }
- (BOOL)overridesAliasSubdirectory { return self.impl.overridesAliasSubdirectory; }
- (void)setOverridesAliasSubdirectory:(BOOL)overridesAliasSubdirectory { self.impl.overridesAliasSubdirectory = overridesAliasSubdirectory; }
- (BOOL)eventsOnly { return self.impl.eventsOnly; }
- (void)setEventsOnly:(BOOL)eventsOnly { self.impl.eventsOnly = eventsOnly; }

- (id)copyWithZone:(NSZone *)zone {
    MPUploadSettings *copy = [[MPUploadSettings alloc] initWithApiKey:self.apiKey
                                                                  secret:self.secret
                                                             eventsHost:self.eventsHost
                                                      eventsTrackingHost:self.eventsTrackingHost
                                       overridesEventsSubdirectory:self.overridesEventsSubdirectory
                                                          aliasHost:self.aliasHost
                                                   aliasTrackingHost:self.aliasTrackingHost
                                        overridesAliasSubdirectory:self.overridesAliasSubdirectory
                                                        eventsOnly:self.eventsOnly];
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [self.impl encodeToCoder:coder];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _impl = [[MPUploadSettingsPRIVATE alloc] initFromCoder:coder];
    }
    return self;
}

+ (nonnull instancetype)currentUploadSettingsWithStateMachine:(nonnull id<MPStateMachineProtocol>)stateMachine
                                                networkOptions:(nonnull MPNetworkOptions *)networkOptions {
    return [[MPUploadSettings alloc] initWithApiKey:stateMachine.apiKey
                                             secret:stateMachine.secret
                                     networkOptions:networkOptions];
}

- (nonnull instancetype)initWithApiKey:(nonnull NSString *)apiKey
                                 secret:(nonnull NSString *)secret
                         networkOptions:(nonnull MPNetworkOptions *)networkOptions {
    NSString *customHost = networkOptions.customBaseURL ? networkOptions.customBaseURL.host : nil;
    if (customHost) {
        if (networkOptions.eventsHost) {
            MPILogWarning(@"MPNetworkOptions: customBaseURL is set; eventsHost is ignored.");
        }
        if (networkOptions.eventsTrackingHost) {
            MPILogWarning(@"MPNetworkOptions: customBaseURL is set; eventsTrackingHost is ignored.");
        }
        if (networkOptions.aliasHost) {
            MPILogWarning(@"MPNetworkOptions: customBaseURL is set; aliasHost is ignored.");
        }
        if (networkOptions.aliasTrackingHost) {
            MPILogWarning(@"MPNetworkOptions: customBaseURL is set; aliasTrackingHost is ignored.");
        }
    }
    return [self initWithApiKey:apiKey
                         secret:secret
                    eventsHost:[MPUploadSettingsPRIVATE resolvedHostWithCustomHost:customHost host:networkOptions.eventsHost]
             eventsTrackingHost:[MPUploadSettingsPRIVATE resolvedHostWithCustomHost:customHost host:networkOptions.eventsTrackingHost]
  overridesEventsSubdirectory:networkOptions.overridesEventsSubdirectory
                     aliasHost:[MPUploadSettingsPRIVATE resolvedHostWithCustomHost:customHost host:networkOptions.aliasHost]
              aliasTrackingHost:[MPUploadSettingsPRIVATE resolvedHostWithCustomHost:customHost host:networkOptions.aliasTrackingHost]
   overridesAliasSubdirectory:networkOptions.overridesAliasSubdirectory
                   eventsOnly:networkOptions.eventsOnly];
}

- (nonnull instancetype)initWithApiKey:(nonnull NSString *)apiKey
                                 secret:(nonnull NSString *)secret
                            eventsHost:(nullable NSString *)eventsHost
                     eventsTrackingHost:(nullable NSString *)eventsTrackingHost
          overridesEventsSubdirectory:(BOOL)overridesEventsSubdirectory
                             aliasHost:(nullable NSString *)aliasHost
                      aliasTrackingHost:(nullable NSString *)aliasTrackingHost
           overridesAliasSubdirectory:(BOOL)overridesAliasSubdirectory
                           eventsOnly:(BOOL)eventsOnly {
    self = [super init];
    if (self) {
        _impl = [[MPUploadSettingsPRIVATE alloc] initWithApiKey:apiKey
                                                         secret:secret
                                                     eventsHost:eventsHost
                                             eventsTrackingHost:eventsTrackingHost
                                    overridesEventsSubdirectory:overridesEventsSubdirectory
                                                      aliasHost:aliasHost
                                              aliasTrackingHost:aliasTrackingHost
                                     overridesAliasSubdirectory:overridesAliasSubdirectory
                                                     eventsOnly:eventsOnly];
    }
    return self;
}

@end
