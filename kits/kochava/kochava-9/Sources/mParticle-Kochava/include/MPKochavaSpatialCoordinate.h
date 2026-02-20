#import <Foundation/Foundation.h>

@interface MPKochavaSpatialCoordinate : NSObject

@property (nonatomic, readonly) float x;
@property (nonatomic, readonly) float y;
@property (nonatomic, readonly) float z;

- (instancetype)initWithDictionary:(NSDictionary *)spatialDictionary;

@end
