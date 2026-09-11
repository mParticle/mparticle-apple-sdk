#import <Foundation/Foundation.h>

// MPCookie now lives in Swift as MPCookiePRIVATE, exported under its original Objective-C runtime
// name. MPConsumerInfo still needs the type for its `cookies` property.
@import mParticle_Apple_SDK_Swift;

// The cookie wire keys stay C globals: Swift cannot emit them, and Objective-C callers still use
// them to build a cookie configuration (see MParticleTests).
extern NSString * _Nonnull const kMPCKContent;
extern NSString * _Nonnull const kMPCKDomain;
extern NSString * _Nonnull const kMPCKExpiration;

#pragma mark - MPConsumerInfo
@interface MPConsumerInfo : NSObject <NSSecureCoding>

@property (nonatomic) int64_t consumerInfoId;
@property (nonatomic, strong, nullable) NSArray<MPCookie *> *cookies;
@property (nonatomic, strong, nullable) NSString *uniqueIdentifier;
@property (nonatomic, strong, nullable, readonly) NSString *deviceApplicationStamp;

- (nullable NSDictionary *)cookiesDictionaryRepresentation;
- (void)updateWithConfiguration:(nonnull NSDictionary *)configuration;

@end
