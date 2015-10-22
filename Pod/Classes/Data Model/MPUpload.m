//
//  MPUpload.m
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

#import "MPUpload.h"
#import "MPSession.h"
#import "MPConstants.h"

@interface MPUpload()
@property (nonatomic, strong) NSDictionary *uploadContent;
@end

@implementation MPUpload

- (instancetype)init {
    return [self initWithSessionId:0 uploadId:0 UUID:[[NSUUID UUID] UUIDString] uploadData:nil timestamp:[[NSDate date] timeIntervalSince1970]];
}

- (instancetype)initWithSession:(MPSession *)session uploadDictionary:(NSDictionary *)uploadDictionary {
    NSData *uploadData = [NSJSONSerialization dataWithJSONObject:uploadDictionary options:0 error:nil];
    
    return [self initWithSessionId:session.sessionId
                          uploadId:0
                              UUID:uploadDictionary[kMPMessageIdKey]
                        uploadData:uploadData
                         timestamp:[uploadDictionary[kMPTimestampKey] doubleValue]];
}

- (instancetype)initWithSessionId:(int64_t)sessionId uploadId:(int64_t)uploadId UUID:(NSString *)uuid uploadData:(NSData *)uploadData timestamp:(NSTimeInterval)timestamp {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _sessionId = sessionId;
    _uploadId = uploadId;
    _uuid = uuid;
    _timestamp = timestamp;
    _uploadData = uploadData;
    if (uploadData) {
        _uploadContent = [NSJSONSerialization JSONObjectWithData:uploadData options:0 error:nil];
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Upload\n Id: %lld\n UUID: %@\n Content: %@\n timestamp: %.0f\n", self.uploadId, self.uuid, self.uploadContent, self.timestamp];
}

- (BOOL)isEqual:(MPUpload *)object {
//    unsigned int numberOfProperties;
//    class_copyPropertyList([self class], &numberOfProperties);
//    
//    if (numberOfProperties != 5) {
//        return NO;
//    }
    
    BOOL isEqual = _sessionId == object.sessionId &&
                   _uploadId == object.uploadId &&
                   _timestamp == object.timestamp &&
                   [_uploadData isEqualToData:object.uploadData];
    
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPUpload *copyObject = [[MPUpload alloc] initWithSessionId:_sessionId
                                                      uploadId:_uploadId
                                                          UUID:[_uuid copy]
                                                    uploadData:[_uploadData copy]
                                                     timestamp:_timestamp];
    
    return copyObject;
}

#pragma mark Public methods
- (NSDictionary *)dictionaryRepresentation {
    return self.uploadContent;
}

- (NSString *)serializedString {
    NSString *serializedString = [[NSString alloc] initWithData:self.uploadData encoding:NSUTF8StringEncoding];
    return serializedString;
}

@end
