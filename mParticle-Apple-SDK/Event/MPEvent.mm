//
//  MPEvent.m
//
//  Copyright 2016 mParticle, Inc.
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

#import "MPEvent.h"
#import "EventTypeName.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPSession.h"
#import "MPStateMachine.h"

NSString *const kMPEventCategoryKey = @"$Category";
NSString *const kMPAttrsEventLengthKey = @"EventLength";
NSString *const kMPEventCustomFlags = @"flags";

@interface MPEvent()

@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString *, __kindof NSArray<NSString *> *> *customFlagsDictionary;

@end


@implementation MPEvent

- (instancetype)init {
    MPILogError(@"%@ should NOT be initialized using the standard initializer.", [self class]);
    return [self initWithName:@"<<Event With No Name>>" type:MPEventTypeOther];
}

- (instancetype)initWithName:(NSString *)name type:(MPEventType)type {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if (!name || name.length == 0) {
        MPILogError(@"'name' is required for MPEvent")
        return nil;
    }
    
    if (name.length > LIMIT_NAME) {
        MPILogError(@"The event name is too long.");
        return nil;
    }
    
    _name = name;
    _duration = @0;
    self.type = type;

    return self;
}

- (BOOL)isEqual:(MPEvent *)object {
    BOOL isEqual = _type == object.type &&
                   [_name isEqualToString:object.name] &&
                   [_info isEqualToDictionary:object.info] &&
                   [_duration isEqualToNumber:object.duration];
    
    if (isEqual) {
        if (_category && object.category) {
            isEqual = [_category isEqualToString:object.category];
        } else if (_category || object.category) {
            isEqual = NO;
        }
    }
    
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPEvent *copyObject = [super copyWithZone:zone];
    
    if (copyObject) {
        copyObject->_category = [_category copy];
        copyObject->_customFlagsDictionary = [_customFlagsDictionary mutableCopy];
        copyObject->_info = [_info copy];
        copyObject->_name = [_name copy];
    }
    
    return copyObject;
}

#pragma mark Private accessors
- (NSMutableDictionary *)customFlagsDictionary {
    if (!_customFlagsDictionary) {
        _customFlagsDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    
    return _customFlagsDictionary;
}

#pragma mark Public accessors
- (void)setCategory:(NSString *)category {
    if (category.length <= LIMIT_NAME) {
        _category = category;
    } else {
        MPILogError(@"The category length is too long. Discarding category.");
        _category = nil;
    }
}

- (NSDictionary *)customFlags {
    return (NSDictionary *)_customFlagsDictionary;
}

- (void)setInfo:(NSDictionary *)info {
    if (_info && info && [_info isEqualToDictionary:info]) {
        return;
    }
    
    NSUInteger numberOfEntries = info.count;
    
    NSAssert(numberOfEntries <= LIMIT_ATTR_COUNT, @"Event info has more than 100 key/value pairs.");

    if (numberOfEntries > LIMIT_ATTR_COUNT) {
        MPILogError(@"Number of attributes exceeds the maximum number of attributes allowed per event. Discarding attributes.");
        return;
    }
    
    if (numberOfEntries > 0) {
        __block BOOL respectsConstraints = YES;
        
        if ([info isKindOfClass:[NSDictionary class]]) {
            [info enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
                if ([value isKindOfClass:[NSString class]] && ((NSString *)value).length > LIMIT_ATTR_LENGTH) {
                    respectsConstraints = NO;
                    *stop = YES;
                }
                
                if (key.length > LIMIT_NAME) {
                    respectsConstraints = NO;
                    *stop = YES;
                }
            }];
            
            if (respectsConstraints) {
                _info = info;
            }
        } else if ([info isKindOfClass:[MPProduct class]]) {
            _info = [(MPProduct *)info dictionaryRepresentation];
        }
    } else {
        _info = nil;
    }
}

- (void)setName:(NSString *)name {
    if (name.length == 0) {
        MPILogError(@"'name' cannot be nil or empty.")
        return;
    }
    
    if (name.length > LIMIT_NAME) {
        MPILogError(@"The event name is too long.");
        return;
    }
    
    if (![_name isEqualToString:name]) {
        _name = name;
    }
}

