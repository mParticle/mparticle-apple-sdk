#import <Foundation/Foundation.h>
@import mParticle_Apple_SDK_ObjC;

@interface MPKitRokt : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;

+ (NSDictionary<NSString *, NSString *> * _Nonnull)prepareAttributes:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes filteredUser:(FilteredMParticleUser * _Nullable)filteredUser performMapping:(BOOL)performMapping;
+ (NSNumber * _Nullable)getRoktHashedEmailUserIdentityType;
+ (void)logSelectPlacementEvent:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes;

@end
