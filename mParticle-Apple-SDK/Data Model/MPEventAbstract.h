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
    NSDate *_timestamp;
    MPEventKind _kind;
    MPEventType _type;
}

@property (nonatomic, strong, nullable) NSDate *timestamp;
@property (nonatomic, unsafe_unretained, readonly) MPEventKind kind;

/**
 An enum value that indicates the type of event to be logged. If logging a screen event, this
 property will be overridden to MPEventTypeNavigation. In all other cases the SDK will honor the type
 assigned to this property.
 @see MPEventType
 */
@property (nonatomic, unsafe_unretained) MPEventType type;

@end
