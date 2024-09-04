#import "MPDataModelAbstract.h"
#import "MPDataModelProtocol.h"
#import "MPEnums.h"

@class MPSession;
@class MPNetworkOptions;

// Upload credentials and options
@interface MPUploadSettings : NSObject <NSCopying, NSSecureCoding>
@property (nonatomic, strong, nonnull) NSString *apiKey;
@property (nonatomic, strong, nonnull) NSString *secret;
@property (nonatomic, strong, nullable) NSString *eventsHost;
@property (nonatomic, strong, nullable) NSString *eventsTrackingHost;
@property (nonatomic) BOOL overridesEventsSubdirectory;
@property (nonatomic, strong, nullable) NSString *aliasHost;
@property (nonatomic, strong, nullable) NSString *aliasTrackingHost;
@property (nonatomic) BOOL overridesAliasSubdirectory;
@property (nonatomic) BOOL eventsOnly;

+ (nonnull MPUploadSettings *)currentUploadSettings;

- (nonnull instancetype)initWithApiKey:(nonnull NSString *)apiKey secret:(nonnull NSString *)secret eventsHost:(nullable NSString *)eventsHost eventsTrackingHost:(nullable NSString *)eventsTrackingHost overridesEventsSubdirectory:(BOOL)overridesEventsSubdirectory aliasHost:(nullable NSString *)aliasHost aliasTrackingHost:(nullable NSString *)aliasTrackingHost overridesAliasSubdirectory:(BOOL)overridesAliasSubdirectory eventsOnly:(BOOL)eventsOnly;

- (nonnull instancetype)initWithApiKey:(nonnull NSString *)apiKey secret:(nonnull NSString *)secret networkOptions:(nullable MPNetworkOptions *)networkOptions;

@end

@interface MPUpload : MPDataModelAbstract <NSCopying, MPDataModelProtocol>

@property (nonatomic, strong, nonnull) NSData *uploadData;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic, strong, nullable) NSNumber *sessionId;
@property (nonatomic) int64_t uploadId;
@property (nonatomic) MPUploadType uploadType;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
@property BOOL containsOptOutMessage;

@property (nonatomic, strong, nonnull) MPUploadSettings *uploadSettings;


- (nonnull instancetype)initWithSessionId:(nullable NSNumber *)sessionId
                         uploadDictionary:(nonnull NSDictionary *)uploadDictionary
                               dataPlanId:(nullable NSString *)dataPlanId
                          dataPlanVersion:(nullable NSNumber *)dataPlanVersion
                           uploadSettings:(nonnull MPUploadSettings *)uploadSettings;

- (nonnull instancetype)initWithSessionId:(nullable NSNumber *)sessionId
                                 uploadId:(int64_t)uploadId
                                     UUID:(nonnull NSString *)uuid
                               uploadData:(nonnull NSData *)uploadData
                                timestamp:(NSTimeInterval)timestamp
                               uploadType:(MPUploadType)uploadType
                               dataPlanId:(nullable NSString *)dataPlanId
                          dataPlanVersion:(nullable NSNumber *)dataPlanVersion
                           uploadSettings:(nonnull MPUploadSettings *)uploadSettings;

@end
