//
//  MPNetworkPerformanceMeasurementProtocol.h
//
//  Copyright 2017 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#ifndef mParticle_Apple_SDK_MPNetworkPerformanceMeasurementProtocol_h
#define mParticle_Apple_SDK_MPNetworkPerformanceMeasurementProtocol_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MPNetworkMeasurementMode) {
    MPNetworkMeasurementModeExclude = 0,
    MPNetworkMeasurementModePreserveQuery,
    MPNetworkMeasurementModeAbridged
};

extern NSString * _Nonnull const kMPNetworkPerformanceMeasurementNotification;
extern NSString * _Nonnull const kMPNetworkPerformanceKey;
extern NSString * _Nonnull const kMPMessageTypeNetworkPerformance;


@protocol MPNetworkPerformanceMeasurementProtocol <NSObject>

@property (nonatomic, strong, nonnull) NSString *httpMethod;
@property (nonatomic, strong, readonly, nullable) NSString *POSTBody;
@property (nonatomic, strong, nullable) NSString *urlString;
@property (nonatomic, unsafe_unretained) NSTimeInterval elapsedTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval endTime;
@property (nonatomic, unsafe_unretained) NSTimeInterval startTime;
@property (nonatomic, unsafe_unretained) NSUInteger bytesIn;
@property (nonatomic, unsafe_unretained) NSUInteger bytesOut;
@property (nonatomic, unsafe_unretained) NSInteger responseCode;
@property (nonatomic, unsafe_unretained, readonly) MPNetworkMeasurementMode networkMeasurementMode;

- (nonnull instancetype)initWithURLRequest:(nonnull NSURLRequest *)request networkMeasurementMode:(MPNetworkMeasurementMode)networkMeasurementMode;
- (void)setStartDate:(nonnull NSDate *)date;
- (void)setEndDate:(nonnull NSDate *)date;
- (nonnull NSDictionary *)dictionaryRepresentation;

@end

#endif
