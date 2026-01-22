@import Foundation;

#import "AThing.h"
@import BObjC;   // <-- import bridge module

@implementation AThing

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialization
    }
    return self;
}

- (void)demo {
    BPricingEngineObjC *engine = [[BPricingEngineObjC alloc] init];
    NSNumber *price = [engine priceForUserId:@"denis"];
    NSString *formatted = [engine formattedPriceForUserId:@"denis"];
    
    NSLog(@"Price = %@", price);
    NSLog(@"Formatted: %@", formatted);
}

- (SomeType*)getType {
    return [[SomeType alloc] init];
}

@end

