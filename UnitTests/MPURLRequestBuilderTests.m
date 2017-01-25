//
//  MPURLRequestBuilderTests.m
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

#import <XCTest/XCTest.h>
#import "MPConsumerInfo.h"
#import "MPIConstants.h"
#import "MPKitContainer.h"
#import "MPKitRegister.h"
#import "MPKitTestClass.h"
#import "MPMessage.h"
#import "MPNetworkCommunication.h"
#import "MPNetworkCommunication+Tests.h"
#import "MPStateMachine.h"
#import "MPURLRequestBuilder.h"
#import "NSUserDefaults+mParticle.h"

#pragma mark - MPURLRequestBuilder category
@interface MPURLRequestBuilder(Tests)

- (NSString *)hmacSha256Encode:(NSString *const)message key:(NSString *const)key;
- (NSString *)userAgent;

@end

#pragma mark - MPURLRequestBuilderTests
@interface MPURLRequestBuilderTests : XCTestCase

@end

@implementation MPURLRequestBuilderTests

- (void)setUp {
    [super setUp];
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";
    
    if (![MPKitContainer registeredKits]) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClass" startImmediately:NO];
        kitRegister.wrapperInstance = [[NSClassFromString(kitRegister.className) alloc] initWithConfiguration:@{@"appKey":@"🔑"} startImmediately:YES];
        [MPKitContainer registerKit:kitRegister];
        kitRegister = [[MPKitRegister alloc] initWithName:@"KitSecondTest" className:@"MPKitSecondTestClass" startImmediately:YES];
        [MPKitContainer registerKit:kitRegister];
    }
}

- (void)tearDown {
    [super tearDown];
}

- (void)testUserAgent {
    XCTestExpectation *expectation = [self expectationWithDescription:@"User-Agent"];
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    
    MPMessage *message = [[MPMessage alloc] initWithSession:[MPStateMachine sharedInstance].nullSession
                                                messageType:@"e"
                                                messageInfo:@{@"key":@"value"}
                                               uploadStatus:MPUploadStatusBatch
                                                       UUID:[[NSUUID UUID] UUIDString]
                                                  timestamp:[[NSDate date] timeIntervalSince1970]];
    
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication eventURL]
                                                                            message:[message serializedString]
                                                                         httpMethod:@"POST"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *userAgent = [urlRequestBuilder userAgent];
        XCTAssertNotNil(userAgent, @"Should not have been nil.");
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testHMACSha256Encode {
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[NSURL URLWithString:@"http://mparticle.com"]];
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSString *message = @"The Quick Brown Fox Jumps Over The Lazy Dog.";
    NSString *referenceEncodedMessage = @"ceefdfeab2fe404a7cbb75f6f6a01443286fab507eb85c213fce3d812e8b615c";
    NSString *encodedMessage = [urlRequestBuilder hmacSha256Encode:message key:stateMachine.apiKey];
    
    XCTAssertEqualObjects(encodedMessage, referenceEncodedMessage, @"HMAC Sha 256 is failing to encode correctly.");
}

- (void)testInvalidHMACSha256Encode {
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[NSURL URLWithString:@"http://mparticle.com"]];
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSString *message = nil;
    NSString *encodedMessage = [urlRequestBuilder hmacSha256Encode:message key:stateMachine.apiKey];
    XCTAssertNil(encodedMessage, @"Should not have tried to encode a nil message.");
    
    message = @"";
    encodedMessage = [urlRequestBuilder hmacSha256Encode:message key:stateMachine.apiKey];
    XCTAssertNotNil(encodedMessage, @"Encoded message should not have been nil.");
    
    message = @"The Quick Brown Fox Jumps Over The Lazy Dog.";
    encodedMessage = [urlRequestBuilder hmacSha256Encode:message key:nil];
    XCTAssertNil(encodedMessage, @"Should not have tried to encode with a nil key.");
}

