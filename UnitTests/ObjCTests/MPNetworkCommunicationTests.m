#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Foundation/Foundation.h>
#import "MPNetworkCommunication.h"
#import "MPNetworkCommunication+Tests.h"
#import "MPApplication.h"
#import "MPUpload.h"
#import "MPConnector.h"
#import "MPBaseTestCase.h"
#import "mParticle.h"
#import "MPPersistenceController.h"
#import "MPURL.h"
#import "MPStateMachine.h"
#import "MParticleSwift.h"
#import "MPIConstants.h"

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readwrite) MPNetworkOptions *networkOptions;
- (void)logKitBatch:(NSString *)batch;

@end

@interface MPNetworkCommunication_PRIVATE ()

- (NSNumber *)maxAgeForCache:(nonnull NSString *)cache;
- (BOOL)performMessageUpload:(MPUpload *)upload;
- (BOOL)performAliasUpload:(MPUpload *)upload;
- (UIBackgroundTaskIdentifier)beginSafeBackgroundTaskWithExpirationHandler:(void(^_Nullable)(void))handler;
- (void)endSafeBackgroundTask:(UIBackgroundTaskIdentifier)taskId;
@property (nonatomic) BOOL identifying;

@end

@interface MPApplication_PRIVATE(Tests)
+ (void)setMockApplication:(id)mockApplication;
@end

@interface MPNetworkCommunicationTests : MPBaseTestCase

@end

Method originalMethod = nil; Method swizzleMethod = nil;

@implementation MPNetworkCommunicationTests

- (void)setUp {
    [super setUp];

    [MParticle sharedInstance].stateMachine.apiKey = @"unit_test_app_key";
    [MParticle sharedInstance].stateMachine.secret = @"unit_test_secret";

    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
}

- (void) swizzleInstanceMethodForInstancesOfClass:(Class)targetClass selector:(SEL)selector
{
    originalMethod = class_getInstanceMethod(targetClass, selector);
    swizzleMethod = class_getInstanceMethod([self class], selector);
    method_exchangeImplementations(originalMethod, swizzleMethod);
}

- (void) deswizzle
{
    method_exchangeImplementations(swizzleMethod, originalMethod);
    swizzleMethod = nil;
    originalMethod = nil;
}

- (NSDictionary *)infoDictionary {
    return @{@"CFBundleShortVersionString":@"1.2.3.4.5678 (bd12345ff)"};
}

- (void)testAudienceURL {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *audienceURL = [networkCommunication audienceURL].url;

    [self deswizzle];

    XCTAssert([audienceURL.absoluteString rangeOfString:@"/unit_test_app_key/audience?mpid=0"].location != NSNotFound);
}

