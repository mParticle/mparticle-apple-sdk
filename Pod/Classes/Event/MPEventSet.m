//
//  MPEventSet.m
//
//  Copyright 2015 mParticle, Inc.
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

#import "MPEventSet.h"
#import "MPEvent.h"

@interface MPEventSet() {
    NSMutableSet *eventSet;
}

@end


@implementation MPEventSet

- (instancetype)init {
    return [self initWithCapacity:1];
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if (capacity < 1) {
        capacity = 1;
    }
    eventSet = [[NSMutableSet alloc] initWithCapacity:capacity];
    
    return self;
}

#pragma mark Public accessors
- (NSUInteger)count {
    return eventSet.count;
}

#pragma mark Public methods
- (void)addEvent:(MPEvent *)event {
    if (!event) {
        return;
    }
    
    [eventSet addObject:event];
}

- (BOOL)containsEvent:(MPEvent *)event {
    BOOL containsEvent = [eventSet containsObject:event];
    return containsEvent;
}

- (BOOL)containsEventWithName:(NSString *)eventName {
    BOOL containsEvent = [self eventWithName:eventName] != nil;
    return containsEvent;
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    if (!eventName || eventSet.count == 0) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", eventName];
    MPEvent *event = [[eventSet filteredSetUsingPredicate:predicate] anyObject];
    
    return event;
}

- (void)removeEvent:(MPEvent *)event {
    if (!event || eventSet.count == 0) {
        return;
    }
    
    if ([eventSet containsObject:event]) {
        [eventSet removeObject:event];
    }
}

- (void)removeEventWithName:(NSString *)eventName {
    MPEvent *event = [self eventWithName:eventName];
    [self removeEvent:event];
}

@end