- (void)testURLRequestComposition {
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication configURL] message:nil httpMethod:@"GET"];
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];
    
    NSDictionary *headersDictionary = [asyncURLRequest allHTTPHeaderFields];
    NSArray *keys = [headersDictionary allKeys];
    NSArray *headers = @[@"User-Agent", @"Accept-Encoding", @"Content-Encoding", @"locale", @"Content-Type", @"timezone", @"secondsFromGMT", @"Date", @"x-mp-signature", @"x-mp-env", @"x-mp-kits"];
    NSString *headerValue;
    
    for (NSString *header in headers) {
        XCTAssertTrue([keys containsObject:header], @"HTTP header %@ is missing", header);
        
        headerValue = headersDictionary[header];
        
        if ([header isEqualToString:@"Accept-Encoding"] || [header isEqualToString:@"Content-Encoding"]) {
            XCTAssertTrue([headerValue isEqualToString:@"gzip"], @"%@ has an invalid value: %@", header, headerValue);
        } else if ([header isEqualToString:@"Content-Type"]) {
            BOOL validContentType = [headerValue isEqualToString:@"application/x-www-form-urlencoded"];
            
            XCTAssertTrue(validContentType, @"%@ http header is invalid: %@", header, headerValue);
        } else if ([header isEqualToString:@"secondsFromGMT"] || [header isEqualToString:@"x-mp-signature"]) {
            XCTAssert([headerValue length] > 0, @"%@ has invalid length", header);
        } else if ([header isEqualToString:@"x-mp-env"]) {
            BOOL validEnvironment = [headerValue isEqualToString:[@(MPEnvironmentDevelopment) stringValue]] ||
            [headerValue isEqualToString:[@(MPEnvironmentProduction) stringValue]];
            
            XCTAssertTrue(validEnvironment, @"Invalid environment value: %@", headerValue);
        } else if ([header isEqualToString:@"x-mp-kits"]) {
            NSRange kitRange = [headerValue rangeOfString:@"42"];
            XCTAssertTrue(kitRange.location != NSNotFound);
            
            kitRange = [headerValue rangeOfString:@"314"];
            XCTAssertTrue(kitRange.location != NSNotFound);
        }
    }
}

- (void)testEtag {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *eTag = userDefaults[kMPHTTPETagHeaderKey];
    if (!eTag) {
        userDefaults[kMPHTTPETagHeaderKey] = @"1.618-2.718-3.141-42";
    }

    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication configURL] message:nil httpMethod:@"GET"];
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];

    NSDictionary *headersDictionary = [asyncURLRequest allHTTPHeaderFields];
    NSArray *keys = [headersDictionary allKeys];
    NSArray *headers = @[@"If-None-Match", @"Accept-Encoding", @"Content-Encoding", @"locale", @"Content-Type", @"timezone", @"secondsFromGMT", @"Date", @"x-mp-signature", @"x-mp-env", @"x-mp-kits"];
    NSString *headerValue;
    
    for (NSString *header in headers) {
        XCTAssertTrue([keys containsObject:header], @"HTTP header %@ is missing", header);
        
        headerValue = headersDictionary[header];
        
        if ([header isEqualToString:@"Accept-Encoding"] || [header isEqualToString:@"Content-Encoding"]) {
            XCTAssertTrue([headerValue isEqualToString:@"gzip"], @"%@ has an invalid value: %@", header, headerValue);
        } else if ([header isEqualToString:@"Content-Type"]) {
            BOOL validContentType = [headerValue isEqualToString:@"application/x-www-form-urlencoded"];
            
            XCTAssertTrue(validContentType, @"%@ http header is invalid: %@", header, headerValue);
        } else if ([header isEqualToString:@"secondsFromGMT"] || [header isEqualToString:@"x-mp-signature"]) {
            XCTAssert([headerValue length] > 0, @"%@ has invalid length", header);
        } else if ([header isEqualToString:@"x-mp-env"]) {
            BOOL validEnvironment = [headerValue isEqualToString:[@(MPEnvironmentDevelopment) stringValue]] ||
            [headerValue isEqualToString:[@(MPEnvironmentProduction) stringValue]];
            
            XCTAssertTrue(validEnvironment, @"Invalid environment value: %@", headerValue);
        } else if ([header isEqualToString:@"x-mp-kits"]) {
            NSRange kitRange = [headerValue rangeOfString:@"42"];
            XCTAssertTrue(kitRange.location != NSNotFound);
            
            kitRange = [headerValue rangeOfString:@"314"];
            XCTAssertTrue(kitRange.location != NSNotFound);
        } else if ([header isEqualToString:@"If-None-Match"]) {
            XCTAssertEqualObjects(headerValue, @"1.618-2.718-3.141-42");
        }
    }

    [userDefaults removeMPObjectForKey:kMPHTTPETagHeaderKey];
}

- (void)testComposingWithHeaderData {
    NSString *urlString = @"http://mparticle.com";
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[NSURL URLWithString:urlString]];
    
    NSString *userAgent = [NSString stringWithFormat:@"UnitTests/1.0 (iPhone; CPU iPhone OS like Mac OS X) (KHTML, like Gecko) mParticle/%@", kMParticleSDKVersion];
    
    NSDictionary *headersDictionary = @{@"User-Agent":userAgent,
                                        @"Accept-Encoding":@"gzip",
                                        @"Content-Encoding":@"gzip"};
    
    NSError *error = nil;
    NSData *headerData = [NSJSONSerialization dataWithJSONObject:headersDictionary options:0 error:&error];
    
    XCTAssertNil(error, @"Error serializing http header.");
    
    [urlRequestBuilder withHeaderData:headerData];
    
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];
    
    headersDictionary = [asyncURLRequest allHTTPHeaderFields];
    NSArray *keys = [headersDictionary allKeys];
    NSArray *headers = @[@"User-Agent", @"Accept-Encoding", @"Content-Encoding"];
    NSString *headerValue;
    
    for (NSString *header in headers) {
        XCTAssertTrue([keys containsObject:header], @"HTTP header %@ is missing", header);
        
        headerValue = headersDictionary[header];
        
        if ([header isEqualToString:@"User-Agent"]) {
            XCTAssertEqualObjects(headerValue, userAgent, @"User-Agent is not being set correctly.");
        } else if ([header isEqualToString:@"Accept-Encoding"] || [header isEqualToString:@"Content-Encoding"]) {
            XCTAssertTrue([headerValue isEqualToString:@"gzip"], @"%@ has an invalid value: %@", header, headerValue);
        }
    }
}

