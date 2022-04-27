#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MPSegmentMembershipAction) {
    MPSegmentMembershipActionAdd = 1,
    MPSegmentMembershipActionDrop
};

@interface MPSegmentMembership : NSObject <NSCopying>

@property (nonatomic) int64_t segmentId;
@property (nonatomic) int64_t segmentMembershipId;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) MPSegmentMembershipAction action;

- (instancetype)initWithSegmentId:(int64_t)segmentId membershipDictionary:(NSDictionary *)membershipDictionary;
- (instancetype)initWithSegmentId:(int64_t)segmentId segmentMembershipId:(int64_t)segmentMembershipId timestamp:(NSTimeInterval)timestamp membershipAction:(MPSegmentMembershipAction)action __attribute__((objc_designated_initializer));

@end
