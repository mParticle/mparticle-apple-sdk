//
//  MPEventAbstract.mm
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

#import "MPEventAbstract.h"
#import "EventTypeName.h"
#import "MPIConstants.h"
#import "NSString+MPUtils.h"

using namespace mParticle;

@implementation MPEventAbstract

- (instancetype)init {
    self = [super init];
    if (self) {
        _kind = MPEventKindAppEvent;
        _messageType = MPMessageTypeEvent;
    }
    
    return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPEventAbstract *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject.duration = [_duration copy];
        copyObject->_endTime = [_endTime copy];
        copyObject->_kind = _kind;
        copyObject->_messageType = _messageType;
        copyObject->_startTime = [_startTime copy];
        copyObject->_timestamp = [_timestamp copy];
        copyObject->_type = _type;
    }
    
    return copyObject;
}

#pragma mark Accessors
- (NSNumber *)duration {
    return _duration;
}

- (void)setDuration:(NSNumber *)duration {
    _duration = duration;
}

- (NSDate *)endTime {
    return _endTime;
}

- (MPEventKind)kind {
    return _kind;
}

- (MPMessageType)messageType {
    return _messageType;
}

- (void)setMessageType:(MPMessageType)messageType {
    _messageType = messageType;
}

- (NSDate *)startTime {
    return _startTime;
}

- (NSDate *)timestamp {
    return _timestamp;
}

- (void)setTimestamp:(NSDate *)timestamp {
    _timestamp = timestamp;
}

- (MPEventType)type {
    return _type;
}

- (void)setType:(MPEventType)type {
    if (_type == type) {
        return;
    }
    
    _type = type;
    _typeName = nil;
}

- (NSString *)typeName {
    if (!_typeName) {
        EventType eventType = static_cast<EventType>(_type);
        _typeName = [NSString stringWithCPPString:EventTypeName::nameForEventType(eventType)];
    }
    
    return _typeName;
}

#pragma mark Public methods
- (void)beginTiming {
    _startTime = [NSDate date];
    _duration = nil;
    
    if (_endTime) {
        _endTime = nil;
    }
}

- (nullable NSDictionary<NSString *, id> *)dictionaryRepresentation {
    return nil;
}

- (void)endTiming {
    if (_startTime) {
        _endTime = [NSDate date];
        
        NSTimeInterval secondsElapsed = [_endTime timeIntervalSince1970] - [_startTime timeIntervalSince1970];
        _duration = MPMilliseconds(secondsElapsed);
    } else {
        _duration = nil;
        _endTime = nil;
    }
}

@end
