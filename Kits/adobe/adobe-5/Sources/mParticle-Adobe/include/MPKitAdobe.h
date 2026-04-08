#import <Foundation/Foundation.h>
@import mParticle_Apple_SDK_ObjC;

#pragma mark - MPIAdobeApi
@interface MPIAdobeApi : NSObject

/// Returns the Adobe Marketing Cloud ID if present
@property (readwrite, nullable) NSString *marketingCloudID;

@end

#pragma mark - MPKitAdobe
@interface MPKitAdobe : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

+ (void)overrideMarketingCloudId:(NSString * _Nullable)mid;
+ (void)willOverrideMarketingCloudId:(BOOL)willOverrideMid;

@end