- (void)testPOSTURLRequest {
    NSString *urlString = @"http://mparticle.com";
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[NSURL URLWithString:urlString]];
    
    [urlRequestBuilder withHttpMethod:@"POST"];
    
    NSDictionary *postDictionary = @{@"key1":@"value1",
                                     @"arrayKey":@[@"item1", @"item2"],
                                     @"key2":@2,
                                     @"key3":@{@"nestedKey":@"nestedValue"}
                                     };
    
    NSError *error = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postDictionary options:0 error:&error];
    
    XCTAssertNil(error, @"Error serializing POST data.");
    
    [urlRequestBuilder withPostData:postData];
    
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];
    
    XCTAssertEqualObjects([asyncURLRequest HTTPMethod], @"POST", @"HTTP method is not being set to POST.");
    
    XCTAssertEqualObjects(postData, [asyncURLRequest HTTPBody], @"HTTP body is not being set as the post data.");
}

- (void)testInvalidURLs {
    NSURL *url = nil;
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:url];
    
    XCTAssertNil(urlRequestBuilder, @"Retuning a request builder from an invalid URL.");
    
    urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:url message:nil httpMethod:@"GET"];
    
    XCTAssertNil(urlRequestBuilder, @"Retuning a request builder from an invalid URL.");
    
    NSString *urlString = @"http://mparticle.com";
    urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[NSURL URLWithString:urlString] message:nil httpMethod:nil];
    
    XCTAssertEqualObjects(urlRequestBuilder.httpMethod, @"GET", @"HTTP method is assuming GET as default.");
}

- (void)testEventRequest {
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appKey":@"unique key"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1];
    [[MPKitContainer sharedInstance] configureKits:nil];
    [[MPKitContainer sharedInstance] configureKits:kitConfigs];
    
    XCTAssertEqual([MPURLRequestBuilder requestTimeout], 30, @"Should have been equal.");
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    
    MPMessage *message = [[MPMessage alloc] initWithSession:[MPStateMachine sharedInstance].nullSession
                                                messageType:@"e"
                                                messageInfo:@{@"key":@"value"}
                                               uploadStatus:MPUploadStatusBatch
                                                       UUID:[[NSUUID UUID] UUIDString]
                                                  timestamp:[[NSDate date] timeIntervalSince1970]];
    
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication eventURL]
                                                                            message:[message serializedString]
                                                                         httpMethod:@"POST"];
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];
    
    NSDictionary *headersDictionary = [asyncURLRequest allHTTPHeaderFields];
    NSArray *keys = [headersDictionary allKeys];
    NSArray *headers = @[@"User-Agent", @"Accept-Encoding", @"Content-Encoding", @"locale", @"Content-Type", @"timezone", @"secondsFromGMT", @"Date", @"x-mp-signature", @"x-mp-kits"];
    NSString *headerValue;
    
    for (NSString *header in headers) {
        XCTAssertTrue([keys containsObject:header], @"HTTP header %@ is missing", header);
        
        headerValue = headersDictionary[header];
        
        if ([header isEqualToString:@"Accept-Encoding"] || [header isEqualToString:@"Content-Encoding"]) {
            XCTAssertTrue([headerValue isEqualToString:@"gzip"], @"%@ has an invalid value: %@", header, headerValue);
        } else if ([header isEqualToString:@"Content-Type"]) {
            BOOL validContentType = [headerValue isEqualToString:@"application/json"];
            
            XCTAssertTrue(validContentType, @"%@ http header is invalid: %@", header, headerValue);
        } else if ([header isEqualToString:@"secondsFromGMT"] || [header isEqualToString:@"x-mp-signature"]) {
            XCTAssert([headerValue length] > 0, @"%@ has invalid length", header);
        } else if ([header isEqualToString:@"x-mp-kits"]) {
            XCTAssertEqualObjects(headerValue, @"42");
        }
    }

    // Remove all kit configurations
    NSArray *directoryContents = [[MPKitContainer sharedInstance] fetchKitConfigurationFileNames];
    if (directoryContents.count > 0) {
        NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
        
        for (NSString *fileName in directoryContents) {
            NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:fileName];
            [[MPKitContainer sharedInstance] removeKitConfigurationAtPath:kitPath];
        }
    }
}

@end
