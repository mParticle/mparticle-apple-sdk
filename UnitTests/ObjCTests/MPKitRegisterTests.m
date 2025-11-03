#import <XCTest/XCTest.h>
#import "MPKitRegister.h"
#import "MPKitProtocol.h"
#import "MPKitTestClassNoStartImmediately.h"
#import "MPBaseTestCase.h"

@interface MPKitRegisterTests : MPBaseTestCase

@end

@implementation MPKitRegisterTests

- (void)testInstance {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
    XCTAssertNotNil(kitRegister, @"Should not have been nil.");
    XCTAssertEqualObjects(kitRegister.code, @42, @"Should have been equal.");
    XCTAssertEqualObjects(kitRegister.name, @"KitTest", @"Should have been equal.");
    XCTAssertEqualObjects(kitRegister.className, @"MPKitTestClassNoStartImmediately", @"Should have been equal.");
    XCTAssertNil(kitRegister.wrapperInstance, @"Should have been nil.");
    
    kitRegister.wrapperInstance = [[NSClassFromString(kitRegister.className) alloc] init];
    [kitRegister.wrapperInstance didFinishLaunchingWithConfiguration:@{@"appKey":@"🔑"}];
    XCTAssertNotNil(kitRegister.wrapperInstance, @"Should not have been nil.");
    XCTAssertEqualObjects([kitRegister.wrapperInstance class], [MPKitTestClassNoStartImmediately class], @"Should have been equal.");
    XCTAssertFalse(kitRegister.wrapperInstance.started, @"Should have been false.");
    [kitRegister.wrapperInstance start];
    XCTAssertTrue(kitRegister.wrapperInstance.started, @"Should have been true.");
}

- (void)testDescription {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
    NSString *description = [kitRegister description];
    XCTAssertNotNil(description, @"Should not have been nil.");
}

@end
