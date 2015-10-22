//
//  MPCommand.m
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

#import "MPCommand.h"
#import "MPSession.h"
#import "MPConstants.h"

@interface MPCommand()

@property (nonatomic, strong) NSString *headerContent;
@property (nonatomic, strong) NSDictionary *headerDictionary;
@property (nonatomic, strong) NSString *postContent;

@end


@implementation MPCommand

- (instancetype)init {
    return [self initWithSessionId:0 commandId:0 UUID:[[NSUUID UUID] UUIDString] url:nil httpMethod:nil headerData:nil postData:nil timestamp:[[NSDate date] timeIntervalSince1970]];
}

- (instancetype)initWithSession:(MPSession *)session commandDictionary:(NSDictionary *)commandDictionary {
    NSDictionary *headerDictionary = commandDictionary[kMPHTTPHeadersKey];
    if (!headerDictionary) {
        return nil;
    }
    
    NSData *postData = nil;
    if ([commandDictionary[kMPResponseMethodKey] isEqualToString:kMPHTTPMethodPost]) {
        _postContent = commandDictionary[kMPResponsePOSTDataKey];
        
        if (_postContent && _postContent.length > 0) {
            postData = [[NSData alloc] initWithBase64EncodedString:_postContent options:0];
        }
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *urlString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)commandDictionary[kMPResponseURLKey], NULL, CFSTR(";"), kCFStringEncodingUTF8);
#pragma clang diagnostic pop
    
    return [self initWithSessionId:session.sessionId
                         commandId:0
                              UUID:[self newUUID]
                               url:[NSURL URLWithString:urlString]
                        httpMethod:commandDictionary[kMPResponseMethodKey]
                        headerData:[NSJSONSerialization dataWithJSONObject:headerDictionary options:0 error:nil]
                          postData:postData
                         timestamp:[[NSDate date] timeIntervalSince1970]];
}

- (instancetype)initWithSessionId:(int64_t)sessionId commandId:(int64_t)commandId UUID:(NSString *)uuid url:(NSURL *)url httpMethod:(NSString *)httpMethod headerData:(NSData *)headerData postData:(NSData *)postData timestamp:(NSTimeInterval)timestamp {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _sessionId = sessionId;
    _commandId = commandId;
    _uuid = uuid;
    _url = url;
    _httpMethod = httpMethod;
    
    _headerData = headerData;
    if (headerData) {
        _headerDictionary = [NSJSONSerialization JSONObjectWithData:headerData options:0 error:nil];
        _headerContent = [[NSString alloc] initWithData:headerData encoding:NSUTF8StringEncoding];
    }
    
    _postData = postData;
    if (_postData) {
        _postContent = [[NSString alloc] initWithData:_postData encoding:NSUTF8StringEncoding];
    }
    
    _timestamp = timestamp;
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Command\n Id: %lld\n UUID: %@\n url: %@\n Header: %@\n Content: %@\n timestamp: %.0f\n", self.commandId, self.uuid, self.url, self.headerDictionary, self.postContent, self.timestamp];
}

- (BOOL)isEqual:(MPCommand *)object {
//    unsigned int numberOfProperties;
//    class_copyPropertyList([self class], &numberOfProperties);
//    
//    if (numberOfProperties != 10) {
//        return NO;
//    }
    
    BOOL isEqual = _sessionId == object.sessionId &&
                   _commandId == object.commandId &&
                   _timestamp == object.timestamp &&
                   [_url isEqual:object.url] &&
                   [_headerData isEqualToData:object.headerData];
    
    return isEqual;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPCommand *copyObject = [[MPCommand alloc] initWithSessionId:_sessionId
                                                       commandId:_commandId
                                                            UUID:[_uuid copy]
                                                             url:[_url copy]
                                                      httpMethod:[_httpMethod copy]
                                                      headerData:[_headerData copy]
                                                        postData:[_postData copy]
                                                       timestamp:_timestamp];
    
    return copyObject;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt64:self.sessionId forKey:@"sessionId"];
    [coder encodeInt64:self.commandId forKey:@"commandId"];
    [coder encodeObject:self.uuid forKey:@"uuid"];
    [coder encodeObject:[self.url absoluteString] forKey:@"url"];
    [coder encodeObject:self.httpMethod forKey:@"httpMethod"];
    [coder encodeObject:self.headerContent forKey:@"headerContent"];
    [coder encodeObject:self.postContent forKey:@"postContent"];
    [coder encodeDouble:self.timestamp forKey:@"timestamp"];
}

- (id)initWithCoder:(NSCoder *)coder {
    NSString *headerContent = [coder decodeObjectForKey:@"headerContent"];
    NSData *headerData = [headerContent dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *postContent = [coder decodeObjectForKey:@"postContent"];
    NSData *postData = postContent ? [postContent dataUsingEncoding:NSUTF8StringEncoding] : nil;
    
    self = [self initWithSessionId:[coder decodeInt64ForKey:@"sessionId"]
                         commandId:[coder decodeInt64ForKey:@"commandId"]
                              UUID:[coder decodeObjectForKey:@"uuid"]
                               url:[NSURL URLWithString:[coder decodeObjectForKey:@"url"]]
                        httpMethod:[coder decodeObjectForKey:@"httpMethod"]
                        headerData:headerData
                          postData:postData
                         timestamp:[coder decodeDoubleForKey:@"timestamp"]];
    
    return self;
}

@end