- (void)setType:(MPEventType)type {
    [super setType:type];
    
    if (type < MPEventTypeNavigation || type > MPEventTypeOther) {
        MPILogWarning(@"An invalid event type was provided. Will default to 'MPEventTypeOther'");
        _type = MPEventTypeOther;
    } else {
        _type = type;
    }
}

#pragma mark Public methods
- (void)addCustomFlag:(NSString *)customFlag withKey:(NSString *)key {
    if (MPIsNull(customFlag)) {
        MPILogError(@"'customFlag' cannot be nil or null.");
        return;
    }
    
    if (MPIsNull(key)) {
        MPILogError(@"'key' cannot be nil or null.");
        return;
    }
    
    [self addCustomFlags:@[customFlag] withKey:key];
}

- (void)addCustomFlags:(nonnull NSArray<NSString *> *)customFlags withKey:(nonnull NSString *)key {
    if (MPIsNull(customFlags)) {
        MPILogError(@"'customFlags' cannot be nil or null.");
        return;
    }
    
    if (MPIsNull(key)) {
        MPILogError(@"'key' cannot be nil or null.");
        return;
    }
    
    BOOL validDataType = [customFlags isKindOfClass:[NSArray class]];
    NSAssert(validDataType, @"'customFlags' must be of type NSArray or an instance of a class inheriting from NSArray.");
    if (!validDataType) {
        MPILogError(@"'customFlags' must be of type NSArray or an instance of a class inheriting from NSArray.");
        return;
    }
    
    for (id item in customFlags) {
        validDataType = [item isKindOfClass:[NSString class]];
        NSAssert(validDataType, @"'customFlags' array items must be of type NSString or an instance of a class inheriting from NSString.");
        if (!validDataType) {
            MPILogError(@"'customFlags' array items must be of type NSString or an instance of a class inheriting from NSString.");
            return;
        }
    }
    
    NSMutableArray<NSString *> *flags = self.customFlagsDictionary[key];
    if (!flags) {
        flags = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    [flags addObjectsFromArray:customFlags];
    self.customFlagsDictionary[key] = flags;
}

- (nullable NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary<NSString *, id> *eventDictionary = [[NSMutableDictionary alloc] initWithCapacity:8];
    
    NSDictionary *info = self.info;
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    if (self.startTime) {
        eventDictionary[kMPEventStartTimestamp] = MPMilliseconds([self.startTime timeIntervalSince1970]);
    } else {
        eventDictionary[kMPEventStartTimestamp] = MPCurrentEpochInMilliseconds;
    }
    
    if (info) {
        [attributes addEntriesFromDictionary:info];
    }
    
    if (self.messageType != MPMessageTypeBreadcrumb) {
        if (self.duration) {
            eventDictionary[kMPEventLength] = self.duration;
            
            if (!info || info[kMPAttrsEventLengthKey] == nil) { // Does not override "EventLength" if it already exists
                attributes[kMPAttrsEventLengthKey] = self.duration;
            }
        } else {
            eventDictionary[kMPEventLength] = @0;
        }
    }
    
    if (attributes.count > 0) {
        eventDictionary[kMPAttributesKey] = attributes;
    }
    
    // Return here if message type is breadcrumb
    if (self.messageType == MPMessageTypeBreadcrumb) {
        eventDictionary[kMPLeaveBreadcrumbsKey] = self.name;
        return eventDictionary;
    }
    
    eventDictionary[kMPEventNameKey] = self.name;
    
    if (self.customFlags) {
        eventDictionary[kMPEventCustomFlags] = self.customFlags;
    }
    
    // Return here if message type is screen view
    if (_messageType == MPMessageTypeScreenView) {
        return eventDictionary;
    }
    
    eventDictionary[kMPEventCounterKey] = @([MPStateMachine sharedInstance].currentSession.eventCounter);
    eventDictionary[kMPEventTypeKey] = self.typeName;
    
    NSString *category = self.category;
    if (category) {
        if (category.length <= LIMIT_NAME) {
            attributes[kMPEventCategoryKey] = category;
        } else {
            MPILogError(@"The event category is too long. Discarding category.");
        }
    }
    
    return eventDictionary;
}

@end
