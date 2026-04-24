#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
@import Rokt_Widget;
@import RoktContracts;
@import mParticle_Rokt;

static NSInteger const kMPRoktKitCode = 181;
static NSString * const kMPRoktHashedEmailUserIdentityType = @"hashedEmailUserIdentityType";

@interface MPKitRokt ()

- (MPKitExecStatus *)selectPlacementsWithIdentifier:(NSString * _Nullable)identifier
                                attributes:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes
                             embeddedViews:(NSDictionary<NSString *, RoktEmbeddedView *> * _Nullable)embeddedViews
                                    config:(RoktConfig * _Nullable)config
                                   onEvent:(void (^ _Nullable)(RoktEvent * _Nonnull))onEvent
                              filteredUser:(FilteredMParticleUser * _Nonnull)filteredUser
                                   options:(RoktPlacementOptions * _Nullable)options;
- (MPKitExecStatus *)setWrapperSdk:(MPWrapperSdk)wrapperSdk version:(nonnull NSString *)wrapperSdkVersion;

- (MPKitExecStatus *)purchaseFinalized:(NSString *)placementId
                         catalogItemId:(NSString *)catalogItemId
                               success:(NSNumber *)success;

- (MPKitExecStatus *)setSessionId:(NSString *)sessionId;
- (NSString *)getSessionId;

- (NSDictionary<NSString *, RoktEmbeddedView *> * _Nullable)confirmEmbeddedViews:(NSDictionary<NSString *, RoktEmbeddedView *> * _Nullable)embeddedViews;

+ (void)addIdentityAttributes:(NSMutableDictionary<NSString *, NSString *> * _Nullable)attributes filteredUser:(FilteredMParticleUser * _Nonnull)filteredUser;

+ (void)handleHashedEmail:(NSMutableDictionary<NSString *, NSString *> * _Nullable)attributes;

+ (NSDictionary *)getKitConfig;

+ (NSNumber *)getRoktHashedEmailUserIdentityType;

+ (NSDictionary<NSString *, NSString *> *)transformValuesToString:(NSDictionary<NSString *, id> * _Nullable)originalDictionary;

+ (void)logSelectPlacementEvent:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes;

+ (void)logSelectShoppableAdsEvent:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes;

- (MPKitExecStatus *)registerPaymentExtension:(id<RoktPaymentExtension>)paymentExtension;

- (BOOL)handleURLCallback:(NSURL *)url;

- (MPKitExecStatus *)selectShoppableAdsWithIdentifier:(NSString *)identifier
                                           attributes:(NSDictionary<NSString *, NSString *> *)attributes
                                               config:(RoktConfig *)config
                                              onEvent:(void (^ _Nullable)(RoktEvent * _Nonnull))onEvent
                                         filteredUser:(FilteredMParticleUser *)filteredUser;

+ (NSDictionary<NSString *, NSString *> *)mapAttributes:(NSDictionary<NSString *, NSString *> * _Nullable)attributes filteredUser:(FilteredMParticleUser * _Nonnull)filteredUser;

+ (NSDictionary<NSString *, NSString *> *)confirmSandboxAttribute:(NSDictionary<NSString *, NSString *> * _Nullable)attributes;

+ (RoktLogLevel)roktLogLevelFromMParticleLogLevel:(MPILogLevel)mpLogLevel;

+ (void)applyMParticleLogLevel;

@end

@interface mParticle_RoktTests : XCTestCase

@property (nonatomic, strong) MPKitRokt *kitInstance;
@property (nonatomic, strong) NSDictionary *configuration;

@end

@implementation mParticle_RoktTests

- (void)setUp {
    [super setUp];
    self.kitInstance = [[MPKitRokt alloc] init];
    self.configuration = @{@"accountId": @"test_account_id"};
}

- (void)tearDown {
    self.kitInstance = nil;
    self.configuration = nil;
    [super tearDown];
}

- (void)testKitCode {
    XCTAssertEqualObjects([MPKitRokt kitCode], @181);
}

- (void)testStarted {
    XCTAssertFalse(self.kitInstance.started);
    
    [self.kitInstance didFinishLaunchingWithConfiguration:self.configuration];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertTrue(self.kitInstance.started);
    });
}

- (void)testDidFinishLaunchingWithConfiguration_Success {
    MPKitExecStatus *status = [self.kitInstance didFinishLaunchingWithConfiguration:self.configuration];
    
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
}

- (void)testDidFinishLaunchingWithConfiguration_MissingAccountId {
    MPKitExecStatus *status = [self.kitInstance didFinishLaunchingWithConfiguration:@{}];
    
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeRequirementsNotMet);
}

- (void)testConfirmEmbeddedViews_ValidEmbeddedViews {
    RoktEmbeddedView *view = [[RoktEmbeddedView alloc] initWithFrame:CGRectZero];
    NSDictionary *embeddedViews = @{@"placement1": view};
    
    NSDictionary *result = [self.kitInstance confirmEmbeddedViews:embeddedViews];
    
    XCTAssertEqual(result.count, 1);
    XCTAssertEqualObjects(result[@"placement1"], view);
}

- (void)testConfirmEmbeddedViews_InvalidEmbeddedViews {
    NSDictionary *embeddedViews = @{@"placement1": @"invalid"};
    
    NSDictionary *result = [self.kitInstance confirmEmbeddedViews:embeddedViews];
    
    XCTAssertEqual(result.count, 0);
}

- (void)testSetUserIdentity_Email {
    MPKitExecStatus *status = [self.kitInstance setUserIdentity:@"test@example.com" identityType:MPUserIdentityEmail];
    
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
}

- (void)testSetUserIdentity_CustomerId {
    MPKitExecStatus *status = [self.kitInstance setUserIdentity:@"12345" identityType:MPUserIdentityCustomerId];
    
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
}

- (void)testSetUserIdentity_UnsupportedType {
    MPKitExecStatus *status = [self.kitInstance setUserIdentity:@"test" identityType:MPUserIdentityFacebook];
    
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeUnavailable);
}

- (void)testLogBaseEvent {
    MPEvent *event = [[MPEvent alloc] initWithName:@"Test Event" type:MPEventTypeOther];
    
    MPKitExecStatus *status = [self.kitInstance logBaseEvent:event];
    
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
}

- (void)testExecuteWithIdentifier {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    RoktEmbeddedView *view = [[RoktEmbeddedView alloc] initWithFrame:CGRectZero];
    NSString *identifier = @"TestView";
    NSDictionary *embeddedViews = @{@"placement1": view};
    NSDictionary *attributes = @{@"attr1": @"value1", @"sandbox": @"false"};
    FilteredMParticleUser *user = [[FilteredMParticleUser alloc] init];

    // Expect Rokt selectPlacements call and verify sandbox attribute is preserved
    // Note: attributes may include additional device identifiers (idfa, idfv, mpid)
    OCMExpect([mockRoktSDK selectPlacementsWithIdentifier:identifier
                                               attributes:[OCMArg checkWithBlock:^BOOL(NSDictionary *attrs) {
                                                   return [attrs[@"sandbox"] isEqualToString:@"false"];
                                               }]
                                               placements:OCMOCK_ANY
                                                   config:nil
                                         placementOptions:OCMOCK_ANY
                                                  onEvent:OCMOCK_ANY]);
    
    MPKitExecStatus *status = [self.kitInstance selectPlacementsWithIdentifier:identifier
                                                         attributes:attributes
                                                      embeddedViews:embeddedViews
                                                             config:nil
                                                          onEvent:nil
                                                       filteredUser:user
                                                            options:nil];

    // Verify
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);
}

