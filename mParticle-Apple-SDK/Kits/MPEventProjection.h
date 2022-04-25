#import "MPBaseProjection.h"
#import "MPEnums.h"

@class MPAttributeProjection;

typedef NS_ENUM(NSUInteger, MPProjectionBehaviorSelector) {
    MPProjectionBehaviorSelectorForEach = 0,
    MPProjectionBehaviorSelectorLast
};

@interface MPProjectionMatch : NSObject <NSCopying, NSSecureCoding>
@property (nonatomic, strong, nullable) NSString *attributeKey;
@property (nonatomic, strong, nullable) NSArray<NSString *> *attributeValues;
@end

@interface MPEventProjection : MPBaseProjection <NSCopying, NSSecureCoding>

@property (nonatomic, strong, nullable) NSArray<MPProjectionMatch *> *projectionMatches;
@property (nonatomic, strong, nullable) NSArray<MPAttributeProjection *> *attributeProjections;
@property (nonatomic) MPProjectionBehaviorSelector behaviorSelector;
@property (nonatomic) MPEventType eventType;
@property (nonatomic) MPMessageType messageType;
@property (nonatomic) MPMessageType outboundMessageType;
@property (nonatomic) NSUInteger maxCustomParameters;
@property (nonatomic) BOOL appendAsIs;
@property (nonatomic) BOOL isDefault;

- (nonnull instancetype)initWithConfiguration:(nullable NSDictionary *)configuration;

@end
