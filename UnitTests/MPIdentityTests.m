//
//  MPIdentityTests.m
//

#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPIdentityDTO.h"
#import "MPNetworkCommunication.h"
#import "OCMock.h"
#import "MPBaseTestCase.h"
#import "MPIdentityApi.h"
#import "MPIdentityApiManager.h"
#import "MPKitContainer.h"
#import "MPPersistenceController.h"

typedef NS_ENUM(NSUInteger, MPIdentityRequestType) {
    MPIdentityRequestIdentify = 0,
    MPIdentityRequestLogin = 1,
    MPIdentityRequestLogout = 2,
    MPIdentityRequestModify = 3
};

@interface MPIdentityTests : MPBaseTestCase {
    MPKitContainer *kitContainer;
}

@end

@interface MParticleUser ()

- (void)setUserIdentitySync:(NSString *)identityString identityType:(MPUserIdentity)identityType;
- (void)setUserId:(NSNumber *)userId;
@end

@interface MPIdentityApi ()
@property (nonatomic, strong) MPIdentityApiManager *apiManager;
@property(nonatomic, strong, readwrite, nonnull) MParticleUser *currentUser;

- (void)onIdentityRequestComplete:(MPIdentityApiRequest *)request identityRequestType:(MPIdentityRequestType)identityRequestType httpResponse:(MPIdentityHTTPSuccessResponse *) httpResponse completion:(MPIdentityApiResultCallback)completion error: (NSError *) error;
- (void)onModifyRequestComplete:(MPIdentityApiRequest *)request httpResponse:(MPIdentityHTTPModifySuccessResponse *) httpResponse completion:(MPModifyApiResultCallback)completion error: (NSError *) error;
@end
    
@interface MPNetworkCommunication ()
- (void)modifyWithIdentityChanges:(NSArray *)identityChanges blockOtherRequests:(BOOL)blockOtherRequests completion:(nullable MPIdentityApiManagerModifyCallback)completion;
- (void)identityApiRequestWithURL:(NSURL*)url identityRequest:(MPIdentityHTTPBaseRequest *_Nonnull)identityRequest blockOtherRequests: (BOOL) blockOtherRequests completion:(nullable MPIdentityApiManagerCallback)completion;
@end

#pragma mark - MPStateMachine category

@interface MPIdentityHTTPIdentities(Tests) 

- (instancetype)initWithIdentities:(NSDictionary *)identities;

@end

@interface MParticle ()

@property (nonatomic, strong) MPKitContainer *kitContainer;
@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;

@end

@implementation MPIdentityTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testConstructIdentityApiRequest {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"other id" identityType:MPUserIdentityOther];
    [request setUserIdentity:@"other id 2" identityType:MPUserIdentityOther2];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    [request setUserIdentity:@"other id 4" identityType:MPUserIdentityOther4];
    
    MPIdentityHTTPIdentities *httpIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:request.userIdentities];
    
    XCTAssertEqual(@"other id", httpIdentities.other);
    XCTAssertEqual(@"other id 2", httpIdentities.other2);
    XCTAssertEqual(@"other id 3", httpIdentities.other3);
    XCTAssertEqual(@"other id 4", httpIdentities.other4);
}

- (void)testNoEmptyModifyRequests {
    MPNetworkCommunication *network = [[MPNetworkCommunication alloc] init];
    
    id partialMock = OCMPartialMock(network);
    
    [[[partialMock reject] ignoringNonObjectArgs] identityApiRequestWithURL:[OCMArg any] identityRequest:[OCMArg any] blockOtherRequests:[OCMArg any] completion:[OCMArg any]];
    
    [partialMock modifyWithIdentityChanges:nil blockOtherRequests:YES completion:^(MPIdentityHTTPModifySuccessResponse * _Nullable httpResponse, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(httpResponse);
        XCTAssert([httpResponse isKindOfClass:[MPIdentityHTTPModifySuccessResponse class]]);
    }];

    [partialMock modifyWithIdentityChanges:@[] blockOtherRequests:YES completion:^(MPIdentityHTTPModifySuccessResponse * _Nullable httpResponse, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(httpResponse);
        XCTAssert([httpResponse isKindOfClass:[MPIdentityHTTPModifySuccessResponse class]]);
    }];
}

