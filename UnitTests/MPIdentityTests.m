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

    [[[mockUser stub] andReturn:mockUser] alloc];
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"1234" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    [request setUserIdentity:@"other id 4" identityType:MPUserIdentityOther4];
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    NSError *error;
    MPIdentityHTTPSuccessResponse *httpResponse = [[MPIdentityHTTPSuccessResponse alloc] init];
    
    [mockUser setExpectationOrderMatters:YES];
    [[[mockUser expect] ignoringNonObjectArgs] setUserIdentitySync:OCMOCK_ANY identityType:MPUserIdentityCustomerId];
    [[[mockUser expect] ignoringNonObjectArgs] setUserIdentitySync:OCMOCK_ANY identityType:MPUserIdentityEmail];
    [[[mockUser expect] ignoringNonObjectArgs] setUserIdentitySync:OCMOCK_ANY identityType:MPUserIdentityOther3];
    [[[mockUser expect] ignoringNonObjectArgs] setUserIdentitySync:OCMOCK_ANY identityType:MPUserIdentityOther4];
    
    [identity onIdentityRequestComplete:request identityRequestType:MPIdentityRequestLogin httpResponse:httpResponse completion:nil error:error];

    [mockUser verify];
}

- (void)testModifyRequestComplete {
    id mockUser = OCMClassMock([MParticleUser class]);
    
    [[[mockUser stub] andReturn:mockUser] alloc];
    
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"1234" identityType:MPUserIdentityCustomerId];
    [request setUserIdentity:@"me@gmail.com" identityType:MPUserIdentityEmail];
    [request setUserIdentity:@"other id 3" identityType:MPUserIdentityOther3];
    [request setUserIdentity:@"other id 4" identityType:MPUserIdentityOther4];
    
    MPIdentityApi *identity = [[MPIdentityApi alloc] init];
    NSError *error;
    MPIdentityHTTPModifySuccessResponse *httpResponse = [[MPIdentityHTTPModifySuccessResponse alloc] init];
    
    [mockUser setExpectationOrderMatters:YES];
    [[[mockUser expect] ignoringNonObjectArgs] setUserIdentitySync:OCMOCK_ANY identityType:MPUserIdentityCustomerId];
    [[[mockUser expect] ignoringNonObjectArgs] setUserIdentitySync:OCMOCK_ANY identityType:MPUserIdentityEmail];
    [[[mockUser expect] ignoringNonObjectArgs] setUserIdentitySync:OCMOCK_ANY identityType:MPUserIdentityOther3];
    [[[mockUser expect] ignoringNonObjectArgs] setUserIdentitySync:OCMOCK_ANY identityType:MPUserIdentityOther4];
    
    [identity onModifyRequestComplete:request httpResponse:httpResponse completion:nil error:error];
    
    [mockUser verify];
}
#endif

@end