- (void)testConfigURL {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *configURL = [networkCommunication configURL].url;

    [self deswizzle];

    XCTAssert([configURL.absoluteString rangeOfString:@"/config?av=1.2.3.4.5678%20(bd12345ff)"].location != NSNotFound);
    XCTAssert(![configURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testConfigURLWithOptions {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.configHost = @"config.mpproxy.example.com";
    [MParticle sharedInstance].networkOptions = options;
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *configURL = [networkCommunication configURL].url;

    [self deswizzle];

    XCTAssert([configURL.absoluteString rangeOfString:@"config.mpproxy.example.com/v4/"].location != NSNotFound);
    XCTAssert(![configURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testConfigURLWithOptionsAndOverride {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.configHost = @"config.mpproxy.example.com";
    options.overridesConfigSubdirectory = true;
    [MParticle sharedInstance].networkOptions = options;
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *configURL = [networkCommunication configURL].url;

    [self deswizzle];

    XCTAssert([configURL.absoluteString rangeOfString:@"config.mpproxy.example.com"].location != NSNotFound);
    XCTAssert([configURL.absoluteString rangeOfString:@"v4"].location == NSNotFound);
    XCTAssert(![configURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testModifyURL {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *modifyURL = [networkCommunication modifyURL].url;

    [self deswizzle];

    XCTAssert([modifyURL.absoluteString rangeOfString:@"https://identity.mparticle.com/v1/0/modify"].location != NSNotFound);
    XCTAssert([modifyURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testModifyURLWithOptions {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.identityHost = @"identity.mpproxy.example.com";
    [MParticle sharedInstance].networkOptions = options;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *modifyURL = [networkCommunication modifyURL].url;

    [self deswizzle];

    XCTAssert([modifyURL.absoluteString rangeOfString:@"https://identity.mpproxy.example.com/v1/0/modify"].location != NSNotFound);
    XCTAssert([modifyURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testModifyURLWithOptionsAndTrackingOverride {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.attAuthorizationStatus = @(MPATTAuthorizationStatusAuthorized);

    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.identityHost = @"identity.mpproxy.example.com";
    options.identityTrackingHost = @"identity-tracking.mpproxy.example.com";
    [MParticle sharedInstance].networkOptions = options;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *modifyURL = [networkCommunication modifyURL].url;

    [self deswizzle];

    XCTAssert([modifyURL.absoluteString rangeOfString:@"https://identity-tracking.mpproxy.example.com/v1/0/modify"].location != NSNotFound);
    XCTAssert([modifyURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testEventURLWithOptionsAndOverrideAndEventsOnlyAndTrackingHost {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.attAuthorizationStatus = @(MPATTAuthorizationStatusAuthorized);

    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    options.eventsTrackingHost = @"events-tracking.mpproxy.example.com";
    options.eventsOnly = true;
    [MParticle sharedInstance].networkOptions = options;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSURL *eventURL = [networkCommunication eventURLForUpload:upload].url;

    [self deswizzle];

    XCTAssert([eventURL.absoluteString rangeOfString:@"https://events-tracking.mpproxy.example.com/"].location != NSNotFound);
    XCTAssert([eventURL.absoluteString rangeOfString:@"v1"].location == NSNotFound);
    XCTAssert([eventURL.absoluteString rangeOfString:@"identity"].location == NSNotFound);
}


- (void)testAliasURL {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSURL *aliasURL = [networkCommunication aliasURLForUpload:upload].url;

    [self deswizzle];

    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://nativesdks.mparticle.com/v1/identity/"].location != NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithOptions {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    [MParticle sharedInstance].networkOptions = options;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSURL *aliasURL = [networkCommunication aliasURLForUpload:upload].url;

    [self deswizzle];

    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://events.mpproxy.example.com/v1/identity/"].location != NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithOptionsAndOverride {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    options.overridesEventsSubdirectory = true;
    [MParticle sharedInstance].networkOptions = options;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSURL *aliasURL = [networkCommunication aliasURLForUpload:upload].url;

    [self deswizzle];

    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://events.mpproxy.example.com/"].location != NSNotFound);
    XCTAssert([aliasURL.absoluteString rangeOfString:@"v1"].location == NSNotFound);
    XCTAssert([aliasURL.absoluteString rangeOfString:@"identity"].location == NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithEventsOnly {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    options.eventsOnly = true;
    [MParticle sharedInstance].networkOptions = options;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSURL *aliasURL = [networkCommunication aliasURLForUpload:upload].url;

    [self deswizzle];

    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://nativesdks.mparticle.com/v1/identity/"].location != NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithOptionsAndEventsOnly {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    options.aliasHost = @"alias.mpproxy.example.com";
    options.eventsOnly = true;
    [MParticle sharedInstance].networkOptions = options;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSURL *aliasURL = [networkCommunication aliasURLForUpload:upload].url;

    [self deswizzle];

    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://alias.mpproxy.example.com/v1/identity/"].location != NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithOptionsAndOverrideAndEventsOnly {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    options.aliasHost = @"alias.mpproxy.example.com";
    options.overridesAliasSubdirectory = true;
    options.eventsOnly = true;
    [MParticle sharedInstance].networkOptions = options;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSURL *aliasURL = [networkCommunication aliasURLForUpload:upload].url;

    [self deswizzle];

    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://alias.mpproxy.example.com/"].location != NSNotFound);
    XCTAssert([aliasURL.absoluteString rangeOfString:@"v1"].location == NSNotFound);
    XCTAssert([aliasURL.absoluteString rangeOfString:@"identity"].location == NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithOptionsAndOverrideAndEventsOnlyAndTrackingHost {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.attAuthorizationStatus = @(MPATTAuthorizationStatusAuthorized);

    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    options.eventsTrackingHost = @"events-tracking.mpproxy.example.com";
    options.aliasHost = @"alias.mpproxy.example.com";
    options.aliasTrackingHost = @"alias-tracking.mpproxy.example.com";
    options.overridesAliasSubdirectory = true;
    options.eventsOnly = true;
    [MParticle sharedInstance].networkOptions = options;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSURL *aliasURL = [networkCommunication aliasURLForUpload:upload].url;

    [self deswizzle];

    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://alias-tracking.mpproxy.example.com/"].location != NSNotFound);
    XCTAssert([aliasURL.absoluteString rangeOfString:@"v1"].location == NSNotFound);
    XCTAssert([aliasURL.absoluteString rangeOfString:@"identity"].location == NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testEmptyUploadsArray {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSArray *uploads = @[];
    __block BOOL handlerCalled = NO;
    [networkCommunication upload:uploads completionHandler:^{
        handlerCalled = YES;
    }];
    XCTAssertTrue(handlerCalled, @"Callbacks are expected in the case where uploads array is empty");
}

- (void)testUploadsArrayZipFail {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSArray *uploads = @[upload];
    id mockZip = OCMClassMock([MPZip_PRIVATE class]);
    OCMStub([mockZip compressedDataFromData:OCMOCK_ANY]).andReturn(nil);
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    [networkCommunication upload:uploads completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testUploadsArrayZipSucceedWithATTNotDetermined {
    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusNotDetermined withATTStatusTimestampMillis:nil];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{kMPDeviceInformationKey: @{}} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSArray *uploads = @[upload];
    id mockZip = OCMClassMock([MPZip_PRIVATE class]);
    [[mockZip expect] compressedDataFromData:[OCMArg checkWithBlock:^BOOL(id value) {
        NSMutableDictionary *uploadDict = [NSJSONSerialization JSONObjectWithData:value options:0 error:nil];
        return ([uploadDict[kMPDeviceInformationKey][kMPATT] isEqual: @"not_determined"]);
    }]];

    [networkCommunication upload:uploads completionHandler:^{
    }];
    [mockZip verifyWithDelay:2];
}

- (void)testUploadsArrayZipSucceedWithATTRestricted {
    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusRestricted withATTStatusTimestampMillis:nil];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{kMPDeviceInformationKey: @{}} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSArray *uploads = @[upload];
    id mockZip = OCMClassMock([MPZip_PRIVATE class]);
    [[mockZip expect] compressedDataFromData:[OCMArg checkWithBlock:^BOOL(id value) {
        NSMutableDictionary *uploadDict = [NSJSONSerialization JSONObjectWithData:value options:0 error:nil];
        return ([uploadDict[kMPDeviceInformationKey][kMPATT] isEqual: @"restricted"]);
    }]];

    [networkCommunication upload:uploads completionHandler:^{
    }];
    [mockZip verifyWithDelay:2];
}

- (void)testUploadsArrayZipSucceedWithATTDenied {
    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusDenied withATTStatusTimestampMillis:nil];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{kMPDeviceInformationKey: @{}} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSArray *uploads = @[upload];
    id mockZip = OCMClassMock([MPZip_PRIVATE class]);
    [[mockZip expect] compressedDataFromData:[OCMArg checkWithBlock:^BOOL(id value) {
        NSMutableDictionary *uploadDict = [NSJSONSerialization JSONObjectWithData:value options:0 error:nil];
        return ([uploadDict[kMPDeviceInformationKey][kMPATT] isEqual: @"denied"]);
    }]];

    [networkCommunication upload:uploads completionHandler:^{
    }];
    [mockZip verifyWithDelay:2];
}

- (void)testUploadsArrayZipSucceedWithATTAuthorized {
    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusAuthorized withATTStatusTimestampMillis:nil];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{kMPDeviceInformationKey: @{}} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    NSArray *uploads = @[upload];
    id mockZip = OCMClassMock([MPZip_PRIVATE class]);
    [[mockZip expect] compressedDataFromData:[OCMArg checkWithBlock:^BOOL(id value) {
        NSMutableDictionary *uploadDict = [NSJSONSerialization JSONObjectWithData:value options:0 error:nil];
        return ([uploadDict[kMPDeviceInformationKey][kMPATT] isEqual: @"authorized"]);
    }]];

    [networkCommunication upload:uploads completionHandler:^{
    }];
    [mockZip verifyWithDelay:2];
}

- (void)testShouldStopEvents {
    [self shouldStopEvents:0 shouldStop:YES];
    [self shouldStopEvents:999 shouldStop:YES];
    [self shouldStopEvents:-999 shouldStop:YES];
    [self shouldStopEvents:-1 shouldStop:YES];
    [self shouldStopEvents:200 shouldStop:NO];
    [self shouldStopEvents:201 shouldStop:NO];
    [self shouldStopEvents:202 shouldStop:NO];
    [self shouldStopEvents:400 shouldStop:NO];
    [self shouldStopEvents:401 shouldStop:NO];
    [self shouldStopEvents:429 shouldStop:YES];
    [self shouldStopEvents:500 shouldStop:YES];
    [self shouldStopEvents:503 shouldStop:YES];
}

- (void)shouldStopEvents:(int)returnCode shouldStop:(BOOL)shouldStop {
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(returnCode)] statusCode];

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;

    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromPostRequestToURL:OCMOCK_ANY message:OCMOCK_ANY serializedParams:OCMOCK_ANY secret:OCMOCK_ANY];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];

    MPUpload *messageUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];

    BOOL actualShouldStop = [networkCommunication performMessageUpload:messageUpload];
    XCTAssertEqual(shouldStop, actualShouldStop, @"Return code assertion: %d", returnCode);
}

- (void)testShouldStopAlias {
    [self shouldStopAlias:0 shouldStop:YES];
    [self shouldStopAlias:999 shouldStop:YES];
    [self shouldStopAlias:-999 shouldStop:YES];
    [self shouldStopAlias:-1 shouldStop:YES];
    [self shouldStopAlias:200 shouldStop:NO];
    [self shouldStopAlias:201 shouldStop:NO];
    [self shouldStopAlias:202 shouldStop:NO];
    [self shouldStopAlias:400 shouldStop:NO];
    [self shouldStopAlias:401 shouldStop:NO];
    [self shouldStopAlias:429 shouldStop:YES];
    [self shouldStopAlias:500 shouldStop:YES];
    [self shouldStopAlias:503 shouldStop:YES];
}

- (void)shouldStopAlias:(int)returnCode shouldStop:(BOOL)shouldStop {
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(returnCode)] statusCode];

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;

    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromPostRequestToURL:OCMOCK_ANY message:OCMOCK_ANY serializedParams:OCMOCK_ANY secret:OCMOCK_ANY];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];

    MPUpload *aliasUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    aliasUpload.uploadType = MPUploadTypeAlias;

    BOOL actualShouldStop = [networkCommunication performAliasUpload:aliasUpload];
    XCTAssertEqual(shouldStop, actualShouldStop, @"Return code assertion: %d", returnCode);
}

- (void)testOfflineUpload {
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(0)] statusCode];

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;

    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromPostRequestToURL:OCMOCK_ANY message:OCMOCK_ANY serializedParams:OCMOCK_ANY secret:OCMOCK_ANY];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];

    id mockPersistenceController = OCMClassMock([MPPersistenceController_PRIVATE class]);
    [[mockPersistenceController reject] deleteUpload:OCMOCK_ANY];

    MParticle *instance = [MParticle sharedInstance];
    instance.persistenceController = mockPersistenceController;

    MPUpload *eventUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    MPUpload *aliasUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    aliasUpload.uploadType = MPUploadTypeAlias;

    NSArray *uploads = @[eventUpload, aliasUpload];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    [networkCommunication upload:uploads completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testUploadSuccessDeletion {
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(202)] statusCode];

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;

    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromPostRequestToURL:OCMOCK_ANY message:OCMOCK_ANY serializedParams:OCMOCK_ANY secret:OCMOCK_ANY];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];

    id mockPersistenceController = OCMClassMock([MPPersistenceController_PRIVATE class]);

    MPUpload *eventUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{kMPDeviceInformationKey: @{}} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    MPUpload *aliasUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    aliasUpload.uploadType = MPUploadTypeAlias;

    [[mockPersistenceController expect] deleteUpload:eventUpload];
    [[mockPersistenceController expect] deleteUpload:aliasUpload];

    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [(MParticle *)[mockInstance expect] logKitBatch:[OCMArg checkWithBlock:^BOOL(id obj) {
        if ([obj isEqual:[[NSString alloc] initWithData:eventUpload.uploadData encoding:NSUTF8StringEncoding]] && ![obj isEqual:[[NSString alloc] initWithData:aliasUpload.uploadData encoding:NSUTF8StringEncoding]]) {
            return YES;
        }
        return NO;
    }]];
    ((MParticle *)mockInstance).persistenceController = mockPersistenceController;

    NSArray *uploads = @[eventUpload, aliasUpload];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    [networkCommunication upload:uploads completionHandler:^{
        [mockInstance verify];
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testUploadInvalidDeletion {
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(400)] statusCode];

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;

    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromPostRequestToURL:OCMOCK_ANY message:OCMOCK_ANY serializedParams:OCMOCK_ANY secret:OCMOCK_ANY];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];

    id mockPersistenceController = OCMClassMock([MPPersistenceController_PRIVATE class]);

    MPUpload *eventUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    MPUpload *aliasUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    aliasUpload.uploadType = MPUploadTypeAlias;

    [[mockPersistenceController expect] deleteUpload:eventUpload];
    [[mockPersistenceController expect] deleteUpload:aliasUpload];

    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [(MParticle *)[mockInstance expect] logKitBatch:[OCMArg checkWithBlock:^BOOL(id obj) {
        return NO; // reject
    }]];
    ((MParticle *)mockInstance).persistenceController = mockPersistenceController;

    NSArray *uploads = @[eventUpload, aliasUpload];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    [networkCommunication upload:uploads completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testRequestConfigWithDefaultMaxAge {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSNumber *configProvisioned = userDefaults[kMPConfigProvisionedTimestampKey];
    NSNumber *maxAge = userDefaults[kMPConfigMaxAgeHeaderKey];

    XCTAssertEqualObjects(configProvisioned, nil);
    XCTAssertEqualObjects(maxAge, nil);

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *configURL = [networkCommunication configURL].url;

    MPConnector *connector = [[MPConnector alloc] init];
    id mockConnector = OCMPartialMock(connector);

    NSDictionary<NSString *, NSString *> *httpHeaders = @{@"Age": @"0",
                                                          kMPHTTPETagHeaderKey: @"242f22f24c224"
                                                          };
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };

    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };

    NSArray *kitConfigs = @[configuration1, configuration2];

    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPMessageTypeKey:kMPMessageTypeConfig,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    NSError *error;

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:configURL statusCode:HTTPStatusCodeSuccess HTTPVersion:@"" headerFields:httpHeaders];
    response.httpResponse = httpResponse;
    response.data = [NSJSONSerialization dataWithJSONObject:responseConfiguration
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];

    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:[networkCommunication configURL]];

    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {
        XCTAssert(success);
    }];

    configProvisioned = userDefaults[kMPConfigProvisionedTimestampKey];
    maxAge = userDefaults[kMPConfigMaxAgeHeaderKey];

    XCTAssertNotNil(configProvisioned);
    XCTAssertNil(maxAge);
}

- (void)testRequestConfigWithManualMaxAge {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    userDefaults[kMPConfigProvisionedTimestampKey] = @5555;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *configURL = [networkCommunication configURL].url;

    MPConnector *connector = [[MPConnector alloc] init];
    id mockConnector = OCMPartialMock(connector);

    NSDictionary<NSString *, NSString *> *httpHeaders = @{@"Age": @"0",
                                                          kMPHTTPETagHeaderKey: @"242f22f24c224",
                                                          kMPHTTPCacheControlHeaderKey: @"max-age=43200"
                                                          };
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };

    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };

    NSArray *kitConfigs = @[configuration1, configuration2];

    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPMessageTypeKey:kMPMessageTypeConfig,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    NSError *error;

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:configURL statusCode:HTTPStatusCodeSuccess HTTPVersion:@"" headerFields:httpHeaders];
    response.httpResponse = httpResponse;
    response.data = [NSJSONSerialization dataWithJSONObject:responseConfiguration
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];

    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:[networkCommunication configURL]];

    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {
        XCTAssert(success);
    }];

    NSNumber *maxAge = userDefaults[kMPConfigMaxAgeHeaderKey];

    XCTAssertEqualObjects(maxAge, @43200);
}