- (void)testModifyChangeResultsResponse {
    NSDictionary *responseDictionary = @{
                                   @"client_sdk":@{
                                           @"platform":@"ios", @"sdk_version":@"7.8.6", @"sdk_vendor":@"mparticle"
                                           },
                                   @"environment":@"development",
                                   @"request_timestamp_ms":@1551205524000,
                                   @"request_id":@"04B0B49E-B2F1-48B5-81E6-A9F9FDB529F5",
                                   @"identity_changes":@[@{@"new_value":@"bar-id",@"old_value":@0,@"identity_type":@"other"},@{@"new_value":@"foo@example.com",@"old_value":@"user@thisappisawesomewhyhaventithoughtaboutbuildingit.com",@"identity_type":@"email"},@{@"new_value":@"123456",@"old_value":@0,@"identity_type":@"customerid"}],
                               @"change_results":@[@{@"identity_type":@"email",@"modified_mpid":@"123"},@{@"identity_type":@"customerid",@"modified_mpid":@"456"}]
                                   };
    NSArray *changeArray = @[
  @{@"identity_type":@"email",@"modified_mpid":@"123"},
  @{@"identity_type":@"customerid",@"modified_mpid":@"456"}
  ];
    
    MPIdentityHTTPModifySuccessResponse *successResponse = [[MPIdentityHTTPModifySuccessResponse alloc] initWithJsonObject:responseDictionary];
    
    XCTAssertEqualObjects(successResponse.changeResults, changeArray);
}

- (void)testModifyChange {
    NSDictionary *responseDictionary = @{
                                         @"client_sdk":@{
                                                 @"platform":@"ios", @"sdk_version":@"7.8.6", @"sdk_vendor":@"mparticle"
                                                 },
                                         @"environment":@"development",
                                         @"request_timestamp_ms":@1551205524000,
                                         @"request_id":@"04B0B49E-B2F1-48B5-81E6-A9F9FDB529F5",
                                         @"identity_changes":@[@{@"new_value":@"bar-id",@"old_value":@0,@"identity_type":@"other"},@{@"new_value":@"foo@example.com",@"old_value":@"user@thisappisawesomewhyhaventithoughtaboutbuildingit.com",@"identity_type":@"email"},@{@"new_value":@"123456",@"old_value":@0,@"identity_type":@"customerid"}],
                                         @"change_results":@[@{@"identity_type":@"email",@"modified_mpid":@"123"},@{@"identity_type":@"customerid",@"modified_mpid":@"456"}]
                                         };
    MPIdentityChange *change1 = [[MPIdentityChange alloc] init];
    MParticleUser *changedUser1 = [[MParticleUser alloc] init];
    changedUser1.userId = @123;
    change1.changedUser = changedUser1;
    change1.changedIdentity = MPUserIdentityEmail;
    
    MPIdentityChange *change2 = [[MPIdentityChange alloc] init];
    MParticleUser *changedUser2 = [[MParticleUser alloc] init];
    changedUser2.userId = @456;
    change2.changedUser = changedUser2;
    change2.changedIdentity = MPUserIdentityCustomerId;
    
    NSArray<MPIdentityChange *> *changeArray = @[change1, change2];
    
    MPIdentityHTTPModifySuccessResponse *successResponse = [[MPIdentityHTTPModifySuccessResponse alloc] initWithJsonObject:responseDictionary];
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    NSError *error;
    
    MPModifyApiResultCallback completion = ^(MPModifyApiResult *_Nullable apiResult, NSError *_Nullable error) {
        for (int x = 0; x<apiResult.identityChanges.count; x++) {
            XCTAssertEqual(apiResult.identityChanges[x].changedUser.userId.integerValue, changeArray[x].changedUser.userId.integerValue);
            XCTAssertEqual(apiResult.identityChanges[x].changedIdentity, changeArray[x].changedIdentity);
        }
    };
    
    [identity onModifyRequestComplete:request httpResponse:successResponse completion:completion error:error];
}

- (void)testIdentityRequestComplete {
    id mockUser = OCMClassMock([MParticleUser class]);

    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock currentUser]).andReturn(mockUser);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"1234" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    
    [mockUser setExpectationOrderMatters:YES];
    [[mockUser expect] setUserIdentitySync:@"1234" identityType:MPUserIdentityCustomerId];
    [[mockUser expect] setUserIdentitySync:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [[mockUser expect] setUserIdentitySync:@"other id 3" identityType:MPUserIdentityOther3];
    [[mockUser reject] setUserIdentitySync:@"other id 4" identityType:MPUserIdentityOther4];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogin httpResponse:httpResponse completion:nil error:error];

    [mockUser verify];
    
    [mockUser stopMocking];
}

