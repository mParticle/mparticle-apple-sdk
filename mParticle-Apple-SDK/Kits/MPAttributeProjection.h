#import "MPBaseProjection.h"

@interface MPAttributeProjection : MPBaseProjection <NSCopying, NSSecureCoding>

@property (nonatomic) MPDataType dataType;
@property (nonatomic) BOOL required;

- (nonnull instancetype)initWithConfiguration:(nullable NSDictionary *)configuration projectionType:(MPProjectionType)projectionType attributeIndex:(NSUInteger)attributeIndex;

@end