- (void)testRequestConfigWithManualMaxAgeAndInitialAge {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *configURL = [networkCommunication configURL].url;

    MPConnector *connector = [[MPConnector alloc] init];
    id mockConnector = OCMPartialMock(connector);

    NSDictionary<NSString *, NSString *> *httpHeaders = @{@"age": @"4000",
                                                          kMPMessageTypeKey:kMPMessageTypeConfig,
                                                          kMPHTTPETagHeaderKey: @"242f22f24c224",
                                                          kMPHTTPCacheControlHeaderKey: @"max-age=43200"
                                                          };

    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };

    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };

    NSArray *kitConfigs = @[configuration1, configuration2];

    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPMessageTypeKey:kMPMessageTypeConfig,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    NSError *error;

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:configURL statusCode:HTTPStatusCodeSuccess HTTPVersion:@"" headerFields:httpHeaders];
    response.httpResponse = httpResponse;
    response.data = [NSJSONSerialization dataWithJSONObject:responseConfiguration
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];


    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:[networkCommunication configURL]];

    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {
        XCTAssert(success);
    }];

    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    [userDefaults synchronize];

    NSNumber *provisionedInterval = userDefaults[kMPConfigProvisionedTimestampKey];
    int approximateAge = ([[NSDate date] timeIntervalSince1970] - [provisionedInterval integerValue]);

    XCTAssertLessThanOrEqual(4000, approximateAge);
    XCTAssertLessThan(approximateAge, 4200);
}

