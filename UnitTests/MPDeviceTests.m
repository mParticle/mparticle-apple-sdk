#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MPDevice.h"
#import "MPIUserDefaults.h"
#import "MPIConstants.h"

@interface MPDeviceTests : XCTestCase

@end

@implementation MPDeviceTests

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
    XCTAssertEqualObjects(testDictionary[@"dma"], @"Apple");
    XCTAssertEqualObjects(testDictionary[kMPDeviceTokenKey], @"3c3030303030303030303030303030303030303030303030303030303030303e");
#endif
}

@end
