#import <XCTest/XCTest.h>
#import <CommonCrypto/CommonDigest.h>
#import "MPBaseTestCase.h"
@import mParticle_Apple_SDK_Swift;
#if TARGET_OS_IOS == 1
#import <OCMock/OCMock.h>
#import "MPIConstants.h"

@interface MPConnectorTests  : MPBaseTestCase

@end

@implementation MPConnectorTests

- (void)testGeneratedSwiftInterfacePreservesRuntimeContracts {
    MPConnector *connector = [[MPConnector alloc] init];
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];

    XCTAssertEqualObjects(NSStringFromClass([MPConnector class]), @"MPConnector");
    XCTAssertEqualObjects(NSStringFromClass([MPConnectorResponse class]), @"MPConnectorResponse");
    XCTAssertTrue([connector conformsToProtocol:@protocol(MPConnectorProtocol)]);
    XCTAssertTrue([response conformsToProtocol:@protocol(MPConnectorResponseProtocol)]);
    XCTAssertEqual(HTTPStatusCodeSuccess, 200);
    XCTAssertEqual(HTTPStatusCodeNetworkAuthenticationRequired, 511);
}

@end

#endif