- (void)testRequestConfigWithManualMaxAgeOverMaxAllowed {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    userDefaults[kMPConfigProvisionedTimestampKey] = @5555;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *configURL = [networkCommunication configURL].url;

    MPConnector *connector = [[MPConnector alloc] init];
    id mockConnector = OCMPartialMock(connector);

    NSDictionary<NSString *, NSString *> *httpHeaders = @{@"Age": @"0",
                                                          kMPMessageTypeKey:kMPMessageTypeConfig,
                                                          kMPHTTPETagHeaderKey: @"242f22f24c224",
                                                          kMPHTTPCacheControlHeaderKey: @"max-age=172800"
                                                          };
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };

    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };

    NSArray *kitConfigs = @[configuration1, configuration2];

    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPMessageTypeKey:kMPMessageTypeConfig,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    NSError *error;

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:configURL statusCode:HTTPStatusCodeSuccess HTTPVersion:@"" headerFields:httpHeaders];
    response.httpResponse = httpResponse;
    response.data = [NSJSONSerialization dataWithJSONObject:responseConfiguration
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];

    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:[networkCommunication configURL]];

    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {
        XCTAssert(success);
    }];

    NSNumber *maxAge = userDefaults[kMPConfigMaxAgeHeaderKey];
    NSNumber *maxExpiration = @(60*60*24.0);

    XCTAssertEqualObjects(maxAge, maxExpiration);
}

