#import "MPDataModelAbstract.h"
#import "MPDataModelProtocol.h"
#import "MPEnums.h"

@class MPSession;

@interface MPUpload : MPDataModelAbstract <NSCopying, MPDataModelProtocol>

@property (nonatomic, strong, nonnull) NSData *uploadData;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic, strong, nullable) NSNumber *sessionId;
@property (nonatomic) int64_t uploadId;
@property (nonatomic) MPUploadType uploadType;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
@property BOOL containsOptOutMessage;

- (nonnull instancetype)initWithSessionId:(nullable NSNumber *)sessionId
                         uploadDictionary:(nonnull NSDictionary *)uploadDictionary
                               dataPlanId:(nullable NSString *)dataPlanId
                          dataPlanVersion:(nullable NSNumber *)dataPlanVersion;
- (nonnull instancetype)initWithSessionId:(nullable NSNumber *)sessionId
                                 uploadId:(int64_t)uploadId
                                     UUID:(nonnull NSString *)uuid
                               uploadData:(nonnull NSData *)uploadData
                                timestamp:(NSTimeInterval)timestamp
                               uploadType:(MPUploadType)uploadType
                               dataPlanId:(nullable NSString *)dataPlanId
                          dataPlanVersion:(nullable NSNumber *)dataPlanVersion;

@end
