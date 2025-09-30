#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPConsentKitFilterItem : NSObject

@property (nonatomic) BOOL consented;
@property (nonatomic) int javascriptHash;

@end

@interface MPConsentKitFilter : NSObject

@property (nonatomic) BOOL shouldIncludeOnMatch;
@property (nonatomic, strong) NSArray<MPConsentKitFilterItem *> *filterItems;

@end

NS_ASSUME_NONNULL_END