- (void)testIdentifyIdentityRequestCompleteWithKits {
    id mockPersistenceController = OCMClassMock([MPPersistenceController class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"1234" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @892;
    
    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestIdentify httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testLoginIdentityRequestCompleteWithKits {
    id mockPersistenceController = OCMClassMock([MPPersistenceController class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
        
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];

    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"1234" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @892;

    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogin httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testLogoutIdentityRequestCompleteWithKits {
    id mockPersistenceController = OCMClassMock([MPPersistenceController class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithUser:mockUser];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @892;

    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogout httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testIdentifyIdentityRequestCompleteWithKitsAndNoUserChange {
    id mockPersistenceController = OCMClassMock([MPPersistenceController class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"1234" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @42;
    
    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestIdentify httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testLoginIdentityRequestCompleteWithKitsAndNoUserChange {
    id mockPersistenceController = OCMClassMock([MPPersistenceController class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"1234" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @42;
    
    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogin httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testLogoutIdentityRequestCompleteWithKitsAndNoUserChange {
    id mockPersistenceController = OCMClassMock([MPPersistenceController class]);
    [[[mockPersistenceController stub] andReturn:@"42"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithUser:mockUser];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @42;
    
    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogout httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
}

- (void)testMPIdZeroToMPId {
    id mockPersistenceController = OCMClassMock([MPPersistenceController class]);
    [[[mockPersistenceController stub] andReturn:@"0"] mpId];
    
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer];
    [[[mockInstance stub] andReturn:mockPersistenceController] persistenceController];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    [[[identityMock stub] andReturn:mockUser] currentUser];
    
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"1234" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    httpResponse.mpid = @42;
    
    [[mockPersistenceController expect] moveContentFromMpidZeroToMpid:@42];
    [[mockPersistenceController reject] moveContentFromMpidZeroToMpid:@60];
    
    [identityMock onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogin httpResponse:httpResponse completion:nil error:error];
    
    [mockPersistenceController verifyWithDelay:0.2];
    
    [mockContainer stopMocking];
    [identityMock stopMocking];
    [mockInstance stopMocking];
    [mockPersistenceController stopMocking];
}

- (void)testModifyRequestComplete {
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock currentUser]).andReturn(mockUser);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"5678" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPModifySuccessResponse *httpResponse = [[MPIdentityHTTPModifySuccessResponse alloc] init];
    
    [mockUser setExpectationOrderMatters:YES];
    [[mockUser expect] setUserIdentitySync:@"5678" identityType:MPUserIdentityCustomerId];
    [[mockUser expect] setUserIdentitySync:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [[mockUser expect] setUserIdentitySync:@"other id 3" identityType:MPUserIdentityOther3];
    [[mockUser reject] setUserIdentitySync:@"other id 4" identityType:MPUserIdentityOther4];
    
    [identityMock onModifyRequestComplete:request httpResponse:httpResponse completion:nil error:error];
    
    [mockUser verify];
    
    [mockUser stopMocking];
}

- (void)testModifyRequestCompleteWithKits {
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    id mockUser = OCMClassMock([MParticleUser class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    id identityMock = OCMPartialMock(identity);
    OCMStub([identityMock currentUser]).andReturn(mockUser);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"5678" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    NSError *error;
    MPIdentityHTTPModifySuccessResponse *httpResponse = [[MPIdentityHTTPModifySuccessResponse alloc] init];

    [[mockContainer expect] forwardIdentitySDKCall:[OCMArg anySelector] kitHandler:OCMOCK_ANY];
    [identityMock onModifyRequestComplete:request httpResponse:httpResponse completion:nil error:error];
    
    [mockContainer verifyWithDelay:0.2];
    
    [mockContainer stopMocking];
    [identityMock stopMocking];
    [mockInstance stopMocking];
}

- (void)testIdentify {
    id mockManager = OCMClassMock([MPIdentityApiManager class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock apiManager]).andReturn(mockManager);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"5678" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    [[mockManager expect] identify:request completion:OCMOCK_ANY];
    
    [identityMock identify:request completion:nil];
    
    [mockManager verifyWithDelay:0.2];
}

- (void)testLogin {
    id mockManager = OCMClassMock([MPIdentityApiManager class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock apiManager]).andReturn(mockManager);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"5678" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    [[mockManager expect] loginRequest:request completion:OCMOCK_ANY];
    
    [identityMock login:request completion:nil];
    
    [mockManager verifyWithDelay:0.2];
}

- (void)testLogout {
    id mockManager = OCMClassMock([MPIdentityApiManager class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock apiManager]).andReturn(mockManager);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"5678" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    [[mockManager expect] logout:request completion:OCMOCK_ANY];
    
    [identityMock logout:request completion:nil];
    
    [mockManager verifyWithDelay:0.2];
}

- (void)testModify {
    id mockManager = OCMClassMock([MPIdentityApiManager class]);
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    MPIdentityApi *identityMock = OCMPartialMock(identity);
    OCMStub([identityMock apiManager]).andReturn(mockManager);
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"5678" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    
    [[mockManager expect] modify:request completion:OCMOCK_ANY];
    
    [identityMock modify:request completion:nil];
    
    [mockManager verifyWithDelay:0.2];
}

@end
