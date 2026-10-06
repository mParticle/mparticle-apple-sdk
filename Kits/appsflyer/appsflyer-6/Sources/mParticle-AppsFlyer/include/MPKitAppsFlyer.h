#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
@import mParticle_Apple_SDK;
#elif __has_feature(objc_modules)
@import mParticle_Apple_SDK_ObjC;
#else
#import <mParticle_Apple_SDK/mParticle.h>
#endif

extern NSString * _Nonnull const MPKitAppsFlyerConversionResultKey;
extern NSString * _Nonnull const MPKitAppsFlyerAppOpenResultKey;
extern NSString * _Nonnull const MPKitAppsFlyerErrorKey;
extern NSString * _Nonnull const MPKitAppsFlyerErrorDomain;

@interface MPKitAppsFlyer : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;
@property (nonatomic, strong, nullable) id providerKitInstance;

+ (void)setDelegate:(id _Nonnull)delegate;

/**
 Starts AppsFlyer on the instance this kit already configured, for apps using the
 `manualStart` connection setting to delay attribution (for example, until a consent
 banner is accepted). Prefer this over calling `[[AppsFlyerLib shared] start]` directly:
 an app that also links the AppsFlyer SDK on its own can otherwise resolve a second,
 unconfigured instance and fail with "No dev key".

 @return `YES` if AppsFlyer was told to start; `NO` if mParticle has not yet configured
 the AppsFlyer kit (for example, if called before `start` on the mParticle SDK itself).
 */
+ (BOOL)startAppsFlyer NS_SWIFT_NAME(startAppsFlyer());

+ (NSNumber * _Nonnull)computeProductQuantity:(nullable MPCommerceEvent *)event;
+ (NSString * _Nullable)generateProductIdList:(nullable MPCommerceEvent *)event;

- (nullable NSNumber *)resolvedConsentForMappingKey:(NSString * _Nonnull)mappingKey
                                         defaultKey:(NSString * _Nonnull)defaultKey
                                       gdprConsents:(NSDictionary<NSString *, MPGDPRConsent *> * _Nonnull)gdprConsents
                                            mapping:(NSDictionary<NSString *, NSString *> * _Nullable)mapping;

- (nullable NSArray<NSDictionary *>*)mappingForKey:(NSString* _Nonnull)key;

- (nonnull NSDictionary*)convertToKeyValuePairs: (NSArray<NSDictionary *> * _Nonnull)mappings;

- (nonnull MPKitExecStatus *)routeCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent;
@end

extern NSString * _Nonnull const MPKitAppsFlyerAttributionResultKey __deprecated_msg("Use MPKitAppsFlyerConversionResultKey instead.");
