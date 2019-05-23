#import <XCTest/XCTest.h>
#import "MPAliasResponse.h"

@interface MPAliasResponseTests : XCTestCase

@end

@implementation MPAliasResponseTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testAliasResponseCodeSuccess {
    MPAliasResponse *response = [[MPAliasResponse alloc] init];
    response.responseCode = 200;
    XCTAssert(response.isSuccessful);
    response.responseCode = 202;
    XCTAssert(response.isSuccessful);
}

- (void)testAliasResponseCodeFailure {
    MPAliasResponse *response = [[MPAliasResponse alloc] init];
    response.responseCode = 400;
    XCTAssertFalse(response.isSuccessful);
    response.responseCode = 500;
    XCTAssertFalse(response.isSuccessful);
}

- (void)testAliasResponseProperties {
    MPAliasResponse *response = [[MPAliasResponse alloc] init];
    response.responseCode = 200;
    response.errorResponse = @"foo error";
    response.willRetry = NO;
    
    XCTAssertEqual(response.responseCode, 200);
    XCTAssertEqualObjects(response.errorResponse, @"foo error");
    XCTAssertEqual(response.willRetry, NO);
}

@end