- (void)testExecuteSandboxDetection {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    RoktEmbeddedView *view = [[RoktEmbeddedView alloc] initWithFrame:CGRectZero];
    NSString *identifier = @"TestView";
    NSDictionary *embeddedViews = @{@"placement1": view};
    NSDictionary *attributes = @{@"attr1": @"value1"};  // No sandbox attribute provided
    FilteredMParticleUser *user = [[FilteredMParticleUser alloc] init];

    // Expect Rokt selectPlacements call and verify sandbox attribute is auto-detected
    // In development environment, sandbox should be "true"
    // Note: attributes may include additional device identifiers (idfa, idfv, mpid)
    OCMExpect([mockRoktSDK selectPlacementsWithIdentifier:identifier
                                               attributes:[OCMArg checkWithBlock:^BOOL(NSDictionary *attrs) {
                                                   return attrs[@"sandbox"] != nil;  // Sandbox should be auto-added
                                               }]
                                               placements:OCMOCK_ANY
                                                   config:nil
                                         placementOptions:OCMOCK_ANY
                                                  onEvent:OCMOCK_ANY]);
    
    MPKitExecStatus *status = [self.kitInstance selectPlacementsWithIdentifier:identifier
                                                         attributes:attributes
                                                      embeddedViews:embeddedViews
                                                             config:nil
                                                          onEvent:nil
                                                       filteredUser:user
                                                            options:nil];

    // Verify
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);
}

- (void)testExecuteWithIdentifierWithOptions {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    RoktEmbeddedView *view = [[RoktEmbeddedView alloc] initWithFrame:CGRectZero];
    NSString *identifier = @"TestView";
    NSDictionary *embeddedViews = @{@"placement1": view};
    NSDictionary *attributes = @{@"attr1": @"value1", @"sandbox": @"false"};
    FilteredMParticleUser *user = [[FilteredMParticleUser alloc] init];

    // Create placement options with a custom timestamp value
    RoktPlacementOptions *options = [[RoktPlacementOptions alloc] initWithTimestamp:42];

    // Expect Rokt selectPlacements call and verify placementOptions carries the jointSdkSelectPlacements value
    OCMExpect([mockRoktSDK selectPlacementsWithIdentifier:identifier
                                               attributes:OCMOCK_ANY
                                               placements:OCMOCK_ANY
                                                   config:nil
                                         placementOptions:[OCMArg checkWithBlock:^BOOL(RoktPlacementOptions *opts) {
                                             return opts != nil;
                                         }]
                                                  onEvent:OCMOCK_ANY]);

    MPKitExecStatus *status = [self.kitInstance selectPlacementsWithIdentifier:identifier
                                                         attributes:attributes
                                                      embeddedViews:embeddedViews
                                                             config:nil
                                                          onEvent:nil
                                                       filteredUser:user
                                                            options:options];

    // Verify
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);
}

- (void)testExecuteWithIdentifierNilOptionsCreatesDefaultPlacementOptions {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    NSString *identifier = @"TestView";
    NSDictionary *attributes = @{@"attr1": @"value1", @"sandbox": @"false"};
    FilteredMParticleUser *user = [[FilteredMParticleUser alloc] init];

    // When options is nil, a default PlacementOptions with jointSdkSelectPlacements=0 should be created
    OCMExpect([mockRoktSDK selectPlacementsWithIdentifier:identifier
                                               attributes:OCMOCK_ANY
                                               placements:OCMOCK_ANY
                                                   config:nil
                                         placementOptions:[OCMArg checkWithBlock:^BOOL(RoktPlacementOptions *opts) {
                                             return opts != nil;
                                         }]
                                                  onEvent:OCMOCK_ANY]);

    MPKitExecStatus *status = [self.kitInstance selectPlacementsWithIdentifier:identifier
                                                         attributes:attributes
                                                      embeddedViews:nil
                                                             config:nil
                                                          onEvent:nil
                                                       filteredUser:user
                                                            options:nil];

    // Verify
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);
}

- (void)testAddIdentityAttributes {
    NSMutableDictionary<NSString *, NSString *> *passedAttributes = [[NSMutableDictionary alloc] init];
    NSDictionary<NSNumber *, NSString *> *testIdentities = @{@(MPIdentityCustomerId): @"testCustomerID",
                                                             @(MPIdentityEmail): @"testEmail@gmail.com",
                                                             @(MPIdentityFacebook): @"testFacebook",
                                                             @(MPIdentityFacebookCustomAudienceId): @"testCustomAudienceID",
                                                             @(MPIdentityGoogle): @"testGoogle",
                                                             @(MPIdentityMicrosoft): @"testMicrosoft",
                                                             @(MPIdentityOther): @"testOther",
                                                             @(MPIdentityTwitter): @"testTwitter",
                                                             @(MPIdentityYahoo): @"testYahoo",
                                                             @(MPIdentityOther2): @"testOther2",
                                                             @(MPIdentityOther3): @"testOther3",
                                                             @(MPIdentityOther4): @"testOther4",
                                                             @(MPIdentityOther5): @"testOther5",
                                                             @(MPIdentityOther6): @"testOther6",
                                                             @(MPIdentityOther7): @"testOther7",
                                                             @(MPIdentityOther8): @"testOther8",
                                                             @(MPIdentityOther9): @"testOther9",
                                                             @(MPIdentityOther10): @"testOther10",
                                                             @(MPIdentityMobileNumber): @"1(234)-567-8910",
                                                             @(MPIdentityPhoneNumber2): @"1(234)-567-2222",
                                                             @(MPIdentityPhoneNumber3): @"1(234)-567-3333",
                                                             @(MPIdentityIOSAdvertiserId): @"testAdvertID",
                                                             @(MPIdentityIOSVendorId): @"testVendorID",
                                                             @(MPIdentityPushToken): @"testPushToken",
                                                             @(MPIdentityDeviceApplicationStamp): @"Test DAS"};

    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] init];
    id mockfilteredUser = OCMPartialMock(filteredUser);
    [[[mockfilteredUser stub] andReturn:testIdentities] userIdentities];
    id mockMPKitRoktClass = OCMClassMock([MPKitRokt class]);
    [[[mockMPKitRoktClass stub] andReturn:@(MPIdentityOther)] getRoktHashedEmailUserIdentityType];
    
    [MPKitRokt addIdentityAttributes:passedAttributes filteredUser:filteredUser];
    
    XCTAssertEqualObjects(passedAttributes[@"customerid"], @"testCustomerID");
    XCTAssertEqualObjects(passedAttributes[@"email"], @"testEmail@gmail.com");
    XCTAssertEqualObjects(passedAttributes[@"facebook"], @"testFacebook");
    XCTAssertEqualObjects(passedAttributes[@"facebookcustomaudienceid"], @"testCustomAudienceID");
    XCTAssertEqualObjects(passedAttributes[@"google"], @"testGoogle");
    XCTAssertEqualObjects(passedAttributes[@"microsoft"], @"testMicrosoft");
    XCTAssertNil(passedAttributes[@"other"]);
    XCTAssertEqualObjects(passedAttributes[@"emailsha256"], @"testOther");
    XCTAssertEqualObjects(passedAttributes[@"twitter"], @"testTwitter");
    XCTAssertEqualObjects(passedAttributes[@"yahoo"], @"testYahoo");
    XCTAssertEqualObjects(passedAttributes[@"other2"], @"testOther2");
    XCTAssertEqualObjects(passedAttributes[@"other3"], @"testOther3");
    XCTAssertEqualObjects(passedAttributes[@"other4"], @"testOther4");
    XCTAssertEqualObjects(passedAttributes[@"other5"], @"testOther5");
    XCTAssertEqualObjects(passedAttributes[@"other6"], @"testOther6");
    XCTAssertEqualObjects(passedAttributes[@"other7"], @"testOther7");
    XCTAssertEqualObjects(passedAttributes[@"other8"], @"testOther8");
    XCTAssertEqualObjects(passedAttributes[@"other9"], @"testOther9");
    XCTAssertEqualObjects(passedAttributes[@"other10"], @"testOther10");
    XCTAssertEqualObjects(passedAttributes[@"mobile_number"], @"1(234)-567-8910");
    XCTAssertEqualObjects(passedAttributes[@"phone_number_2"], @"1(234)-567-2222");
    XCTAssertEqualObjects(passedAttributes[@"phone_number_3"], @"1(234)-567-3333");
    XCTAssertEqualObjects(passedAttributes[@"ios_idfa"], @"testAdvertID");
    XCTAssertEqualObjects(passedAttributes[@"ios_idfv"], @"testVendorID");
    XCTAssertEqualObjects(passedAttributes[@"push_token"], @"testPushToken");
    XCTAssertEqualObjects(passedAttributes[@"device_application_stamp"], @"Test DAS");
}

