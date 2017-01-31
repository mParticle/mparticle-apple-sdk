//
//  MPEventAbstract.h
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

#import <Foundation/Foundation.h>
#import "MPEnums.h"

typedef NS_ENUM(NSUInteger, MPEventKind) {
    MPEventKindAppEvent = 0,
    MPEventKindCommerceEvent
};

@interface MPEventAbstract : NSObject <NSCopying> {
@protected
    NSNumber *_duration;
    NSDate *_endTime;
    NSDate *_startTime;
    NSDate *_timestamp;
    NSString *_typeName;
    MPEventKind _kind;
    MPMessageType _messageType;
    MPEventType _type;
}

/**
 The duration, in milliseconds, of an event. This property can be set by a developer, or
 it can be calculated automatically by the mParticle SDK using the beginTiming/endTiming
 methods.
 @see beginTiming
 */
@property (nonatomic, strong, nullable) NSNumber *duration;

/**
 If using the beginTiming/endTiming methods, this property contains the time the
 event ended. Otherwise it is nil.
 */
@property (nonatomic, strong, nullable, readonly) NSDate *endTime;

/**
 Kind of the event (app event or commerce event). Internal use only. Please do not use this property
 under any circumstance.
 */
@property (nonatomic, unsafe_unretained, readonly) MPEventKind kind;

/**
 Type of the event. Internal use only. Please do not use this property
 under any circumstance.
 */
@property (nonatomic, unsafe_unretained) MPMessageType messageType;

/**
 If using the beginTiming/endTiming methods, this property contains the time the
 event started. Otherwise it is nil.
 */
@property (nonatomic, strong, nullable, readonly) NSDate *startTime;

/**
 Timestamp when the event is logged. This is for internal use only. Please do not use this property
 under any circumstance.
 */
@property (nonatomic, strong, nullable) NSDate *timestamp;

/**
 An enum value that indicates the type of event to be logged. If logging a screen event, this
 property will be overridden to MPEventTypeNavigation. In all other cases the SDK will honor the type
 assigned to this property.
 @see MPEventType
 */
@property (nonatomic, unsafe_unretained) MPEventType type;

/**
 String representation of the event type to be logged.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *typeName;


- (void)beginTiming;

/**
 Returns the dictionary representation of an app event or commerce event. This information
 is used to generate part of the batch to be uploaded to the server.
 */
- (nullable NSDictionary<NSString *, id> *)dictionaryRepresentation;

- (void)endTiming;

@end
