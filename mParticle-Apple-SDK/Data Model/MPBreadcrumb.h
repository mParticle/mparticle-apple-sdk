#import "MPDataModelAbstract.h"
#import "MPDataModelProtocol.h"

@interface MPBreadcrumb : MPDataModelAbstract <NSCopying, NSSecureCoding, MPDataModelProtocol>

@property (nonatomic, strong, nonnull) NSString *sessionUUID;
@property (nonatomic, strong, nonnull) NSData *breadcrumbData;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) int64_t breadcrumbId;

- (nonnull instancetype)initWithSessionUUID:(nonnull NSString *)sessionUUID
                               breadcrumbId:(int64_t)breadcrumbId
                                       UUID:(nonnull NSString *)uuid
                             breadcrumbData:(nonnull NSData *)breadcrumbData
                                  timestamp:(NSTimeInterval)timestamp;

@end