- (void)testAddIdentityAttributesUnassigned {
    NSMutableDictionary<NSString *, NSString *> *passedAttributes = [[NSMutableDictionary alloc] init];
    NSDictionary<NSNumber *, NSString *> *testIdentities = @{@(MPIdentityCustomerId): @"testCustomerID",
                                                             @(MPIdentityEmail): @"testEmail@gmail.com",
                                                             @(MPIdentityFacebook): @"testFacebook",
                                                             @(MPIdentityFacebookCustomAudienceId): @"testCustomAudienceID",
                                                             @(MPIdentityGoogle): @"testGoogle",
                                                             @(MPIdentityMicrosoft): @"testMicrosoft",
                                                             @(MPIdentityOther): @"testOther",
                                                             @(MPIdentityTwitter): @"testTwitter",
                                                             @(MPIdentityYahoo): @"testYahoo",
                                                             @(MPIdentityOther2): @"testOther2",
                                                             @(MPIdentityOther3): @"testOther3",
                                                             @(MPIdentityOther4): @"testOther4",
                                                             @(MPIdentityOther5): @"testOther5",
                                                             @(MPIdentityOther6): @"testOther6",
                                                             @(MPIdentityOther7): @"testOther7",
                                                             @(MPIdentityOther8): @"testOther8",
                                                             @(MPIdentityOther9): @"testOther9",
                                                             @(MPIdentityOther10): @"testOther10",
                                                             @(MPIdentityMobileNumber): @"1(234)-567-8910",
                                                             @(MPIdentityPhoneNumber2): @"1(234)-567-2222",
                                                             @(MPIdentityPhoneNumber3): @"1(234)-567-3333",
                                                             @(MPIdentityIOSAdvertiserId): @"testAdvertID",
                                                             @(MPIdentityIOSVendorId): @"testVendorID",
                                                             @(MPIdentityPushToken): @"testPushToken",
                                                             @(MPIdentityDeviceApplicationStamp): @"Test DAS"};

    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] init];
    id mockfilteredUser = OCMPartialMock(filteredUser);
    [[[mockfilteredUser stub] andReturn:testIdentities] userIdentities];
    id mockMPKitRoktClass = OCMClassMock([MPKitRokt class]);
    [[[mockMPKitRoktClass stub] andReturn:nil] getRoktHashedEmailUserIdentityType];
    
    [MPKitRokt addIdentityAttributes:passedAttributes filteredUser:filteredUser];
    
    XCTAssertEqualObjects(passedAttributes[@"customerid"], @"testCustomerID");
    XCTAssertEqualObjects(passedAttributes[@"email"], @"testEmail@gmail.com");
    XCTAssertEqualObjects(passedAttributes[@"facebook"], @"testFacebook");
    XCTAssertEqualObjects(passedAttributes[@"facebookcustomaudienceid"], @"testCustomAudienceID");
    XCTAssertEqualObjects(passedAttributes[@"google"], @"testGoogle");
    XCTAssertEqualObjects(passedAttributes[@"microsoft"], @"testMicrosoft");
    XCTAssertEqualObjects(passedAttributes[@"other"], @"testOther");
    XCTAssertEqualObjects(passedAttributes[@"twitter"], @"testTwitter");
    XCTAssertEqualObjects(passedAttributes[@"yahoo"], @"testYahoo");
    XCTAssertEqualObjects(passedAttributes[@"other2"], @"testOther2");
    XCTAssertEqualObjects(passedAttributes[@"other3"], @"testOther3");
    XCTAssertEqualObjects(passedAttributes[@"other4"], @"testOther4");
    XCTAssertEqualObjects(passedAttributes[@"other5"], @"testOther5");
    XCTAssertEqualObjects(passedAttributes[@"other6"], @"testOther6");
    XCTAssertEqualObjects(passedAttributes[@"other7"], @"testOther7");
    XCTAssertEqualObjects(passedAttributes[@"other8"], @"testOther8");
    XCTAssertEqualObjects(passedAttributes[@"other9"], @"testOther9");
    XCTAssertEqualObjects(passedAttributes[@"other10"], @"testOther10");
    XCTAssertEqualObjects(passedAttributes[@"mobile_number"], @"1(234)-567-8910");
    XCTAssertEqualObjects(passedAttributes[@"phone_number_2"], @"1(234)-567-2222");
    XCTAssertEqualObjects(passedAttributes[@"phone_number_3"], @"1(234)-567-3333");
    XCTAssertEqualObjects(passedAttributes[@"ios_idfa"], @"testAdvertID");
    XCTAssertEqualObjects(passedAttributes[@"ios_idfv"], @"testVendorID");
    XCTAssertEqualObjects(passedAttributes[@"push_token"], @"testPushToken");
    XCTAssertEqualObjects(passedAttributes[@"device_application_stamp"], @"Test DAS");
}

