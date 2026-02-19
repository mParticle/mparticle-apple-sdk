#import <XCTest/XCTest.h>
#import "MPKitFirebaseGA4.h"

@interface MPKitFirebaseGA4Tests : XCTestCase

@end

@implementation MPKitFirebaseGA4Tests

- (void)testKitCode {
    XCTAssertEqualObjects([MPKitFirebaseGA4 kitCode], @243);
}

@end
