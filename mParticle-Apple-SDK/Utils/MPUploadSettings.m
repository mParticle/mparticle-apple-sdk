#import "MPUploadSettings.h"
#import "MPStateMachine.h"
#import "mParticle.h"

static NSString *const kApiKey = @"apiKey";
static NSString *const kSecret = @"secret";
static NSString *const kEventsHost = @"eventsHost";
static NSString *const kEventsTrackingHost = @"eventsTrackingHost";
static NSString *const kOverridesEventsSubdirectory = @"overridesEventsSubdirectory";
static NSString *const kAliasHost = @"aliasHost";
static NSString *const kAliasTrackingHost = @"aliasTrackingHost";
static NSString *const kOverridesAliasSubdirectory = @"overridesAliasSubdirectory";
static NSString *const kEventsOnly = @"eventsOnly";

@implementation MPUploadSettings

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _apiKey = @"";
        _secret = @"";
        _overridesEventsSubdirectory = NO;
        _overridesAliasSubdirectory = NO;
        _eventsOnly = NO;
    }
    return self;
}

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
    [coder encodeObject:self.apiKey forKey:kApiKey];
    [coder encodeObject:self.secret forKey:kSecret];
    [coder encodeObject:self.eventsHost forKey:kEventsHost];
    [coder encodeObject:self.eventsTrackingHost forKey:kEventsTrackingHost];
    [coder encodeBool:self.overridesEventsSubdirectory forKey:kOverridesEventsSubdirectory];
    [coder encodeObject:self.aliasHost forKey:kAliasHost];
    [coder encodeObject:self.aliasTrackingHost forKey:kAliasTrackingHost];
    [coder encodeBool:self.overridesAliasSubdirectory forKey:kOverridesAliasSubdirectory];
    [coder encodeBool:self.eventsOnly forKey:kEventsOnly];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _apiKey = [coder decodeObjectOfClass:[NSString class] forKey:kApiKey] ?: @"";
        _secret = [coder decodeObjectOfClass:[NSString class] forKey:kSecret] ?: @"";
        _eventsHost = [coder decodeObjectOfClass:[NSString class] forKey:kEventsHost];
        _eventsTrackingHost = [coder decodeObjectOfClass:[NSString class] forKey:kEventsTrackingHost];
        _overridesEventsSubdirectory = [coder decodeBoolForKey:kOverridesEventsSubdirectory];
        _aliasHost = [coder decodeObjectOfClass:[NSString class] forKey:kAliasHost];
        _aliasTrackingHost = [coder decodeObjectOfClass:[NSString class] forKey:kAliasTrackingHost];
        _overridesAliasSubdirectory = [coder decodeBoolForKey:kOverridesAliasSubdirectory];
        _eventsOnly = [coder decodeBoolForKey:kEventsOnly];
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
    return [self initWithApiKey:apiKey
                         secret:secret
                    eventsHost:networkOptions.eventsHost
             eventsTrackingHost:networkOptions.eventsTrackingHost
  overridesEventsSubdirectory:networkOptions.overridesEventsSubdirectory
                     aliasHost:networkOptions.aliasHost
              aliasTrackingHost:networkOptions.aliasTrackingHost
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
        _apiKey = [apiKey copy];
        _secret = [secret copy];
        _eventsHost = [eventsHost copy];
        _eventsTrackingHost = [eventsTrackingHost copy];
        _overridesEventsSubdirectory = overridesEventsSubdirectory;
        _aliasHost = [aliasHost copy];
        _aliasTrackingHost = [aliasTrackingHost copy];
        _overridesAliasSubdirectory = overridesAliasSubdirectory;
        _eventsOnly = eventsOnly;
    }
    return self;
}

@end
