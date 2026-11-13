#import "MPKochavaSpatialCoordinate.h"

NSString *const spatialX = @"SpatialX";
NSString *const spatialY = @"SpatialY";
NSString *const spatialZ = @"SpatialZ";

@implementation MPKochavaSpatialCoordinate

- (instancetype)initWithDictionary:(NSDictionary *)spatialDictionary {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSArray *keys = [spatialDictionary allKeys];
    BOOL containsSpatialCoordinate = [keys containsObject:spatialX] || [keys containsObject:spatialY] || [keys containsObject:spatialZ];
    if (!containsSpatialCoordinate) {
        return nil;
    }
    
    _x = [spatialDictionary[spatialX] floatValue];
    _y = [spatialDictionary[spatialY] floatValue];
    _z = [spatialDictionary[spatialZ] floatValue];
    
    return self;
}

@end
