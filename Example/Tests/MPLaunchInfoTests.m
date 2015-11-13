//
//  MPLaunchInfoTests.m
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
#import "MPLaunchInfo.h"

@interface MPLaunchInfoTests : XCTestCase

@property (nonatomic, strong) id annotation;
@property (nonatomic, strong) NSURL *url;

@end


@implementation MPLaunchInfoTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAnnotation {
    NSURL *url = [NSURL URLWithString:@"http://mparticle.com"];
    NSString *sourceApp = @"testApp";
    id annotation = @{@"String Key":@"String Value",
                      @"Number Key":@42,
                      @"Date Key":[NSDate date],
                      @"Data Key":[@"Another string" dataUsingEncoding:NSUTF8StringEncoding]};
    
    MPLaunchInfo *launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNotNil(launchInfo, @"Should not have been nil.");
    XCTAssertTrue([launchInfo.annotation isKindOfClass:[NSDictionary class]], @"Should have been true.");
    NSDictionary *annotationDictionary = launchInfo.annotation;
    XCTAssertEqual(annotationDictionary.count, 2, @"Incorrect size.");
    XCTAssertEqualObjects(annotationDictionary[@"String Key"], annotation[@"String Key"], @"Should have been equal.");
    XCTAssertEqualObjects(annotationDictionary[@"Number Key"], annotation[@"Number Key"], @"Should have been equal.");
    
    annotation = @[@"String", @42, [NSDate date], [@"Another string" dataUsingEncoding:NSUTF8StringEncoding]];
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertTrue([launchInfo.annotation isKindOfClass:[NSArray class]], @"Should have been true.");
    NSArray *annotationArray = launchInfo.annotation;
    XCTAssertEqual(annotationArray.count, 2, @"Incorrect size.");
    XCTAssertEqualObjects(annotationArray[0], annotation[0], @"Should have been equal.");
    XCTAssertEqualObjects(annotationArray[1], annotation[1], @"Should have been equal.");
    
    annotation = @"String";
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertTrue([launchInfo.annotation isKindOfClass:[NSString class]], @"Should have been true.");
    XCTAssertEqualObjects(launchInfo.annotation, @"String", @"Should have been equal.");
    
    annotation = @42;
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertTrue([launchInfo.annotation isKindOfClass:[NSNumber class]], @"Should have been true.");
    XCTAssertEqualObjects(launchInfo.annotation, @42, @"Should have been equal.");
    
    annotation = [NSDate date];
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNil(launchInfo.annotation, @"Should have been nil.");
    
    annotation = [@"Another string" dataUsingEncoding:NSUTF8StringEncoding];
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNil(launchInfo.annotation, @"Should have been nil.");
}

- (void)testURL {
    NSURL *url = [NSURL URLWithString:@"http://mparticle.com/al_applink_data"];
    NSString *sourceApp = @"testApp";
    id annotation = nil;
    
    MPLaunchInfo *launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNotNil(launchInfo, @"Should not have been nil.");
    XCTAssertEqualObjects(launchInfo.sourceApplication, @"AppLink(testApp)", @"Should have been equal.");
    XCTAssertEqualObjects(launchInfo.url, url, @"Should have been equal.");
    
    url = [NSURL URLWithString:@"http://mparticle.com"];
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertEqualObjects(launchInfo.sourceApplication, @"testApp", @"Should have been equal.");
    XCTAssertEqualObjects(launchInfo.url, url, @"Should have been equal.");
}

- (void)testInvalidValues {
    NSURL *url = nil;
    NSString *sourceApp = @"testApp";
    id annotation = nil;
    
    MPLaunchInfo *launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNil(launchInfo, @"Should have been nil.");
    
    url = [NSURL URLWithString:@"http://mparticle.com"];
    sourceApp = nil;
    
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNil(launchInfo, @"Should have been nil.");
    
    url = (NSURL *)[NSNull null];
    sourceApp = @"testApp";
    
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNil(launchInfo, @"Should have been nil.");
    
    url = [NSURL URLWithString:@"http://mparticle.com"];
    sourceApp = (NSString *)[NSNull null];
    
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNil(launchInfo, @"Should have been nil.");
}

@end