- (void)testRequestConfigWithComplexCacheControlHeader {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    userDefaults[kMPConfigProvisionedTimestampKey] = @5555;

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    NSURL *configURL = [networkCommunication configURL].url;

    MPConnector *connector = [[MPConnector alloc] init];
    id mockConnector = OCMPartialMock(connector);

    NSDictionary<NSString *, NSString *> *httpHeaders = @{@"Age": @"0",
                                                          kMPMessageTypeKey:kMPMessageTypeConfig,
                                                          kMPHTTPETagHeaderKey: @"242f22f24c224",
                                                          kMPHTTPCacheControlHeaderKey: @"min-fresh=0, max-age=43200, no-transform"
                                                          };
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };

    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };

    NSArray *kitConfigs = @[configuration1, configuration2];

    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPMessageTypeKey:kMPMessageTypeConfig,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    NSError *error;

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:configURL statusCode:HTTPStatusCodeSuccess HTTPVersion:@"" headerFields:httpHeaders];
    response.httpResponse = httpResponse;
    response.data = [NSJSONSerialization dataWithJSONObject:responseConfiguration
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];

    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:[networkCommunication configURL]];

    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {
        XCTAssert(success);
    }];

    NSNumber *maxAge = userDefaults[kMPConfigMaxAgeHeaderKey];

    XCTAssertEqualObjects(maxAge, @43200);
}

