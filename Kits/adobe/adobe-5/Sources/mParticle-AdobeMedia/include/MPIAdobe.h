#import <Foundation/Foundation.h>

@interface MPIAdobe : NSObject

- (void)sendRequestWithMarketingCloudId:(NSString *)marketingCloudId advertiserId:(NSString *)advertiserId pushToken:(NSString *)pushToken organizationId:(NSString *)organizationId userIdentities:(NSDictionary<NSNumber *, NSString *> *)userIdentities audienceManagerServer:(NSString *)audienceManagerServer completion:(void (^)(NSString *marketingCloudId, NSString *locationHint, NSString *blob, NSError *error))completion;

- (NSString *)marketingCloudIdFromUserDefaults;

@end

extern NSString *const MPIAdobeErrorKey;

typedef NS_ENUM(NSInteger, MPIAdobeErrorCode) {
    MPIAdobeErrorCodeClientFailedRequestError,
    MPIAdobeErrorCodeClientSerializationError,
    MPIAdobeErrorCodeServerError
};

@interface MPIAdobeError : NSObject

@property (nonatomic, assign) MPIAdobeErrorCode code;
@property (nonatomic) NSString *message;
@property (nonatomic) NSError *innerError;

@end
