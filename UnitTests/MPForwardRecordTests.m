//
//  MPForwardRecordTests.m
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
#import "MPForwardRecord.h"
#import "MPKitFilter.h"
#import "MPEnums.h"
#import "MPStateMachine.h"
#import "MPEvent.h"
#import "MPKitExecStatus.h"
#import "MPKitContainer.h"
#import "MPKitFilter.h"
#import "MPProduct.h"
#import "MPCommerceEvent.h"

@interface MPForwardRecordTests : XCTestCase

@end

@implementation MPForwardRecordTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInstance {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    XCTAssertTrue([execStatus success], @"Should have been true.");
    XCTAssertEqual(execStatus.forwardCount, 1, @"Should have been equal.");
    
    [execStatus incrementForwardCount];
    XCTAssertEqual(execStatus.forwardCount, 2, @"Should have been equal.");
    
    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                       execStatus:execStatus
                                                                        stateFlag:YES];
    forwardRecord.forwardRecordId = 314;
    XCTAssertNotNil(forwardRecord, @"Should not have been nil.");
    
    NSData *dataRepresentation = [forwardRecord dataRepresentation];
    
    MPForwardRecord *derivedForwardRecord = [[MPForwardRecord alloc] initWithId:314 data:dataRepresentation];
    XCTAssertNotNil(derivedForwardRecord, @"Should not have been nil.");
    XCTAssertEqualObjects(forwardRecord, derivedForwardRecord, @"Should have been equal.");
    
    forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                      execStatus:execStatus];
    XCTAssertNotNil(forwardRecord, @"Should not have been nil.");
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

- (void)testWithProjectedCommerceEvent {
    NSDictionary *expectedDataDictionary = @{
                                             @"dt":@"cm",
                                             @"mid":@(MPKitInstanceLocalytics),
                                             @"et":@"ProductViewDetail"
                                             };
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    
    MPCommerceEvent *originalEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionViewDetail product:nil];
    MPEvent *projectedEvent = [[MPEvent alloc] initWithName:@"foo" type:MPEventTypeOther];
    MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithEvent:projectedEvent shouldFilter:NO];
    
    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypeCommerceEvent
                                                                       execStatus:execStatus
                                                                        kitFilter:kitFilter
                                                                    originalEvent:originalEvent];
    
    XCTAssertNotNil(forwardRecord, @"Should not have been nil.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"dt"], expectedDataDictionary[@"dt"], @"Does not match.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"mid"], expectedDataDictionary[@"mid"], @"Does not match.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"et"], expectedDataDictionary[@"et"], @"Does not match.");
    XCTAssertEqualObjects(forwardRecord.dataDictionary[@"n"], nil, @"Does not match.");
    
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
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"Sonic Screwdriver" sku:@"SNCDRV" quantity:@1 price:@3.14];
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:commerceEvent shouldFilter:NO];
    
    forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypeCommerceEvent
                                                      execStatus:execStatus
                                                       kitFilter:kitFilter
                                                   originalEvent:commerceEvent];
    XCTAssertNotNil(forwardRecord, @"Should not have been nil.");
}

- (void)testEquality {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    
    MPForwardRecord *forwardRecord1 = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                        execStatus:execStatus
                                                                         stateFlag:YES];
    
    MPForwardRecord *forwardRecord2 = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                        execStatus:execStatus
                                                                         stateFlag:YES];
    
    forwardRecord2.timestamp = forwardRecord1.timestamp;
    
    XCTAssertEqualObjects(forwardRecord1, forwardRecord2, @"Should have been equal");
    
    forwardRecord1.forwardRecordId = 123;
    forwardRecord2.forwardRecordId = 123;
    XCTAssertEqualObjects(forwardRecord1, forwardRecord2, @"Should have been equal");

    forwardRecord2.forwardRecordId = 321;
    XCTAssertNotEqualObjects(forwardRecord1, forwardRecord2, @"Should not have been equal");
    
    forwardRecord2 = nil;
    XCTAssertNotEqualObjects(forwardRecord1, forwardRecord2, @"Should not have been equal");
    
    forwardRecord2 = (MPForwardRecord *)[NSNull null];
    XCTAssertNotEqualObjects(forwardRecord1, forwardRecord2, @"Should not have been equal");
}

- (void)testDataRepresentation {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    
    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                       execStatus:execStatus
                                                                        stateFlag:YES];
    
    NSData *dataRepresentation = [forwardRecord dataRepresentation];
    XCTAssertNotNil(dataRepresentation, @"Should not have been nil.");
    
    NSMutableDictionary *dataDictionary = nil;
    forwardRecord.dataDictionary = dataDictionary;
    dataRepresentation = [forwardRecord dataRepresentation];
    XCTAssertNil(dataRepresentation, @"Should have been nil.");
    
    dataDictionary = (NSMutableDictionary *)[NSNull null];
    forwardRecord.dataDictionary = dataDictionary;
    dataRepresentation = [forwardRecord dataRepresentation];
    XCTAssertNil(dataRepresentation, @"Should have been nil.");
    
    dataDictionary = (NSMutableDictionary *)@"This clearly is not an instance of NSMutableDictionary";
    forwardRecord.dataDictionary = dataDictionary;
    dataRepresentation = [forwardRecord dataRepresentation];
    XCTAssertNil(dataRepresentation, @"Should have been nil.");
}

- (void)testDescription {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    
    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                       execStatus:execStatus
                                                                        stateFlag:YES];
    
    NSString *description = [forwardRecord description];
    XCTAssertNotNil(description, @"Should not have been nil.");
}

@end
