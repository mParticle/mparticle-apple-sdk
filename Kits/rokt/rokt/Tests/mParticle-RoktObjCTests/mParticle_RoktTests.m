#import <XCTest/XCTest.h>
#import <objc/runtime.h>
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
        NSStringFromSelector(@selector(setSession:)),
        NSStringFromSelector(@selector(getSession)),
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

// accountId arrives from the server, so an empty string or any non-string shape has to be refused
// rather than handed to the provider SDK as a tag id.
- (void)testWrongTypedAccountIdReturnsRequirementsNotMet {
    for (id accountId in @[@"", @1, @[], @{}, [NSNull null]]) {
        MPKitRokt *kit = [[MPKitRokt alloc] init];
        MPKitExecStatus *status = nil;
        XCTAssertNoThrow(status = [kit didFinishLaunchingWithConfiguration:@{@"accountId": accountId}],
                         @"Threw on accountId %@.", accountId);
        XCTAssertEqual(status.returnCode, MPKitReturnCodeRequirementsNotMet,
                       @"Should have refused accountId %@.", accountId);
        XCTAssertNil(kit.configuration, @"Should not have retained settings for accountId %@.", accountId);
    }
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

// The kit's settings must come from the dictionary handed to it at launch and stay usable before
// it reports started, because a placement call can arrive in that window. Objective-C callers hand
// over an NSMutableDictionary they may keep mutating, so the kit has to hold a copy: a later edit
// to the caller's dictionary must not silently retarget which identity the hashed email is read
// from. Only an explicit refresh may change it, and stop must clear it.
- (void)testLaunchConfigurationIsCopiedAndOnlyChangesOnAnExplicitRefresh {
    // A successful launch initializes the real provider SDK, which this target cannot inject a
    // client into. Stubbing the initializer is how the Swift suite isolates the same path.
    // Rokt is a Swift class without an explicit ObjC name, so the runtime knows it module-qualified.
    Class roktClass = NSClassFromString(@"Rokt_Widget.Rokt") ?: NSClassFromString(@"Rokt");
    Method initialize = class_getClassMethod(roktClass,
                                             NSSelectorFromString(@"initWithRoktTagId:mParticleSdkVersion:mParticleKitVersion:"));
    XCTAssertTrue(initialize != NULL, @"Rokt initializer not found; the stub below would not apply.");
    void (^skipInitialization)(id, id, id, id) = ^(id _self, id tagId, id sdkVersion, id kitVersion) {};
    IMP initializationStub = imp_implementationWithBlock(skipInitialization);
    IMP originalInitialization = method_setImplementation(initialize, initializationStub);

    MPKitRokt *kit = [[MPKitRokt alloc] init];
    NSMutableDictionary *launched = [@{@"accountId": @"test_account_id",
                                       @"hashedEmailUserIdentityType": @"OTHER4"} mutableCopy];

    MPKitExecStatus *status = [kit didFinishLaunchingWithConfiguration:launched];
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);

    XCTAssertFalse(kit.started, @"Settings must be readable before the provider reports started.");
    XCTAssertEqualObjects([MPKitRokt getRoktHashedEmailUserIdentityType], @(MPIdentityOther4));

    launched[@"hashedEmailUserIdentityType"] = @"other2";
    XCTAssertEqualObjects([MPKitRokt getRoktHashedEmailUserIdentityType], @(MPIdentityOther4),
                          @"Mutating the caller's dictionary must not retarget the identity.");

    kit.configuration = @{@"accountId": @"test_account_id", @"hashedEmailUserIdentityType": @"other3"};
    XCTAssertEqualObjects([MPKitRokt getRoktHashedEmailUserIdentityType], @(MPIdentityOther3),
                          @"An explicit refresh must take effect.");

    [kit stop];
    XCTAssertNil([MPKitRokt getRoktHashedEmailUserIdentityType], @"stop must clear the settings.");

    method_setImplementation(initialize, originalInitialization);
    imp_removeBlock(initializationStub);
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

- (void)testMalformedSessionIsDiscardedAtObjectiveCBoundary {
    MPKitRokt *kit = [[MPKitRokt alloc] init];

    // The session reaches the kit as an untyped forwarded argument, so the wrong class can arrive
    // here. Swift will not catch it: an Objective-C object parameter crosses into Swift
    // unchecked, and the first property read raises -[NSString sessionId] instead of returning.
    id notASession = @"session-1";
    XCTAssertEqual([kit setSession:notASession].returnCode, MPKitReturnCodeSuccess);
}

@end
