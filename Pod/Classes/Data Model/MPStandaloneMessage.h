//
//  MPStandaloneMessage.h
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

#import "MPDataModelAbstract.h"
#import "MPConstants.h"
#import "MPDataModelProtocol.h"

@interface MPStandaloneMessage : MPDataModelAbstract <NSCopying, NSCoding, MPDataModelProtocol>

@property (nonatomic, strong) NSString *messageType;
@property (nonatomic, strong) NSData *messageData;
@property (nonatomic, unsafe_unretained) NSTimeInterval timestamp;
@property (nonatomic, unsafe_unretained) int64_t messageId;
@property (nonatomic, unsafe_unretained) MPUploadStatus uploadStatus;

// Designited initializer for fetching data from the database
- (instancetype)initWithMessageId:(int64_t)messageId
                             UUID:(NSString *)uuid
                      messageType:(NSString *)messageType
                      messageData:(NSData *)messageData
                        timestamp:(NSTimeInterval)timestamp
                     uploadStatus:(MPUploadStatus)uploadStatus __attribute__((objc_designated_initializer));

// Designated initializers for creating instances (not fetched from the database)
- (instancetype)initWithMessageType:(NSString *)messageType messageInfo:(NSDictionary *)messageInfo uploadStatus:(MPUploadStatus)uploadStatus UUID:(NSString *)uuid timestamp:(NSTimeInterval)timestamp;

@end