- (void)testMaxAgeForCacheEmptyString {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];

    NSString *test1 = @"";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test1], nil);
}

- (void)testMaxAgeForCacheSimple {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];

    NSString *test2 = @"max-age=12";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test2], @12);
}

- (void)testMaxAgeForCacheMultiValue1 {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];

    NSString *test3 = @"max-age=13, max-stale=7";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test3], @13);
}

- (void)testMaxAgeForCacheMultiValue2 {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];

    NSString *test4 = @"max-stale=34, max-age=14";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test4], @14);
}

- (void)testMaxAgeForCacheMultiValue3 {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];

    NSString *test4 = @"max-stale=33434344, max-age=15, min-fresh=3553553";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test4], @15);
}

- (void)testMaxAgeForCacheCapitalization {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];

    NSString *test5 = @"max-stale=34, MAX-age=16, min-fresh=3553553";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test5], @16);
}

- (void)testPodURLRoutingAndTrackingURL {
    // NOTE: All keys are fake and randomly generated just for this test
    NSArray *testKeys = @[
        @[@"4u8wmsug0pf5tbf58lgjiouma3qukrgbu", @"nativesdks.us1.mparticle.com", @"identity.us1.mparticle.com", @"tracking-nativesdks.us1.mparticle.com", @"tracking-identity.us1.mparticle.com"],
        @[@"us1-1vc4gbp24cdtx6e31s58icnymzy83f1uf", @"nativesdks.us1.mparticle.com", @"identity.us1.mparticle.com", @"tracking-nativesdks.us1.mparticle.com", @"tracking-identity.us1.mparticle.com"],
        @[@"us2-v2p8lr3w2g90vtpaumbq21zy05cl50qm3", @"nativesdks.us2.mparticle.com", @"identity.us2.mparticle.com", @"tracking-nativesdks.us2.mparticle.com", @"tracking-identity.us2.mparticle.com"],
        @[@"eu1-bkabfno0b8zpv5bwi2zm2mfa1kfml19al", @"nativesdks.eu1.mparticle.com", @"identity.eu1.mparticle.com", @"tracking-nativesdks.eu1.mparticle.com", @"tracking-identity.eu1.mparticle.com"],
        @[@"au1-iermuj83dbeoshm0n32f10feotclq6i4a", @"nativesdks.au1.mparticle.com", @"identity.au1.mparticle.com", @"tracking-nativesdks.au1.mparticle.com", @"tracking-identity.au1.mparticle.com"],
        @[@"st1-k77ivhkbbqf4ce0s3y12zpcthyn1ixfyu", @"nativesdks.st1.mparticle.com", @"identity.st1.mparticle.com", @"tracking-nativesdks.st1.mparticle.com", @"tracking-identity.st1.mparticle.com"],
        @[@"us3-w1y2y8yj8q58d5bx9u2dvtxzl4cpa7cuf", @"nativesdks.us3.mparticle.com", @"identity.us3.mparticle.com", @"tracking-nativesdks.us3.mparticle.com", @"tracking-identity.us3.mparticle.com"]
    ];
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    NSString *oldEventHost = @"nativesdks.mparticle.com";
    NSString *oldIdentityHost = @"identity.mparticle.com";

    stateMachine.enableDirectRouting = NO;
    stateMachine.attAuthorizationStatus = @(MPATTAuthorizationStatusNotDetermined);
    for (NSArray *test in testKeys) {
        NSString *key = test[0];
        stateMachine.apiKey = key;

        XCTAssertEqualObjects(oldEventHost, [networkCommunication defaultEventHost]);
        XCTAssertEqualObjects(oldIdentityHost, [networkCommunication defaultIdentityHost]);
    }

    NSString *newEventHost = @"tracking-nativesdks.mparticle.com";
    NSString *newIdentityHost = @"tracking-identity.mparticle.com";
    stateMachine.attAuthorizationStatus = @(MPATTAuthorizationStatusAuthorized);
    for (NSArray *test in testKeys) {
        NSString *key = test[0];
        stateMachine.apiKey = key;

        XCTAssertEqualObjects(newEventHost, [networkCommunication defaultEventHost]);
        XCTAssertEqualObjects(newIdentityHost, [networkCommunication defaultIdentityHost]);
    }

    stateMachine.enableDirectRouting = YES;
    stateMachine.attAuthorizationStatus = @(MPATTAuthorizationStatusNotDetermined);
    for (NSArray *test in testKeys) {
        NSString *key = test[0];
        stateMachine.apiKey = key;
        NSString *eventHost = test[1];
        NSString *identityHost = test[2];

        XCTAssertEqualObjects(eventHost, [networkCommunication defaultEventHost]);
        XCTAssertEqualObjects(identityHost, [networkCommunication defaultIdentityHost]);
    }

    stateMachine.attAuthorizationStatus = @(MPATTAuthorizationStatusAuthorized);
    for (NSArray *test in testKeys) {
        NSString *key = test[0];
        stateMachine.apiKey = key;
        NSString *eventHost = test[3];
        NSString *identityHost = test[4];

        XCTAssertEqualObjects(eventHost, [networkCommunication defaultEventHost]);
        XCTAssertEqualObjects(identityHost, [networkCommunication defaultIdentityHost]);
    }
}

