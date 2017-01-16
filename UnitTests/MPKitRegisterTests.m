//
//  MPKitRegisterTests.m
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
#import "MPKitRegister.h"
#import "MPKitProtocol.h"
#import "MPKitTestClass.h"

@interface MPKitRegisterTests : XCTestCase

@end

@implementation MPKitRegisterTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInstance {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClass" startImmediately:NO];
    XCTAssertNotNil(kitRegister, @"Should not have been nil.");
    XCTAssertEqualObjects(kitRegister.code, @42, @"Should have been equal.");
    XCTAssertEqualObjects(kitRegister.name, @"KitTest", @"Should have been equal.");
    XCTAssertEqualObjects(kitRegister.className, @"MPKitTestClass", @"Should have been equal.");
    XCTAssertNil(kitRegister.wrapperInstance, @"Should have been nil.");
    
    kitRegister.wrapperInstance = [[NSClassFromString(kitRegister.className) alloc] initWithConfiguration:@{@"appKey":@"🔑"} startImmediately:kitRegister.startImmediately];
    XCTAssertNotNil(kitRegister.wrapperInstance, @"Should not have been nil.");
    XCTAssertEqualObjects([kitRegister.wrapperInstance class], [MPKitTestClass class], @"Should have been equal.");
    XCTAssertFalse(kitRegister.wrapperInstance.started, @"Should have been false.");
    [kitRegister.wrapperInstance start];
    XCTAssertTrue(kitRegister.wrapperInstance.started, @"Should have been true.");
}

@end
