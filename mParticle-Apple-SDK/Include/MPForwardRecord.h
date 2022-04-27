#import "MPEnums.h"

@class MPKitExecStatus;

@interface MPForwardRecord : NSObject

@property (nonatomic) uint64_t forwardRecordId;
@property (nonatomic, strong, nonnull) NSMutableDictionary *dataDictionary;
@property (nonatomic, strong, nonnull) NSNumber *mpid;
@property (nonatomic, strong, nonnull) NSNumber *timestamp;

- (nonnull instancetype)initWithId:(int64_t)forwardRecordId dataDictionary:(nonnull NSDictionary *)dataDictionary mpid:(nonnull NSNumber *)mpid;

@end
