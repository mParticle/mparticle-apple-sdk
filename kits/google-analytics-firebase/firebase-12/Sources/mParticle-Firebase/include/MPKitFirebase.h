#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
    #import <mParticle_Apple_SDK/mParticle_Apple_SDK.h>
#else
    #import "mParticle.h"
    #import "mParticle_Apple_SDK.h"
#endif

@interface MPKitFirebase : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

- (nullable NSNumber *)resolvedConsentForMappingKey:(NSString * _Nonnull)mappingKey
                                         defaultKey:(NSString * _Nonnull)defaultKey
                                       gdprConsents:(NSDictionary<NSString *, MPGDPRConsent *> * _Nonnull)gdprConsents
                                            mapping:(NSDictionary<NSString *, NSString *> * _Nullable)mapping;

- (nullable NSArray<NSDictionary *>*)mappingForKey:(NSString* _Nonnull)key;

- (nonnull NSDictionary*)convertToKeyValuePairs:(NSArray<NSDictionary *> * _Nonnull)mappings;

@end

static NSString * _Nonnull const kMPFIRGoogleAppIDKey = @"firebaseAppId";
static NSString * _Nonnull const kMPFIRSenderIDKey = @"googleProjectNumber";
static NSString * _Nonnull const kMPFIRAPIKey = @"firebaseAPIKey";
static NSString * _Nonnull const kMPFIRProjectIDKey = @"firebaseProjectId";
static NSString * _Nonnull const kMPFIRExternalUserIdentityType = @"userIdField";
static NSString * _Nonnull const kMPFIRShouldHashUserId = @"hashUserId";
static NSString * _Nonnull const kMPFIRForwardRequestsServerSide = @"forwardWebRequestsServerSide";
static NSString * _Nonnull const kMPFIRCommerceEventType = @"Firebase.CommerceEventType";
static NSString * _Nonnull const kMPFIRPaymentType = @"Firebase.PaymentType";
static NSString * _Nonnull const kMPFIRShippingTier = @"Firebase.ShippingTier";
