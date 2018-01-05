//
//  MPIdentityTests.m
//

#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPIdentityDTO.h"

@interface MPIdentityTests : XCTestCase

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

@end
