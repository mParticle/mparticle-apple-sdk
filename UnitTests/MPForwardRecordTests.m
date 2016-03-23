//
//  MPForwardRecordTests.m
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
#import "MPForwardRecord.h"
#import "MPKitFilter.h"
#import "MPEnums.h"
#import "MPStateMachine.h"
#import "MPEvent.h"
#import "MPKitExecStatus.h"
#import "MPKitContainer.h"
#import "MPKitFilter.h"

@interface MPForwardRecordTests : XCTestCase

@end

@implementation MPForwardRecordTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testRemoteNotificationForwardReport {
    NSDictionary *expectedDataDictionary = @{
                                             @"dt":@"pr",
                                             @"mid":@(MPKitInstanceAppboy),
                                             @"r":@YES
                                             };
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    
    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                       execStatus:execStatus
                                                                        stateFlag:YES];
    
    XCTAssertNotNil(forwardRecord, @"Should not have been nil.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"dt"], expectedDataDictionary[@"dt"], @"Does not match.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"r"], expectedDataDictionary[@"r"], @"Does not match.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"mid"], expectedDataDictionary[@"mid"], @"Does not match.");
    XCTAssertEqual(forwardRecord.dataDictionary.count, 4, @"Does not match.");
}

- (void)testOptOutForwardReport {
    NSDictionary *expectedDataDictionary = @{
                                             @"dt":@"o",
                                             @"mid":@(MPKitInstanceComScore),
                                             @"s":@NO
                                             };
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceComScore) returnCode:MPKitReturnCodeSuccess];
    
    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypeOptOut
                                                                       execStatus:execStatus
                                                                        stateFlag:NO];
    
    XCTAssertNotNil(forwardRecord, @"Should not have been nil.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"dt"], expectedDataDictionary[@"dt"], @"Does not match.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"s"], expectedDataDictionary[@"s"], @"Does not match.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"mid"], expectedDataDictionary[@"mid"], @"Does not match.");
    XCTAssertEqual(forwardRecord.dataDictionary.count, 4, @"Does not match.");
}

- (void)testWithOriginalEvent {
    NSDictionary *expectedDataDictionary = @{
                                             @"dt":@"e",
                                             @"mid":@(MPKitInstanceLocalytics),
                                             @"et":@"Other",
                                             @"n":@"Original"
                                             };
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    
    MPEvent *originalEvent = [[MPEvent alloc] initWithName:@"Original" type:MPEventTypeOther];
    
    MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithEvent:originalEvent shouldFilter:NO];
    XCTAssertNil(kitFilter.forwardCommerceEvent, @"Should have been nil.");
    XCTAssertEqualObjects(originalEvent, kitFilter.forwardEvent, @"Should have been equal.");
    
    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypeEvent
                                                                       execStatus:execStatus
                                                                        kitFilter:kitFilter
                                                                    originalEvent:originalEvent];
    
    XCTAssertNotNil(forwardRecord, @"Should not have been nil.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"dt"], expectedDataDictionary[@"dt"], @"Does not match.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"mid"], expectedDataDictionary[@"mid"], @"Does not match.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"et"], expectedDataDictionary[@"et"], @"Does not match.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"n"], expectedDataDictionary[@"n"], @"Does not match.");
}

@end
