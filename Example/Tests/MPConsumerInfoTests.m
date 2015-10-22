//
//  MPConsumerInfoTests.m
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

#import <XCTest/XCTest.h>
#import "MPConsumerInfo.h"
#import "MPConstants.h"

@interface MPConsumerInfoTests : XCTestCase {
    NSDictionary *responseDictionary;
    NSDictionary *consumerInfoDictionary;
}

@end


@implementation MPConsumerInfoTests

- (void)setUp {
    [super setUp];
    
    responseDictionary = @{@"ci":@{
                                   @"ck":@{
                                           @"rpl":@{
                                                   @"c":@"288160084=2832403&-515079401=2832403&1546594223=2832403&264784951=2832403&4151713=2832403&-1663781220=2832403",
                                                   @"e":@"2015-05-26T22:43:31.505262Z"
                                                   },
                                           @"uddif":@{
                                                   @"c":@"uah6978=1068490497975183452&uahist=%2524Gender%3Dm%26Tag1%3D",
                                                   @"e":@"2025-05-18T22:43:31.461026Z"
                                                   },
                                           @"uid":@{
                                                   @"c":@"u=3452189063653540060&cr=2827774&lbri=53CB5411-5BF0-402C-88E4-DFE91F921D82&g=7754fbee-1b83-4cab-9b59-34518c14ae85&ls=2832403&lbe=2832403",
                                                   @"e":@"2025-05-15T17:34:07.450231Z"
                                                   },
                                           @"uuc6978":@{
                                                   @"c":@"nu=t&et-Unknown=2832403&et-Other=2832403&et-=2832403&et-Transaction=2832198",
                                                   @"e":@"2020-05-16T17:34:07.941843Z"
                                                   }
                                           },
                                   @"das":@"7754fbee-1b83-4cab-9b59-34518c14ae85",
                                   @"mpid":@3452189063653540060
                                   },
                           @"ct":@1432248211838,
                           @"dt":@"rh",
                           @"id":@"aeea31ab-2ee6-4126-bf9d-1812873aee20",
                           @"msgs":@[]
                           };
    
    consumerInfoDictionary = responseDictionary[kMPRemoteConfigConsumerInfoKey];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInstance {
    MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:consumerInfoDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:@{}];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:nil];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:(NSDictionary *)[NSNull null]];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
}

- (void)testCookiesDictionary {
    MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:consumerInfoDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    NSDictionary *cookiesDictionary = [consumerInfo cookiesDictionaryRepresentation];
    XCTAssertNotNil(cookiesDictionary, @"Cookies dictionary should not have been nil.");
    XCTAssertNotNil(cookiesDictionary[@"rpl"], @"Value for key should not have been nil.");
    XCTAssertNotNil(cookiesDictionary[@"uddif"], @"Value for key should not have been nil.");
    XCTAssertNotNil(cookiesDictionary[@"uid"], @"Value for key should not have been nil.");
    XCTAssertNotNil(cookiesDictionary[@"uuc6978"], @"Value for key should not have been nil.");
}

- (void)testNullValues {
    NSDictionary *localResponseDictionary = @{@"ci":@{
                                                      @"ck":@{
                                                              @"rpl":@{
                                                                      @"c":[NSNull null],
                                                                      @"e":@"2015-05-26T22:43:31.505262Z"
                                                                      },
                                                              @"uddif":@{
                                                                      @"c":@"uah6978=1068490497975183452&uahist=%2524Gender%3Dm%26Tag1%3D",
                                                                      @"e":[NSNull null]
                                                                      },
                                                              @"uid":[NSNull null],
                                                              [NSNull null]:@{
                                                                      @"c":@"nu=t&et-Unknown=2832403&et-Other=2832403&et-=2832403&et-Transaction=2832198",
                                                                      @"e":@"2020-05-16T17:34:07.941843Z"
                                                                      }
                                                              },
                                                      @"das":[NSNull null],
                                                      @"mpid":[NSNull null]
                                                      },
                                              @"ct":@1432248211838,
                                              @"dt":@"rh",
                                              @"id":@"aeea31ab-2ee6-4126-bf9d-1812873aee20",
                                              @"msgs":[NSNull null]
                                              };
    
    NSDictionary *localConsumerInfoDictionary = localResponseDictionary[kMPRemoteConfigConsumerInfoKey];
    
    MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:localConsumerInfoDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    NSDictionary *cookiesDictionary = [consumerInfo cookiesDictionaryRepresentation];
    XCTAssertNotNil(cookiesDictionary, @"Cookies dictionary should not have been nil.");
    
    localResponseDictionary = @{@"ci":@{
                                        @"ck":[NSNull null],
                                        @"das":[NSNull null],
                                        @"mpid":[NSNull null]
                                        },
                                @"ct":@1432248211838,
                                @"dt":@"rh",
                                @"id":@"aeea31ab-2ee6-4126-bf9d-1812873aee20",
                                @"msgs":[NSNull null]
                                };
    
    localConsumerInfoDictionary = localResponseDictionary[kMPRemoteConfigConsumerInfoKey];
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:localConsumerInfoDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    localResponseDictionary = @{@"ci":[NSNull null],
                                @"ct":@1432248211838,
                                @"dt":@"rh",
                                @"id":@"aeea31ab-2ee6-4126-bf9d-1812873aee20",
                                @"msgs":[NSNull null]
                                };
    
    localConsumerInfoDictionary = localResponseDictionary[kMPRemoteConfigConsumerInfoKey];
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:localConsumerInfoDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    cookiesDictionary = [consumerInfo cookiesDictionaryRepresentation];
    XCTAssertNil(cookiesDictionary, @"Cookies dictionary should have been nil.");
}

@end
