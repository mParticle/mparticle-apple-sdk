#import <Foundation/Foundation.h>
@import mParticle_Apple_SDK_ObjC;

@interface MPKitOneTrust : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) NSDictionary *purposeConsentMapping;
@property (nonatomic, strong, nullable) NSDictionary *venderGeneralConsentMapping;
@property (nonatomic, strong, nullable) NSDictionary *venderIABConsentMapping;
@property (nonatomic, strong, nullable) NSDictionary *venderGoogleConsentMapping;


@end
