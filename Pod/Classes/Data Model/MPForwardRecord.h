//
//  MPForwardRecord.h
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

#import "MPEnums.h"
#import "MPConstants.h"

@class MPKitFilter;
@class MPKitExecStatus;

@interface MPForwardRecord : NSObject

@property (nonatomic, unsafe_unretained) uint64_t forwardRecordId;
@property (nonatomic, strong) NSMutableDictionary *dataDictionary;

- (instancetype)initWithId:(int64_t)forwardRecordId data:(NSData *)data;
- (instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(MPKitExecStatus *)execStatus;
- (instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(MPKitExecStatus *)execStatus stateFlag:(BOOL)stateFlag;
- (instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(MPKitExecStatus *)execStatus kitFilter:(MPKitFilter *)kitFilter originalEvent:(id)originalEvent;
- (NSData *)dataRepresentation;

@end