#pragma mark - Background Task Tests

- (void)testBeginSafeBackgroundTaskDispatchesToMainThread {
    __block BOOL beginCalledOnMainThread = NO;

    id mockApplication = OCMClassMock([UIApplication class]);
    OCMStub([mockApplication beginBackgroundTaskWithExpirationHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        beginCalledOnMainThread = [NSThread isMainThread];
        UIBackgroundTaskIdentifier taskId = 42;
        [invocation setReturnValue:&taskId];
    });

    [MPApplication_PRIVATE setMockApplication:mockApplication];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Background queue completed"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        MPNetworkCommunication_PRIVATE *nc = [[MPNetworkCommunication_PRIVATE alloc] init];
        UIBackgroundTaskIdentifier taskId = [nc beginSafeBackgroundTaskWithExpirationHandler:nil];
        XCTAssertEqual(taskId, (UIBackgroundTaskIdentifier)42);
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:5.0];

    XCTAssertTrue(beginCalledOnMainThread, @"beginBackgroundTaskWithExpirationHandler: must be called on the main thread");

    [MPApplication_PRIVATE setMockApplication:nil];
}

- (void)testEndSafeBackgroundTaskDispatchesToMainThread {
    __block BOOL endCalledOnMainThread = NO;

    id mockApplication = OCMClassMock([UIApplication class]);
    OCMStub([mockApplication endBackgroundTask:(UIBackgroundTaskIdentifier)42]).andDo(^(NSInvocation *invocation) {
        endCalledOnMainThread = [NSThread isMainThread];
    });

    [MPApplication_PRIVATE setMockApplication:mockApplication];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Background queue completed"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        MPNetworkCommunication_PRIVATE *nc = [[MPNetworkCommunication_PRIVATE alloc] init];
        [nc endSafeBackgroundTask:42];
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:5.0];

    // Give main queue time to process the async dispatch
    XCTestExpectation *mainQueueDrained = [self expectationWithDescription:@"Main queue drained"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainQueueDrained fulfill];
    });
    [self waitForExpectations:@[mainQueueDrained] timeout:2.0];

    XCTAssertTrue(endCalledOnMainThread, @"endBackgroundTask: must be called on the main thread");

    [MPApplication_PRIVATE setMockApplication:nil];
}

