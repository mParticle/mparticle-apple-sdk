#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MPNetworkMeasurementMode) {
    MPNetworkMeasurementModeExclude = 0,
    MPNetworkMeasurementModePreserveQuery,
    MPNetworkMeasurementModeAbridged
};

@interface MPNetworkPerformance : NSObject <NSCopying>

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong, readonly) NSString *POSTBody;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) NSTimeInterval endTime;
@property (nonatomic) NSTimeInterval elapsedTime;
@property (nonatomic) NSUInteger bytesIn;
@property (nonatomic) NSUInteger bytesOut;
@property (nonatomic) NSInteger responseCode;
@property (nonatomic, readonly) MPNetworkMeasurementMode networkMeasurementMode;

- (instancetype)initWithURLRequest:(NSURLRequest *)request networkMeasurementMode:(MPNetworkMeasurementMode)networkMeasurementMode;
- (void)setStartDate:(NSDate *)date;
- (void)setEndDate:(NSDate *)date;
- (NSDictionary *)dictionaryRepresentation;

@end
