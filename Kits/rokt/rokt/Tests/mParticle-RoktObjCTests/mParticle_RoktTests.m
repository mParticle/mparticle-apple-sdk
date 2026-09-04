#import <XCTest/XCTest.h>
@import mParticle_Rokt;
@import mParticle_Apple_SDK;
@import RoktContracts;

@interface MPKitRokt (Testing)
- (NSDictionary<NSString *, RoktEmbeddedView *> *)confirmEmbeddedViews:(NSDictionary *)embeddedViews;
@end

@interface mParticle_RoktTests : XCTestCase
@end

@implementation mParticle_RoktTests

- (void)testRuntimeClassAndKitCodeRemainStable {
    Class kitClass = NSClassFromString(@"MPKitRokt");
    XCTAssertEqual(kitClass, [MPKitRokt class]);
    XCTAssertEqualObjects([MPKitRokt kitCode], @181);
}

- (void)testKitRetainsObjectiveCContracts {
    MPKitRokt *kit = [[MPKitRokt alloc] init];
    XCTAssertTrue([kit conformsToProtocol:@protocol(MPKitProtocol)]);
    XCTAssertTrue([kit conformsToProtocol:@protocol(MPRoktKitDispatchTarget)]);
}

- (void)testRequiredDispatchSelectorsRemainAvailable {
    MPKitRokt *kit = [[MPKitRokt alloc] init];
    NSArray<NSString *> *selectors = @[
        NSStringFromSelector(@selector(didFinishLaunchingWithConfiguration:)),
        NSStringFromSelector(@selector(selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:)),
        NSStringFromSelector(@selector(selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:)),
        NSStringFromSelector(@selector(registerPaymentExtension:)),
        NSStringFromSelector(@selector(purchaseFinalized:catalogItemId:success:)),
        NSStringFromSelector(@selector(events:onEvent:)),
        NSStringFromSelector(@selector(globalEvents:)),
        NSStringFromSelector(@selector(close)),
        NSStringFromSelector(@selector(setSessionId:)),
        NSStringFromSelector(@selector(getSessionId)),
        NSStringFromSelector(@selector(clearSession)),
        NSStringFromSelector(@selector(handleURLCallback:)),
        NSStringFromSelector(@selector(logMParticleApiDiagnostic:))
    ];

    for (NSString *selectorName in selectors) {
        XCTAssertTrue([kit respondsToSelector:NSSelectorFromString(selectorName)], @"Missing %@", selectorName);
    }
}

- (void)testMissingAccountIdReturnsRequirementsNotMet {
    MPKitRokt *kit = [[MPKitRokt alloc] init];
    MPKitExecStatus *status = [kit didFinishLaunchingWithConfiguration:@{}];
    XCTAssertEqual(status.returnCode, MPKitReturnCodeRequirementsNotMet);
    XCTAssertNil(kit.configuration);
}

- (void)testConfigurationIsForwardedToSwiftImplementation {
    MPKitRokt *kit = [[MPKitRokt alloc] init];
    NSDictionary *configuration = @{@"accountId": @"test-account", @"stripePublishableKey": @"pk_test"};
    kit.configuration = configuration;
    XCTAssertEqualObjects(kit.configuration, configuration);
}

- (void)testLegacyAttributeHelperPreservesExplicitSandbox {
    NSDictionary *result = [MPKitRokt prepareAttributes:@{@"sandbox": @"true", @"key": @"value"}
                                           filteredUser:nil
                                         performMapping:NO];
    XCTAssertEqualObjects(result[@"sandbox"], @"true");
    XCTAssertEqualObjects(result[@"key"], @"value");
}

- (void)testMalformedEmbeddedViewsAreDiscardedAtObjectiveCBoundary {
    MPKitRokt *kit = [[MPKitRokt alloc] init];
    RoktEmbeddedView *validView = [[RoktEmbeddedView alloc] initWithFrame:CGRectZero];
    NSDictionary *result = [kit confirmEmbeddedViews:@{
        @"valid": validView,
        @"invalid": [UIView new],
        @42: validView
    }];

    XCTAssertEqualObjects(result, @{@"valid": validView});
}

@end