- (void)testAddIdentityAttributesWithExistingAttributes {
    NSMutableDictionary<NSString *, NSString *> *passedAttributes = [[NSMutableDictionary alloc] init];
    [passedAttributes setObject:@"bar" forKey:@"foo"];
    NSDictionary<NSNumber *, NSString *> *testIdentities = @{@(MPIdentityCustomerId): @"testCustomerID",
                                                             @(MPIdentityEmail): @"testEmail@gmail.com",
                                                             @(MPIdentityFacebook): @"testFacebook",
                                                             @(MPIdentityFacebookCustomAudienceId): @"testCustomAudienceID",
                                                             @(MPIdentityGoogle): @"testGoogle",
                                                             @(MPIdentityMicrosoft): @"testMicrosoft",
                                                             @(MPIdentityOther): @"testOther",
                                                             @(MPIdentityTwitter): @"testTwitter",
                                                             @(MPIdentityYahoo): @"testYahoo",
                                                             @(MPIdentityOther2): @"testOther2",
                                                             @(MPIdentityOther3): @"testOther3",
                                                             @(MPIdentityOther4): @"testOther4",
                                                             @(MPIdentityOther5): @"testOther5",
                                                             @(MPIdentityOther6): @"testOther6",
                                                             @(MPIdentityOther7): @"testOther7",
                                                             @(MPIdentityOther8): @"testOther8",
                                                             @(MPIdentityOther9): @"testOther9",
                                                             @(MPIdentityOther10): @"testOther10",
                                                             @(MPIdentityMobileNumber): @"1(234)-567-8910",
                                                             @(MPIdentityPhoneNumber2): @"1(234)-567-2222",
                                                             @(MPIdentityPhoneNumber3): @"1(234)-567-3333",
                                                             @(MPIdentityIOSAdvertiserId): @"testAdvertID",
                                                             @(MPIdentityIOSVendorId): @"testVendorID",
                                                             @(MPIdentityPushToken): @"testPushToken",
                                                             @(MPIdentityDeviceApplicationStamp): @"Test DAS"};

    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] init];
    id mockfilteredUser = OCMPartialMock(filteredUser);
    [[[mockfilteredUser stub] andReturn:testIdentities] userIdentities];
    id mockMPKitRoktClass = OCMClassMock([MPKitRokt class]);
    [[[mockMPKitRoktClass stub] andReturn:@(MPIdentityOther)] getRoktHashedEmailUserIdentityType];
    
    [MPKitRokt addIdentityAttributes:passedAttributes filteredUser:filteredUser];
    
    XCTAssertEqualObjects(passedAttributes[@"foo"], @"bar");
    XCTAssertEqualObjects(passedAttributes[@"customerid"], @"testCustomerID");
    XCTAssertEqualObjects(passedAttributes[@"email"], @"testEmail@gmail.com");
    XCTAssertEqualObjects(passedAttributes[@"facebook"], @"testFacebook");
    XCTAssertEqualObjects(passedAttributes[@"facebookcustomaudienceid"], @"testCustomAudienceID");
    XCTAssertEqualObjects(passedAttributes[@"google"], @"testGoogle");
    XCTAssertEqualObjects(passedAttributes[@"microsoft"], @"testMicrosoft");
    XCTAssertNil(passedAttributes[@"other"]);
    XCTAssertEqualObjects(passedAttributes[@"emailsha256"], @"testOther");
    XCTAssertEqualObjects(passedAttributes[@"twitter"], @"testTwitter");
    XCTAssertEqualObjects(passedAttributes[@"yahoo"], @"testYahoo");
    XCTAssertEqualObjects(passedAttributes[@"other2"], @"testOther2");
    XCTAssertEqualObjects(passedAttributes[@"other3"], @"testOther3");
    XCTAssertEqualObjects(passedAttributes[@"other4"], @"testOther4");
    XCTAssertEqualObjects(passedAttributes[@"other5"], @"testOther5");
    XCTAssertEqualObjects(passedAttributes[@"other6"], @"testOther6");
    XCTAssertEqualObjects(passedAttributes[@"other7"], @"testOther7");
    XCTAssertEqualObjects(passedAttributes[@"other8"], @"testOther8");
    XCTAssertEqualObjects(passedAttributes[@"other9"], @"testOther9");
    XCTAssertEqualObjects(passedAttributes[@"other10"], @"testOther10");
    XCTAssertEqualObjects(passedAttributes[@"mobile_number"], @"1(234)-567-8910");
    XCTAssertEqualObjects(passedAttributes[@"phone_number_2"], @"1(234)-567-2222");
    XCTAssertEqualObjects(passedAttributes[@"phone_number_3"], @"1(234)-567-3333");
    XCTAssertEqualObjects(passedAttributes[@"ios_idfa"], @"testAdvertID");
    XCTAssertEqualObjects(passedAttributes[@"ios_idfv"], @"testVendorID");
    XCTAssertEqualObjects(passedAttributes[@"push_token"], @"testPushToken");
    XCTAssertEqualObjects(passedAttributes[@"device_application_stamp"], @"Test DAS");
}

- (void)testAddIdentityAttributesWithExistingAttributesAndOther {
    NSMutableDictionary<NSString *, NSString *> *passedAttributes = [[NSMutableDictionary alloc] init];
    [passedAttributes setObject:@"bar" forKey:@"foo"];
    NSDictionary<NSNumber *, NSString *> *testIdentities = @{@(MPIdentityCustomerId): @"testCustomerID",
                                                             @(MPIdentityEmail): @"testEmail@gmail.com",
                                                             @(MPIdentityFacebook): @"testFacebook",
                                                             @(MPIdentityFacebookCustomAudienceId): @"testCustomAudienceID",
                                                             @(MPIdentityGoogle): @"testGoogle",
                                                             @(MPIdentityMicrosoft): @"testMicrosoft",
                                                             @(MPIdentityOther): @"testOther",
                                                             @(MPIdentityTwitter): @"testTwitter",
                                                             @(MPIdentityYahoo): @"testYahoo",
                                                             @(MPIdentityOther2): @"testOther2",
                                                             @(MPIdentityOther3): @"testOther3",
                                                             @(MPIdentityOther4): @"testOther4",
                                                             @(MPIdentityOther5): @"testOther5",
                                                             @(MPIdentityOther6): @"testOther6",
                                                             @(MPIdentityOther7): @"testOther7",
                                                             @(MPIdentityOther8): @"testOther8",
                                                             @(MPIdentityOther9): @"testOther9",
                                                             @(MPIdentityOther10): @"testOther10",
                                                             @(MPIdentityMobileNumber): @"1(234)-567-8910",
                                                             @(MPIdentityPhoneNumber2): @"1(234)-567-2222",
                                                             @(MPIdentityPhoneNumber3): @"1(234)-567-3333",
                                                             @(MPIdentityIOSAdvertiserId): @"testAdvertID",
                                                             @(MPIdentityIOSVendorId): @"testVendorID",
                                                             @(MPIdentityPushToken): @"testPushToken",
                                                             @(MPIdentityDeviceApplicationStamp): @"Test DAS"};

    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] init];
    id mockfilteredUser = OCMPartialMock(filteredUser);
    [[[mockfilteredUser stub] andReturn:testIdentities] userIdentities];
    id mockMPKitRoktClass = OCMClassMock([MPKitRokt class]);
    [[[mockMPKitRoktClass stub] andReturn:@(MPIdentityOther4)] getRoktHashedEmailUserIdentityType];
    
    [MPKitRokt addIdentityAttributes:passedAttributes filteredUser:filteredUser];
    
    XCTAssertEqualObjects(passedAttributes[@"foo"], @"bar");
    XCTAssertEqualObjects(passedAttributes[@"customerid"], @"testCustomerID");
    XCTAssertEqualObjects(passedAttributes[@"email"], @"testEmail@gmail.com");
    XCTAssertEqualObjects(passedAttributes[@"facebook"], @"testFacebook");
    XCTAssertEqualObjects(passedAttributes[@"facebookcustomaudienceid"], @"testCustomAudienceID");
    XCTAssertEqualObjects(passedAttributes[@"google"], @"testGoogle");
    XCTAssertEqualObjects(passedAttributes[@"microsoft"], @"testMicrosoft");
    XCTAssertEqualObjects(passedAttributes[@"other"], @"testOther");
    XCTAssertEqualObjects(passedAttributes[@"emailsha256"], @"testOther4");
    XCTAssertEqualObjects(passedAttributes[@"twitter"], @"testTwitter");
    XCTAssertEqualObjects(passedAttributes[@"yahoo"], @"testYahoo");
    XCTAssertEqualObjects(passedAttributes[@"other2"], @"testOther2");
    XCTAssertEqualObjects(passedAttributes[@"other3"], @"testOther3");
    XCTAssertNil(passedAttributes[@"other4"]);
    XCTAssertEqualObjects(passedAttributes[@"other5"], @"testOther5");
    XCTAssertEqualObjects(passedAttributes[@"other6"], @"testOther6");
    XCTAssertEqualObjects(passedAttributes[@"other7"], @"testOther7");
    XCTAssertEqualObjects(passedAttributes[@"other8"], @"testOther8");
    XCTAssertEqualObjects(passedAttributes[@"other9"], @"testOther9");
    XCTAssertEqualObjects(passedAttributes[@"other10"], @"testOther10");
    XCTAssertEqualObjects(passedAttributes[@"mobile_number"], @"1(234)-567-8910");
    XCTAssertEqualObjects(passedAttributes[@"phone_number_2"], @"1(234)-567-2222");
    XCTAssertEqualObjects(passedAttributes[@"phone_number_3"], @"1(234)-567-3333");
    XCTAssertEqualObjects(passedAttributes[@"ios_idfa"], @"testAdvertID");
    XCTAssertEqualObjects(passedAttributes[@"ios_idfv"], @"testVendorID");
    XCTAssertEqualObjects(passedAttributes[@"push_token"], @"testPushToken");
    XCTAssertEqualObjects(passedAttributes[@"device_application_stamp"], @"Test DAS");
}

