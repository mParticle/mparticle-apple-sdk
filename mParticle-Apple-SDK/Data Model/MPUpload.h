#import "MPDataModelAbstract.h"
#import "MPDataModelProtocol.h"

@class MPSession;

@interface MPUpload : MPDataModelAbstract <NSCopying, MPDataModelProtocol>

@property (nonatomic, strong, nonnull) NSData *uploadData;
@property (nonatomic, unsafe_unretained) NSTimeInterval timestamp;
@property (nonatomic, unsafe_unretained) int64_t sessionId;
@property (nonatomic, unsafe_unretained) int64_t uploadId;

- (nonnull instancetype)initWithSession:(nonnull MPSession *)session uploadDictionary:(nonnull NSDictionary *)uploadDictionary;
- (nonnull instancetype)initWithSessionId:(int64_t)sessionId uploadId:(int64_t)uploadId UUID:(nonnull NSString *)uuid uploadData:(nonnull NSData *)uploadData timestamp:(NSTimeInterval)timestamp;

@end
