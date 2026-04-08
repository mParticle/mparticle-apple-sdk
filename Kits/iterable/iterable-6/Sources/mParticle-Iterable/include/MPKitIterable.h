#import <Foundation/Foundation.h>
@import mParticle_Apple_SDK_ObjC;

#import "IterableMPHelper.h"

@class IterableConfig;

@interface MPKitIterable : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) NSArray<NSDictionary<NSString *, id> *> *userIdentities;
@property (nonatomic, readwrite) BOOL mpidEnabled;

/// Set a custom config to be used when initializing Iterable SDK.
/// @param config `IterableConfig` instance with configuration data for Iterable SDK
+ (void)setCustomConfig:(IterableConfig *_Nullable)config;

/// Set a custom config to be used when initializing Iterable SDK. To be used in cases where
/// the compiler cannot resolve the IterableConfig type, such as with Swift Package Manager.
/// @param config `IterableConfig` instance with configuration data for Iterable SDK
+ (void)setCustomConfigObject:(id _Nullable)config;

/// Declare whether or not to prefer user id in API calls to Iterable. If `YES`, the kit will not
/// set an email or create a placeholder.email address.
+ (void)setPrefersUserId:(BOOL)prefers;
+ (BOOL)prefersUserId;

@end