- (void)runSetWrapperSdkTestWithProvidedMPWrapperType:(MPWrapperSdk)providedMPWrapperType expectedRoktFrameworkType:(RoktFrameworkType)expectedRoktFrameworkType {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    // Expect Rokt execute call with correct parameters
    OCMExpect([mockRoktSDK setFrameworkTypeWithFrameworkType:expectedRoktFrameworkType]);

    MPKitExecStatus *status = [self.kitInstance setWrapperSdk:providedMPWrapperType
                                                         version:@""];

    // Verify
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);
    [mockRoktSDK stopMocking];
}

- (void)testSetWrapperSdk {
    [self runSetWrapperSdkTestWithProvidedMPWrapperType:MPWrapperSdkNone expectedRoktFrameworkType:RoktFrameworkTypeIOS];
    [self runSetWrapperSdkTestWithProvidedMPWrapperType:MPWrapperSdkUnity expectedRoktFrameworkType:RoktFrameworkTypeIOS];
    [self runSetWrapperSdkTestWithProvidedMPWrapperType:MPWrapperSdkReactNative expectedRoktFrameworkType:RoktFrameworkTypeReactNative];
    [self runSetWrapperSdkTestWithProvidedMPWrapperType:MPWrapperSdkCordova expectedRoktFrameworkType:RoktFrameworkTypeCordova];
    [self runSetWrapperSdkTestWithProvidedMPWrapperType:MPWrapperSdkXamarin expectedRoktFrameworkType:RoktFrameworkTypeIOS];
    [self runSetWrapperSdkTestWithProvidedMPWrapperType:MPWrapperSdkFlutter expectedRoktFrameworkType:RoktFrameworkTypeFlutter];
}

- (void)testPurchaseFinalized {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    // Set up test parameters
    NSString *identifier = @"testonversion";
    NSString *catalogItemId = @"testcatalogItemId";
    BOOL success = YES;

    // Expect Rokt purchaseFinalized call with correct parameters
    OCMExpect([mockRoktSDK purchaseFinalizedWithIdentifier:identifier
                                             catalogItemId:catalogItemId
                                                   success:success]);

    MPKitExecStatus *status = [self.kitInstance purchaseFinalized:identifier
                                                    catalogItemId:catalogItemId
                                                          success:@(success)];

    // Verify
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);
}

- (void)testEvents_Success {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    NSString *identifier = @"TestViewName";
    __block BOOL callbackCalled = NO;
    __block RoktEvent *receivedEvent = nil;

    // Mock the Rokt SDK call and simulate triggering the callback with a mock event
    OCMStub([mockRoktSDK eventsWithIdentifier:identifier onEvent:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        // Get the callback block from the invocation
        void (^onEventCallback)(RoktEvent *) = nil;
        [invocation getArgument:&onEventCallback atIndex:3]; // Index 3 is the second parameter (onEvent)

        RoktShowLoadingIndicator *roktEvent = [[RoktShowLoadingIndicator alloc] init];

        // Simulate the callback being called
        if (onEventCallback) {
            onEventCallback(roktEvent);
        }
    });

    // Execute the method under test
    MPKitExecStatus *status = [self.kitInstance events:identifier onEvent:^(RoktEvent * _Nonnull event) {
        callbackCalled = YES;
        receivedEvent = event;
    }];

    // Verify the Rokt SDK method was called
    OCMVerify([mockRoktSDK eventsWithIdentifier:identifier onEvent:[OCMArg any]]);

    // Verify the return status
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    XCTAssertEqualObjects(status.integrationId, @181);

    // Verify the callback was called with the same RoktContracts event instance
    XCTAssertTrue(callbackCalled);
    XCTAssertNotNil(receivedEvent);
    XCTAssertEqual([receivedEvent class], [RoktShowLoadingIndicator class]);

    [mockRoktSDK stopMocking];
}

- (void)testEvents_PassesThroughConcreteEvent {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    NSString *identifier = @"TestViewName";
    __block BOOL callbackCalled = NO;
    __block RoktEvent *receivedEvent = nil;
    __block id mockRoktEvent = nil;

    // Mock the Rokt SDK call and simulate triggering the callback with a mock event
    OCMStub([mockRoktSDK eventsWithIdentifier:identifier onEvent:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        // Get the callback block from the invocation
        void (^onEventCallback)(RoktEvent *) = nil;
        [invocation getArgument:&onEventCallback atIndex:3];

        mockRoktEvent = OCMClassMock([RoktEvent class]);

        if (onEventCallback) {
            onEventCallback(mockRoktEvent);
        }
    });

    MPKitExecStatus *status = [self.kitInstance events:identifier onEvent:^(RoktEvent * _Nonnull event) {
        callbackCalled = YES;
        receivedEvent = event;
    }];

    // Verify the Rokt SDK method was called
    OCMVerify([mockRoktSDK eventsWithIdentifier:identifier onEvent:[OCMArg any]]);

    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    XCTAssertTrue(callbackCalled);
    XCTAssertEqualObjects(receivedEvent, mockRoktEvent);

    [mockRoktSDK stopMocking];
}

- (void)testEvents_NilIdentifier {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    NSString *identifier = @"";
    __block BOOL callbackCalled = NO;

    // The Rokt SDK should still be called even with nil identifier
    OCMExpect([mockRoktSDK eventsWithIdentifier:@"" onEvent:[OCMArg any]]);

    // Execute the method under test
    MPKitExecStatus *status = [self.kitInstance events:identifier onEvent:^(RoktEvent * _Nonnull event) {
        callbackCalled = YES;
    }];

    // Verify the Rokt SDK method was called
    OCMVerify([mockRoktSDK eventsWithIdentifier:@"" onEvent:[OCMArg any]]);

    // Verify the return status
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);

    [mockRoktSDK stopMocking];
}

- (void)testEvents_NilOnEventForwardedWithoutCrash {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    NSString *identifier = @"RoktLayout";

    OCMExpect([mockRoktSDK eventsWithIdentifier:identifier onEvent:nil]);

    MPKitExecStatus *status = [self.kitInstance events:identifier onEvent:nil];

    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);

    [mockRoktSDK stopMocking];
}

- (void)testHandleHashedEmailOtherOverride {
    NSMutableDictionary<NSString *, NSString *> *passedAttributes = [[NSMutableDictionary alloc] init];
    [passedAttributes setObject:@"foo@gmail.com" forKey:@"email"];
    [passedAttributes setObject:@"test@gmail.com" forKey:@"other"];
    
    [MPKitRokt handleHashedEmail:passedAttributes];
    
    XCTAssertEqualObjects(passedAttributes[@"email"], @"foo@gmail.com");
    XCTAssertEqualObjects(passedAttributes[@"other"], @"test@gmail.com");
    XCTAssertNil(passedAttributes[@"emailsha256"]);
    XCTAssertTrue(passedAttributes.allKeys.count == 2);
}

