#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
#else
    #import "mParticle.h"
#endif

@interface MPKitRokt : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;

+ (NSDictionary<NSString *, NSString *> * _Nonnull)prepareAttributes:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes filteredUser:(FilteredMParticleUser * _Nullable)filteredUser performMapping:(BOOL)performMapping;
+ (NSNumber * _Nullable)getRoktHashedEmailUserIdentityType;
+ (void)logSelectPlacementEvent:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes;

@end
