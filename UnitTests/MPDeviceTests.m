#import <XCTest/XCTest.h>
#import "MPDevice.h"
#import "OCMock.h"
#import "MPIUserDefaults.h"
#import "MPIConstants.h"

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

- (void)testDictionaryDescription {
#if TARGET_OS_IOS == 1
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSData *testDeviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
    userDefaults[kMPDeviceTokenKey] = testDeviceToken;

    MPDevice *device = [[MPDevice alloc] init];
    NSDictionary *testDictionary = device.dictionaryRepresentation;
    XCTAssertEqualObjects(testDictionary[@"dll"], @"en");
    XCTAssertEqualObjects(testDictionary[@"dlc"], @"US");
    XCTAssertEqualObjects(testDictionary[@"aid"], @"00000000-0000-0000-0000-000000000000");
    XCTAssertEqualObjects(testDictionary[@"dma"], @"Apple");
    XCTAssertEqualObjects(testDictionary[kMPDeviceTokenKey], @"3c3030303030303030303030303030303030303030303030303030303030303e");
#endif
}

@end