- (void)testRequestConfigCallsBeginAndEndBackgroundTask {
    __block BOOL beginCalled = NO;
    __block BOOL endCalled = NO;

    id mockApplication = OCMClassMock([UIApplication class]);
    OCMStub([mockApplication beginBackgroundTaskWithExpirationHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        beginCalled = YES;
        UIBackgroundTaskIdentifier taskId = 42;
        [invocation setReturnValue:&taskId];
    });
    OCMStub([mockApplication endBackgroundTask:(UIBackgroundTaskIdentifier)42]).andDo(^(NSInvocation *invocation) {
        endCalled = YES;
    });

    [MPApplication_PRIVATE setMockApplication:mockApplication];

    int statusCode = 200;
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
    [[[urlResponseMock stub] andReturn:@{}] allHeaderFields];

    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;

    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:OCMOCK_ANY];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];

    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {}];

    // Give main queue time to process async endBackgroundTask dispatch
    XCTestExpectation *mainQueueDrained = [self expectationWithDescription:@"Main queue drained"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [mainQueueDrained fulfill];
    });
    [self waitForExpectations:@[mainQueueDrained] timeout:2.0];

    XCTAssertTrue(beginCalled, @"beginBackgroundTaskWithExpirationHandler: should be called during config request");
    XCTAssertTrue(endCalled, @"endBackgroundTask: should be called after config request completes");

    [MPApplication_PRIVATE setMockApplication:nil];
}

- (void)testExpirationHandlerEndsTask {
    __block void (^capturedExpirationHandler)(void) = nil;

    id mockApplication = OCMClassMock([UIApplication class]);
    OCMStub([mockApplication beginBackgroundTaskWithExpirationHandler:([OCMArg checkWithBlock:^BOOL(id obj) {
        capturedExpirationHandler = [obj copy];
        return YES;
    }])]).andDo(^(NSInvocation *invocation) {
        UIBackgroundTaskIdentifier taskId = 42;
        [invocation setReturnValue:&taskId];
    });
    OCMStub([mockApplication endBackgroundTask:(UIBackgroundTaskIdentifier)42]);

    [MPApplication_PRIVATE setMockApplication:mockApplication];

    MPNetworkCommunication_PRIVATE *nc = [[MPNetworkCommunication_PRIVATE alloc] init];
    [nc beginSafeBackgroundTaskWithExpirationHandler:nil];

    XCTAssertNotNil(capturedExpirationHandler, @"Expiration handler should have been captured");

    capturedExpirationHandler();

    OCMVerify([mockApplication endBackgroundTask:(UIBackgroundTaskIdentifier)42]);

    [MPApplication_PRIVATE setMockApplication:nil];
}

- (void)testIdentityExpirationHandlerSetsIdentifyingNO {
    __block void (^capturedExpirationHandler)(void) = nil;

    id mockApplication = OCMClassMock([UIApplication class]);
    OCMStub([mockApplication beginBackgroundTaskWithExpirationHandler:([OCMArg checkWithBlock:^BOOL(id obj) {
        capturedExpirationHandler = [obj copy];
        return YES;
    }])]).andDo(^(NSInvocation *invocation) {
        UIBackgroundTaskIdentifier taskId = 42;
        [invocation setReturnValue:&taskId];
    });
    OCMStub([mockApplication endBackgroundTask:(UIBackgroundTaskIdentifier)42]);

    [MPApplication_PRIVATE setMockApplication:mockApplication];

    MPNetworkCommunication_PRIVATE *nc = [[MPNetworkCommunication_PRIVATE alloc] init];
    nc.identifying = YES;

    [nc beginSafeBackgroundTaskWithExpirationHandler:^{
        nc.identifying = NO;
    }];

    XCTAssertNotNil(capturedExpirationHandler, @"Expiration handler should have been captured");
    XCTAssertTrue(nc.identifying, @"identifying should still be YES before expiration");

    capturedExpirationHandler();

    XCTAssertFalse(nc.identifying, @"identifying should be NO after expiration handler fires");
    OCMVerify([mockApplication endBackgroundTask:(UIBackgroundTaskIdentifier)42]);

    [MPApplication_PRIVATE setMockApplication:nil];
}

- (void)testBackgroundTaskSkippedInAppExtension {
    id mockStateMachine = OCMClassMock([MPStateMachine_PRIVATE class]);
    OCMStub([mockStateMachine isAppExtension]).andReturn(YES);

    id mockApplication = OCMClassMock([UIApplication class]);
    [[mockApplication reject] beginBackgroundTaskWithExpirationHandler:OCMOCK_ANY];

    [MPApplication_PRIVATE setMockApplication:mockApplication];

    MPNetworkCommunication_PRIVATE *nc = [[MPNetworkCommunication_PRIVATE alloc] init];
    UIBackgroundTaskIdentifier taskId = [nc beginSafeBackgroundTaskWithExpirationHandler:nil];

    XCTAssertEqual(taskId, UIBackgroundTaskInvalid, @"Should return UIBackgroundTaskInvalid in app extension");
    OCMVerifyAll(mockApplication);

    [mockStateMachine stopMocking];
    [MPApplication_PRIVATE setMockApplication:nil];
}

@end