- (void)testHandleHashedEmailHashedOverride {
    NSMutableDictionary<NSString *, NSString *> *passedAttributes = [[NSMutableDictionary alloc] init];
    [passedAttributes setObject:@"foo@gmail.com" forKey:@"email"];
    [passedAttributes setObject:@"foo-value" forKey:@"other"];
    [passedAttributes setObject:@"test2@gmail.com" forKey:@"emailsha256"];
    
    [MPKitRokt handleHashedEmail:passedAttributes];
    
    XCTAssertNil(passedAttributes[@"email"]);
    XCTAssertEqualObjects(passedAttributes[@"other"], @"foo-value");
    XCTAssertEqualObjects(passedAttributes[@"emailsha256"], @"test2@gmail.com");
    XCTAssertTrue(passedAttributes.allKeys.count == 2);
}

- (void)testTransformValuesToString {
    NSMutableDictionary<NSString *, id> *passedAttributes = [[NSMutableDictionary alloc] init];
    [passedAttributes setObject:@"foo@gmail.com" forKey:@"email"];
    [passedAttributes setObject:@"test@gmail.com" forKey:@"other"];
    [passedAttributes setObject:@"test2@gmail.com" forKey:@"emailsha256"];
    [passedAttributes setObject:[NSNull null] forKey:@"testCrash"];

    
    NSDictionary<NSString *, NSString *> *finalAtt = [MPKitRokt transformValuesToString:passedAttributes];
    
    XCTAssertEqualObjects(finalAtt[@"testCrash"], @"null");
    XCTAssertEqualObjects(finalAtt[@"email"], @"foo@gmail.com");
    XCTAssertEqualObjects(finalAtt[@"other"], @"test@gmail.com");
    XCTAssertEqualObjects(finalAtt[@"emailsha256"], @"test2@gmail.com");
    XCTAssertTrue(finalAtt.allKeys.count == 4);
}

- (void)testGetRoktHashedEmailUserIdentityTypeOther4 {
    // Test case 1: When kit configuration exists with hashed email identity type
    NSDictionary *roktKitConfig = @{
        @"id": @(kMPRoktKitCode),
        @"as": @{
            kMPRoktHashedEmailUserIdentityType: @"other4"
        }
    };
    
    // Mock the MParticle shared instance and kit container
    id mockMPKitRoktClass = OCMClassMock([MPKitRokt class]);
    [[[mockMPKitRoktClass stub] andReturn:roktKitConfig] getKitConfig];
    
    // Call the method and verify result
    NSNumber *result = [MPKitRokt getRoktHashedEmailUserIdentityType];
    XCTAssertEqualObjects(result, @(MPIdentityOther4), @"Should return MPIdentityOther4 when configured with 'other4'");
    
    [mockMPKitRoktClass stopMocking];
}

- (void)testGetRoktHashedEmailUserIdentityTypeConfigNil {
    // Test case 2: When kit config nil
    // Mock the MParticle shared instance and kit container
    id mockMPKitRoktClass = OCMClassMock([MPKitRokt class]);
    [[[mockMPKitRoktClass stub] andReturn:nil] getKitConfig];
    
    NSNumber *defaultResult = [MPKitRokt getRoktHashedEmailUserIdentityType];
    XCTAssertNil(defaultResult, @"Should return nil when when no configuration exists");
    
    [mockMPKitRoktClass stopMocking];
}

- (void)testGetRoktHashedEmailUserIdentityTypeNil {
    // Mock the MParticle shared instance and kit container
    id mockMPKitRoktClass = OCMClassMock([MPKitRokt class]);
    // Test case 3: When kit config exists but no hashed email identity type specified
    NSDictionary *roktKitConfigNoHash = @{
        @"id": @(kMPRoktKitCode),
        @"as": @{
            // No kMPRoktHashedEmailUserIdentityType specified
        }
    };
    [[[mockMPKitRoktClass stub] andReturn:roktKitConfigNoHash] getKitConfig];
    
    NSNumber *noHashResult = [MPKitRokt getRoktHashedEmailUserIdentityType];
    XCTAssertNil(noHashResult, @"Should return nil when hashed email identity type not specified");
    
    [mockMPKitRoktClass stopMocking];
}

#pragma mark - logSelectPlacementEvent tests

- (void)testExecuteWithIdentifierLogsSelectPlacementEventWithPreparedAttributes {
    id mockRoktSDK = OCMClassMock([Rokt class]);
    id mockMParticleInstance = OCMClassMock([MParticle class]);
    
    // Stub the class method sharedInstance to return our mock
    id mockMParticleClass = OCMClassMock([MParticle class]);
    OCMStub([mockMParticleClass sharedInstance]).andReturn(mockMParticleInstance);
    OCMStub([(MParticle *)mockMParticleInstance environment]).andReturn(MPEnvironmentDevelopment);
    
    NSString *identifier = @"TestView";
    NSDictionary *attributes = @{@"email": @"test@example.com"};
    
    // Create a mock user with MPID and identities
    FilteredMParticleUser *user = [[FilteredMParticleUser alloc] init];
    id mockUser = OCMPartialMock(user);
    OCMStub([mockUser userId]).andReturn(@(123456));
    OCMStub([mockUser userIdentities]).andReturn(@{@(MPIdentityEmail): @"test@example.com"});
    OCMStub([mockUser userAttributes]).andReturn(@{});
    
    // Expect logEvent and verify MPEvent object contains prepared attributes (email, mpid, sandbox)
    OCMExpect([(MParticle *)mockMParticleInstance logEvent:[OCMArg checkWithBlock:^BOOL(MPEvent *event) {
        // Verify the MPEvent object was created correctly
        XCTAssertNotNil(event, @"Event object should not be nil");
        XCTAssertEqualObjects(event.name, @"selectPlacements", @"Event name should be 'selectPlacements'");
        XCTAssertEqual(event.type, MPEventTypeOther, @"Event type should be MPEventTypeOther");
        
        // Verify custom attributes contain prepared user data
        XCTAssertEqualObjects(event.customAttributes[@"email"], @"test@example.com", @"Email should be in attributes");
        XCTAssertEqualObjects(event.customAttributes[@"mpid"], @"123456", @"MPID should be in attributes");
        XCTAssertNotNil(event.customAttributes[@"sandbox"], @"Sandbox should be in attributes");
        
        return YES;
    }]]);
    
    // Stub Rokt selectPlacements call
    OCMStub([mockRoktSDK selectPlacementsWithIdentifier:OCMOCK_ANY
                                             attributes:OCMOCK_ANY
                                             placements:OCMOCK_ANY
                                                 config:OCMOCK_ANY
                                       placementOptions:OCMOCK_ANY
                                              onEvent:OCMOCK_ANY]);
    
    // Call executeWithIdentifier which triggers logSelectPlacementEvent with prepareAttributes
    MPKitExecStatus *status = [self.kitInstance selectPlacementsWithIdentifier:identifier
                                                         attributes:attributes
                                                      embeddedViews:nil
                                                             config:nil
                                                          onEvent:nil
                                                       filteredUser:user
                                                            options:nil];

    // Verify that logEvent was called with the correct MPEvent object
    OCMVerifyAll(mockMParticleInstance);
    
    // Verify execution status
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    
    [mockRoktSDK stopMocking];
    [mockMParticleClass stopMocking];
    [mockMParticleInstance stopMocking];
}

#pragma mark - setSessionId tests

- (void)testSetSessionIdCallsRoktSDK {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    NSString *sessionId = @"test-session-id-12345";

    // Expect Rokt setSessionIdWithSessionId call with correct parameter
    OCMExpect([mockRoktSDK setSessionIdWithSessionId:sessionId]);

    // Execute the method
    MPKitExecStatus *status = [self.kitInstance setSessionId:sessionId];

    // Verify
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    XCTAssertEqualObjects(status.integrationId, @181);
    OCMVerifyAll(mockRoktSDK);

    [mockRoktSDK stopMocking];
}

