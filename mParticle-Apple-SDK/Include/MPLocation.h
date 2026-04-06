#ifndef mParticle_Apple_SDK_MPLocation_h
#define mParticle_Apple_SDK_MPLocation_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Accuracy for location tracking, in meters. Uses the same numeric values as `CLLocationAccuracy`
 * from Core Location (for example `kCLLocationAccuracyBest` when Core Location is available).
 */
typedef double MPLocationAccuracy;

/**
 * Distance in meters. Same semantics as `CLLocationDistance` from Core Location.
 */
typedef double MPLocationDistance;

/**
 * Location snapshot passed to kits via `MPKitProtocol`. Does not depend on Core Location.
 * Kits that need `CLLocation` or `CLLocationCoordinate2D` should import CoreLocation and convert.
 */
@interface MPLocation : NSObject

@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;
@property (nonatomic, readonly) double altitude;
@property (nonatomic, readonly) double horizontalAccuracy;
@property (nonatomic, readonly) double verticalAccuracy;
@property (nonatomic, readonly) double course;
@property (nonatomic, readonly) double speed;
@property (nonatomic, readonly, copy) NSDate *timestamp;

- (instancetype)init NS_UNAVAILABLE;

- (nonnull instancetype)initWithLatitude:(double)latitude
                               longitude:(double)longitude
                                altitude:(double)altitude
                      horizontalAccuracy:(double)horizontalAccuracy
                        verticalAccuracy:(double)verticalAccuracy
                                  course:(double)course
                                   speed:(double)speed
                               timestamp:(nonnull NSDate *)timestamp NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

#endif
