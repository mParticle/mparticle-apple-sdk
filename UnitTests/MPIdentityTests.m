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

@interface MPIdentityTests : MPBaseTestCase

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

#endif

@end