- (void)testSetSessionIdWithEmptyString {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    NSString *sessionId = @"";

    // Expect Rokt setSessionIdWithSessionId call - the kit passes it through, Rokt SDK handles validation
    OCMExpect([mockRoktSDK setSessionIdWithSessionId:sessionId]);

    // Execute the method
    MPKitExecStatus *status = [self.kitInstance setSessionId:sessionId];

    // Verify
    XCTAssertNotNil(status);
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);

    [mockRoktSDK stopMocking];
}

#pragma mark - getSessionId tests

- (void)testGetSessionIdReturnsSessionIdFromRoktSDK {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    NSString *expectedSessionId = @"mock-session-id-67890";

    // Stub Rokt getSessionId to return the expected session ID
    OCMStub([mockRoktSDK getSessionId]).andReturn(expectedSessionId);

    // Execute the method
    NSString *result = [self.kitInstance getSessionId];

    // Verify
    XCTAssertEqualObjects(result, expectedSessionId, @"Should return the session id from the Rokt SDK");

    [mockRoktSDK stopMocking];
}

- (void)testGetSessionIdReturnsNilWhenRoktSDKReturnsNil {
    id mockRoktSDK = OCMClassMock([Rokt class]);

    // Stub Rokt getSessionId to return nil
    OCMStub([mockRoktSDK getSessionId]).andReturn(nil);

    // Execute the method
    NSString *result = [self.kitInstance getSessionId];

    // Verify
    XCTAssertNil(result, @"Should return nil when Rokt SDK returns nil");

    [mockRoktSDK stopMocking];
}

- (void)testMapAttributesWithNewConfigurationStructure {
    // Test the mapAttributes method with the new nested configuration structure
    NSDictionary *roktKitConfig = @{
        @"id": @(kMPRoktKitCode),
        @"as": @{
            @"placementAttributesMapping": @"[{\"jsmap\":null,\"map\":\"f.name\",\"maptype\":\"UserAttributeClass.Name\",\"value\":\"firstname\"},{\"jsmap\":null,\"map\":\"zip\",\"maptype\":\"UserAttributeClass.Name\",\"value\":\"billingzipcode\"},{\"jsmap\":null,\"map\":\"l.name\",\"maptype\":\"UserAttributeClass.Name\",\"value\":\"lastname\"}]"
        }
    };
    
    // Mock the kit configuration
    id mockMPKitRoktClass = OCMClassMock([MPKitRokt class]);
    [[[mockMPKitRoktClass stub] andReturn:roktKitConfig] getKitConfig];
    
    // Create test input attributes
    NSDictionary<NSString *, NSString *> *inputAttributes = @{
        @"f.name": @"John",
        @"zip": @"12345",
        @"l.name": @"Doe",
        @"email": @"john.doe@example.com"
    };
    
    // Create mock filtered user
    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] init];
    id mockFilteredUser = OCMPartialMock(filteredUser);
    [[[mockFilteredUser stub] andReturn:@{}] userAttributes];
    
    // Call mapAttributes method
    NSDictionary<NSString *, NSString *> *result = [MPKitRokt mapAttributes:inputAttributes filteredUser:mockFilteredUser];
    
    // Verify the mapping worked correctly
    XCTAssertEqualObjects(result[@"firstname"], @"John", @"f.name should be mapped to firstname");
    XCTAssertEqualObjects(result[@"billingzipcode"], @"12345", @"zip should be mapped to billingzipcode");
    XCTAssertEqualObjects(result[@"lastname"], @"Doe", @"l.name should be mapped to lastname");
    XCTAssertEqualObjects(result[@"email"], @"john.doe@example.com", @"email should remain unchanged");
    
    // Verify original keys are removed
    XCTAssertNil(result[@"f.name"], @"Original f.name key should be removed");
    XCTAssertNil(result[@"zip"], @"Original zip key should be removed");
    XCTAssertNil(result[@"l.name"], @"Original l.name key should be removed");
    
    [mockMPKitRoktClass stopMocking];
}

- (void)testMapAttributesWithNoConfiguration {
    // Test mapAttributes when no kit configuration exists
    id mockMPKitRoktClass = OCMClassMock([MPKitRokt class]);
    [[[mockMPKitRoktClass stub] andReturn:nil] getKitConfig];
    
    NSDictionary<NSString *, NSString *> *inputAttributes = @{
        @"email": @"test@example.com",
        @"name": @"Test User"
    };
    
    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] init];
    
    // Call mapAttributes method
    NSDictionary<NSString *, NSString *> *result = [MPKitRokt mapAttributes:inputAttributes filteredUser:filteredUser];
    
    // Should return original attributes unchanged
    XCTAssertEqualObjects(result, inputAttributes, @"Should return original attributes when no configuration exists");
    
    [mockMPKitRoktClass stopMocking];
}

- (void)testAddIdentityAttributesMpidWithNilUserId {
    // Test behavior when userId is nil
    NSMutableDictionary<NSString *, NSString *> *passedAttributes = [[NSMutableDictionary alloc] init];
    NSDictionary<NSNumber *, NSString *> *testIdentities = @{
        @(MPIdentityEmail): @"test@example.com"
    };

    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] init];
    id mockFilteredUser = OCMPartialMock(filteredUser);
    [[[mockFilteredUser stub] andReturn:testIdentities] userIdentities];
    [[[mockFilteredUser stub] andReturn:nil] userId];  // nil userId
    
    id mockMPKitRoktClass = OCMClassMock([MPKitRokt class]);
    [[[mockMPKitRoktClass stub] andReturn:nil] getRoktHashedEmailUserIdentityType];
    
    [MPKitRokt addIdentityAttributes:passedAttributes filteredUser:filteredUser];
    
    // Verify MPID is nil when userId is nil
    XCTAssertNil(passedAttributes[@"mpid"], @"MPID should be nil when userId is nil");
    // Email should still be added
    XCTAssertEqualObjects(passedAttributes[@"email"], @"test@example.com", @"Email should still be added");
    
    [mockMPKitRoktClass stopMocking];
}

#pragma mark - Shoppable Ads

- (void)testRegisterPaymentExtensionPassesStripeKeyFromKitConfiguration {
    id mockRoktSDK = OCMClassMock([Rokt class]);
    OCMExpect([mockRoktSDK registerPaymentExtension:OCMOCK_ANY
                                             config:[OCMArg checkWithBlock:^BOOL(NSDictionary *cfg) {
                                                 return [cfg isEqualToDictionary:@{@"stripeKey": @"pk_test_123"}];
                                             }]]);
    NSMutableDictionary *cfg = [self.configuration mutableCopy];
    cfg[@"stripePublishableKey"] = @"pk_test_123";
    self.kitInstance.configuration = cfg;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-selector"
#pragma clang diagnostic ignored "-Wat-protocol"
    id ext = OCMProtocolMock(@protocol(RoktPaymentExtension));
#pragma clang diagnostic pop
    MPKitExecStatus *status = [self.kitInstance registerPaymentExtension:ext];
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);
    [mockRoktSDK stopMocking];
}

- (void)testRegisterPaymentExtensionPassesEmptyConfigWhenStripeKeyAbsent {
    id mockRoktSDK = OCMClassMock([Rokt class]);
    OCMExpect([mockRoktSDK registerPaymentExtension:OCMOCK_ANY
                                             config:[OCMArg checkWithBlock:^BOOL(NSDictionary *cfg) {
                                                 return cfg.count == 0;
                                             }]]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-selector"
#pragma clang diagnostic ignored "-Wat-protocol"
    id ext = OCMProtocolMock(@protocol(RoktPaymentExtension));
#pragma clang diagnostic pop
    MPKitExecStatus *status = [self.kitInstance registerPaymentExtension:ext];
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);
    [mockRoktSDK stopMocking];
}

