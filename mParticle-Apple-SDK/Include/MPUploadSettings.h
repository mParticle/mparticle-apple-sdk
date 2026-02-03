#import <Foundation/Foundation.h>

@protocol MPStateMachineProtocol;
@class MPNetworkOptions;

@interface MPUploadSettings : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, copy, nonnull) NSString *apiKey;
@property (nonatomic, copy, nonnull) NSString *secret;
@property (nonatomic, copy, nullable) NSString *eventsHost;
@property (nonatomic, copy, nullable) NSString *eventsTrackingHost;
@property (nonatomic) BOOL overridesEventsSubdirectory;
@property (nonatomic, copy, nullable) NSString *aliasHost;
@property (nonatomic, copy, nullable) NSString *aliasTrackingHost;
@property (nonatomic) BOOL overridesAliasSubdirectory;
@property (nonatomic) BOOL eventsOnly;

+ (nonnull instancetype)currentUploadSettingsWithStateMachine:(nonnull id<MPStateMachineProtocol>)stateMachine
                                                networkOptions:(nonnull MPNetworkOptions *)networkOptions;

- (nonnull instancetype)initWithApiKey:(nonnull NSString *)apiKey
                                 secret:(nonnull NSString *)secret
                         networkOptions:(nonnull MPNetworkOptions *)networkOptions;

- (nonnull instancetype)initWithApiKey:(nonnull NSString *)apiKey
                                 secret:(nonnull NSString *)secret
                            eventsHost:(nullable NSString *)eventsHost
                     eventsTrackingHost:(nullable NSString *)eventsTrackingHost
          overridesEventsSubdirectory:(BOOL)overridesEventsSubdirectory
                             aliasHost:(nullable NSString *)aliasHost
                      aliasTrackingHost:(nullable NSString *)aliasTrackingHost
           overridesAliasSubdirectory:(BOOL)overridesAliasSubdirectory
                           eventsOnly:(BOOL)eventsOnly;

@end
