#import <XCTest/XCTest.h>
#import "MPKitFirebase.h"

@interface MPKitFirebaseTests : XCTestCase

@end

@implementation MPKitFirebaseTests

- (void)testKitCode {
    XCTAssertEqualObjects([MPKitFirebase kitCode], @243);
}

@end
