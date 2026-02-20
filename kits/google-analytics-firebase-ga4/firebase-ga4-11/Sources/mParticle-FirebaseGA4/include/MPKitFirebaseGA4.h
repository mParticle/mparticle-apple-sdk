#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
    #import <mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>
#else
    #import "mParticle.h"
    #import "mParticle_Apple_SDK-Swift.h"
#endif

@interface MPKitFirebaseGA4 : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

+ (void)setCustomNameStandardization:(NSString * _Nonnull (^_Nullable)(NSString * _Nonnull name))standardization;
+ (NSString * _Nonnull (^_Nullable)(NSString * _Nonnull name))customNameStandardization;

- (nullable NSNumber *)resolvedConsentForMappingKey:(NSString * _Nonnull)mappingKey
                                         defaultKey:(NSString * _Nonnull)defaultKey
                                       gdprConsents:(NSDictionary<NSString *, MPGDPRConsent *> * _Nonnull)gdprConsents
                                            mapping:(NSDictionary<NSString *, NSString *> * _Nullable)mapping;

- (nullable NSArray<NSDictionary *>*)mappingForKey:(NSString* _Nonnull)key;

- (nonnull NSDictionary*)convertToKeyValuePairs:(NSArray<NSDictionary *> * _Nonnull)mappings;

@end

static NSString * _Nonnull const kMPFIRGA4ExternalUserIdentityType = @"externalUserIdentityType";
static NSString * _Nonnull const kMPFIRGA4ShouldHashUserId = @"hashUserId";
static NSString * _Nonnull const kMPFIRGA4ForwardRequestsServerSide = @"forwardWebRequestsServerSide";
static NSString * _Nonnull const kMPFIRGA4CommerceEventType = @"GA4.CommerceEventType";
static NSString * _Nonnull const kMPFIRGA4PaymentType = @"GA4.PaymentType";
static NSString * _Nonnull const kMPFIRGA4ShippingTier = @"GA4.ShippingTier";
