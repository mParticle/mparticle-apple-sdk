#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPConsentKitFilterItem;

@interface MPConsentKitFilter : NSObject

@property (nonatomic) BOOL shouldIncludeOnMatch;
@property (nonatomic, strong) NSArray<MPConsentKitFilterItem *> *filterItems;

@end

NS_ASSUME_NONNULL_END
