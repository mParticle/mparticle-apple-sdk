#import "MPLocation.h"

@implementation MPLocation

- (nonnull instancetype)initWithLatitude:(double)latitude
                               longitude:(double)longitude
                                altitude:(double)altitude
                      horizontalAccuracy:(double)horizontalAccuracy
                        verticalAccuracy:(double)verticalAccuracy
                                  course:(double)course
                                   speed:(double)speed
                               timestamp:(nonnull NSDate *)timestamp {
    self = [super init];
    if (self) {
        _latitude = latitude;
        _longitude = longitude;
        _altitude = altitude;
        _horizontalAccuracy = horizontalAccuracy;
        _verticalAccuracy = verticalAccuracy;
        _course = course;
        _speed = speed;
        _timestamp = [timestamp copy];
    }
    return self;
}

@end
