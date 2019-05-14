#import <XCTest/XCTest.h>
#import "MPDevice.h"
#import "OCMock.h"

@interface MPDeviceTests : XCTestCase

@end

@implementation MPDeviceTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testTelephonyRadioAccessTechnology {
#if TARGET_OS_IOS == 1
    CTTelephonyNetworkInfo *mockTelephonyNetworkInfo = OCMPartialMock([[CTTelephonyNetworkInfo alloc] init]);
    [[[(id)mockTelephonyNetworkInfo stub] andReturn:@"foo"] currentRadioAccessTechnology];
    MPDevice *device = [[MPDevice alloc] init];
    [device setValue:mockTelephonyNetworkInfo forKey:@"telephonyNetworkInfo"];
    NSString *technology = device.radioAccessTechnology;
    XCTAssertEqualObjects(technology, @"None");
#endif
}

@end
