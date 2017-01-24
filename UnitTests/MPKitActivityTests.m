//
//  MPKitActivityTests.m
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

#import "MPConsumerInfo.h"
#import "MPExtensionProtocol.h"
#import "MPKitActivity.h"
#import "MPKitConfiguration.h"
#import "MPKitContainer.h"
#import "MPKitInstanceValidator.h"
#import "MPKitRegister.h"
#import "MPKitTestClass.h"
#import "MPStateMachine.h"
#import <XCTest/XCTest.h>

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer(Tests)

- (void)startKitRegister:(nonnull id<MPExtensionKitProtocol>)kitRegister configuration:(nonnull MPKitConfiguration *)kitConfiguration;

@end

#pragma mark - MPKitInstanceValidator category for unit tests
@interface MPKitInstanceValidator(BackendControllerTests)

+ (void)includeUnitTestKits:(NSArray<NSNumber *> *)kitCodes;

@end

#pragma mark - MPKitActivityTests
@interface MPKitActivityTests : XCTestCase

@property (nonatomic, strong) MPKitActivity *kitActivity;

@end


@implementation MPKitActivityTests

- (void)setUp {
    [super setUp];

    _kitActivity = [[MPKitActivity alloc] init];
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";
    stateMachine.consumerInfo.mpId = @(-986700791391657968);
    
    [MPKitInstanceValidator includeUnitTestKits:@[@42]];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    if (!registeredKits) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClass" startImmediately:NO];
        [MPKitContainer registerKit:kitRegister];
        
        NSDictionary *configuration = @{
                                        @"id":@42,
                                        @"as":@{
                                                @"appId":@"MyAppId"
                                                }
                                        };
        
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
        [[MPKitContainer sharedInstance] startKitRegister:kitRegister configuration:kitConfiguration];
    }
}

- (void)tearDown {
    _kitActivity = nil;
    
    [super tearDown];
}

- (void)testCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"KitActivity completion handler"];
    
    [self.kitActivity kitInstance:@42 withHandler:^(id _Nullable kitInstance) {
        XCTAssertNotNil(kitInstance);
        XCTAssertTrue([kitInstance isKindOfClass:[MPKitTestClass class]]);
        
        BOOL isKitActive = [self.kitActivity isKitActive:@42];
        XCTAssertTrue(isKitActive);
        
        id syncKitInstance = [self.kitActivity kitInstance:@42];
        XCTAssertNotNil(syncKitInstance);
        XCTAssertTrue([syncKitInstance isKindOfClass:[MPKitTestClass class]]);
        
        [expectation fulfill];
    }];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    @"as":@{
                                            @"appId":@"cool app key"
                                            }
                                    };
    
    NSArray *kitConfigs = @[configuration];
    [[MPKitContainer sharedInstance] configureKits:nil];
    [[MPKitContainer sharedInstance] configureKits:kitConfigs];

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", @42];
    id<MPExtensionKitProtocol>kitRegister = [[[MPKitContainer registeredKits] filteredSetUsingPredicate:predicate] anyObject];
    
    [[MPKitContainer sharedInstance] startKitRegister:kitRegister configuration:kitConfiguration];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    [[MPKitContainer sharedInstance] configureKits:nil];
}

- (void)testKitAlreadyStarted {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    @"as":@{
                                            @"appId":@"cool app key"
                                            }
                                    };
    
    NSArray *kitConfigs = @[configuration];
    [[MPKitContainer sharedInstance] configureKits:nil];
    [[MPKitContainer sharedInstance] configureKits:kitConfigs];
    
    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", @42];
    id<MPExtensionKitProtocol>kitRegister = [[[MPKitContainer registeredKits] filteredSetUsingPredicate:predicate] anyObject];
    
    [[MPKitContainer sharedInstance] startKitRegister:kitRegister configuration:kitConfiguration];
    
    BOOL isKitActive = [self.kitActivity isKitActive:@42];
    XCTAssertTrue(isKitActive);
    
    [self.kitActivity kitInstance:@42 withHandler:^(id _Nullable kitInstance) {
        XCTAssertNotNil(kitInstance);
        XCTAssertTrue([kitInstance isKindOfClass:[MPKitTestClass class]]);
        
        id syncKitInstance = [self.kitActivity kitInstance:@42];
        XCTAssertNotNil(syncKitInstance);
        XCTAssertTrue([syncKitInstance isKindOfClass:[MPKitTestClass class]]);
    }];
    
    [[MPKitContainer sharedInstance] configureKits:nil];
}

@end
