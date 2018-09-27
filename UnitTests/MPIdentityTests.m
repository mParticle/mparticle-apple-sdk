//
//  MPIdentityTests.m
//

#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPIdentityDTO.h"
#import "MPNetworkCommunication.h"
#if TARGET_OS_IOS == 1
#import "OCMock.h"
#endif
#import "MPBaseTestCase.h"
#import "MPIdentityApi.h"
#import "MPIdentityApiManager.h"

typedef NS_ENUM(NSUInteger, MPIdentityRequestType) {
    MPIdentityRequestIdentify = 0,
    MPIdentityRequestLogin = 1,
    MPIdentityRequestLogout = 2,
    MPIdentityRequestModify = 3
};

@interface MPIdentityTests : MPBaseTestCase

@end

@interface MParticleUser ()

- (void)setUserIdentitySync:(NSString *)identityString identityType:(MPUserIdentity)identityType;
- (void)setUserId:(NSNumber *)userId;
@end

@interface MPIdentityApi ()
@property (nonatomic, strong) MPIdentityApiManager *apiManager;
@property(nonatomic, strong, readwrite, nonnull) MParticleUser *currentUser;

- (void)onIdentityRequestComplete:(MPIdentityApiRequest *)request identityRequestType:(MPIdentityRequestType)identityRequestType httpResponse:(MPIdentityHTTPSuccessResponse *) httpResponse completion:(MPIdentityApiResultCallback)completion error: (NSError *) error;
- (void)onModifyRequestComplete:(MPIdentityApiRequest *)request httpResponse:(MPIdentityHTTPModifySuccessResponse *) httpResponse completion:(MPIdentityApiResultCallback)completion error: (NSError *) error;
@end
    
@interface MPNetworkCommunication ()
- (void)modifyWithIdentityChanges:(NSArray *)identityChanges blockOtherRequests:(BOOL)blockOtherRequests completion:(nullable MPIdentityApiManagerModifyCallback)completion;
- (void)identityApiRequestWithURL:(NSURL*)url identityRequest:(MPIdentityHTTPBaseRequest *_Nonnull)identityRequest blockOtherRequests: (BOOL) blockOtherRequests completion:(nullable MPIdentityApiManagerCallback)completion;
@end

#pragma mark - MPStateMachine category

@interface MPIdentityHTTPIdentities(Tests)

- (instancetype)initWithIdentities:(NSDictionary *)identities;

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

#if TARGET_OS_IOS == 1

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
#endif

@end