- (void)testRegisterPaymentExtensionNilReturnsFail {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    MPKitExecStatus *status = [self.kitInstance registerPaymentExtension:nil];
#pragma clang diagnostic pop
    XCTAssertEqual(status.returnCode, MPKitReturnCodeFail);
}

- (void)testRegisterPaymentExtensionForwardsToRoktWithConfigurationStripeKey {
    id mockRoktSDK = OCMClassMock([Rokt class]);
    OCMExpect([mockRoktSDK registerPaymentExtension:OCMOCK_ANY config:@{@"stripeKey": @"pk_x"}]);
    NSMutableDictionary *cfg = [self.configuration mutableCopy];
    cfg[@"stripePublishableKey"] = @"pk_x";
    self.kitInstance.configuration = cfg;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-selector"
#pragma clang diagnostic ignored "-Wat-protocol"
    id ext = OCMProtocolMock(@protocol(RoktPaymentExtension));
#pragma clang diagnostic pop
    MPKitExecStatus *status = [self.kitInstance registerPaymentExtension:ext];
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);
    [mockRoktSDK stopMocking];
}

- (void)testHandleURLCallbackForwardsToRoktAndReturnsYES {
    id mockRoktSDK = OCMClassMock([Rokt class]);
    NSURL *url = [NSURL URLWithString:@"myapp://afterpay-redirect?token=xyz"];
    OCMExpect([mockRoktSDK handleURLCallbackWith:url]).andReturn(YES);

    BOOL handled = [self.kitInstance handleURLCallback:url];

    XCTAssertTrue(handled);
    OCMVerifyAll(mockRoktSDK);
    [mockRoktSDK stopMocking];
}

- (void)testHandleURLCallbackForwardsToRoktAndReturnsNO {
    id mockRoktSDK = OCMClassMock([Rokt class]);
    NSURL *url = [NSURL URLWithString:@"myapp://unrelated"];
    OCMExpect([mockRoktSDK handleURLCallbackWith:url]).andReturn(NO);

    BOOL handled = [self.kitInstance handleURLCallback:url];

    XCTAssertFalse(handled);
    OCMVerifyAll(mockRoktSDK);
    [mockRoktSDK stopMocking];
}

- (void)testHandleURLCallbackNilURLReturnsNOWithoutForwarding {
    id mockRoktSDK = OCMClassMock([Rokt class]);
    OCMReject([mockRoktSDK handleURLCallbackWith:OCMOCK_ANY]);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    BOOL handled = [self.kitInstance handleURLCallback:nil];
#pragma clang diagnostic pop

    XCTAssertFalse(handled);
    [mockRoktSDK stopMocking];
}

- (void)testSelectShoppableAdsInvokesRoktAndLogsEvent {
    id mockRoktSDK = OCMClassMock([Rokt class]);
    OCMExpect([mockRoktSDK selectShoppableAdsWithIdentifier:@"ShopView"
                                               attributes:[OCMArg checkWithBlock:^BOOL(NSDictionary *attrs) {
                                                   return [attrs[@"email"] isEqualToString:@"a@b.com"];
                                               }]
                                                   config:nil
                                                  onEvent:nil]);
    id mockMParticleInstance = OCMClassMock([MParticle class]);
    id mockMParticleClass = OCMClassMock([MParticle class]);
    OCMStub([mockMParticleClass sharedInstance]).andReturn(mockMParticleInstance);
    OCMStub([(MParticle *)mockMParticleInstance environment]).andReturn(MPEnvironmentDevelopment);
    OCMExpect([(MParticle *)mockMParticleInstance logEvent:[OCMArg checkWithBlock:^BOOL(MPEvent *event) {
        XCTAssertEqualObjects(event.name, @"selectShoppableAds");
        XCTAssertEqual(event.type, MPEventTypeOther);
        return YES;
    }]]);
    FilteredMParticleUser *user = [[FilteredMParticleUser alloc] init];
    id mockUser = OCMPartialMock(user);
    OCMStub([mockUser userId]).andReturn(@(99));
    OCMStub([mockUser userIdentities]).andReturn(@{@(MPIdentityEmail): @"a@b.com"});
    OCMStub([mockUser userAttributes]).andReturn(@{});

    MPKitExecStatus *status = [self.kitInstance selectShoppableAdsWithIdentifier:@"ShopView"
                                                                      attributes:@{@"email": @"a@b.com"}
                                                                          config:nil
                                                                         onEvent:nil
                                                                    filteredUser:user];
    XCTAssertEqual(status.returnCode, MPKitReturnCodeSuccess);
    OCMVerifyAll(mockRoktSDK);
    OCMVerifyAll(mockMParticleInstance);
    [mockRoktSDK stopMocking];
    [mockMParticleClass stopMocking];
    [mockMParticleInstance stopMocking];
}

#pragma mark - Log Level Mapping tests

- (void)testRoktLogLevelFromMParticleLogLevel_Verbose {
    RoktLogLevel result = [MPKitRokt roktLogLevelFromMParticleLogLevel:MPILogLevelVerbose];
    XCTAssertEqual(result, RoktLogLevelVerbose, @"MPILogLevelVerbose should map to RoktLogLevelVerbose");
}

- (void)testRoktLogLevelFromMParticleLogLevel_Debug {
    RoktLogLevel result = [MPKitRokt roktLogLevelFromMParticleLogLevel:MPILogLevelDebug];
    XCTAssertEqual(result, RoktLogLevelDebug, @"MPILogLevelDebug should map to RoktLogLevelDebug");
}

- (void)testRoktLogLevelFromMParticleLogLevel_Warning {
    RoktLogLevel result = [MPKitRokt roktLogLevelFromMParticleLogLevel:MPILogLevelWarning];
    XCTAssertEqual(result, RoktLogLevelWarning, @"MPILogLevelWarning should map to RoktLogLevelWarning");
}

- (void)testRoktLogLevelFromMParticleLogLevel_Error {
    RoktLogLevel result = [MPKitRokt roktLogLevelFromMParticleLogLevel:MPILogLevelError];
    XCTAssertEqual(result, RoktLogLevelError, @"MPILogLevelError should map to RoktLogLevelError");
}

- (void)testRoktLogLevelFromMParticleLogLevel_None {
    RoktLogLevel result = [MPKitRokt roktLogLevelFromMParticleLogLevel:MPILogLevelNone];
    XCTAssertEqual(result, RoktLogLevelNone, @"MPILogLevelNone should map to RoktLogLevelNone");
}

- (void)testApplyMParticleLogLevel {
    id mockRoktSDK = OCMClassMock([Rokt class]);
    id mockMParticleInstance = OCMClassMock([MParticle class]);
    id mockMParticleClass = OCMClassMock([MParticle class]);
    
    OCMStub([mockMParticleClass sharedInstance]).andReturn(mockMParticleInstance);
    OCMStub([(MParticle *)mockMParticleInstance logLevel]).andReturn(MPILogLevelDebug);
    OCMStub([(MParticle *)mockMParticleInstance environment]).andReturn(MPEnvironmentDevelopment);
    
    OCMExpect([mockRoktSDK setLogLevel:RoktLogLevelDebug]);
    
    [MPKitRokt applyMParticleLogLevel];
    
    OCMVerifyAll(mockRoktSDK);
    
    [mockRoktSDK stopMocking];
    [mockMParticleClass stopMocking];
    [mockMParticleInstance stopMocking];
}

@end
