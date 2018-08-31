#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "MPIdentityApiRequest.h"

@interface MPIdentityApiRequestTests : MPBaseTestCase

@end

@implementation MPIdentityApiRequestTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSetNilIdentity {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"foo" identityType:MPUserIdentityOther];
    XCTAssertEqualObjects(@"foo", [request.userIdentities objectForKey:@(MPUserIdentityOther)]);
    [request setUserIdentity:nil identityType:MPUserIdentityOther];
    XCTAssertEqual([NSNull null], [request.userIdentities objectForKey:@(MPUserIdentityOther)]);
}

- (void)testSetNullIdentity {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"foo" identityType:MPUserIdentityOther];
    XCTAssertEqualObjects(@"foo", [request.userIdentities objectForKey:@(MPUserIdentityOther)]);
    [request setUserIdentity:(id)[NSNull null] identityType:MPUserIdentityOther];
    XCTAssertEqual([NSNull null], [request.userIdentities objectForKey:@(MPUserIdentityOther)]);
}

- (void)testSetUserIdentity {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setUserIdentity:@"foo" identityType:MPUserIdentityOther];
    XCTAssertEqualObjects(@"foo", [request.userIdentities objectForKey:@(MPUserIdentityOther)]);
    
    [request setUserIdentity:@"bar" identityType:MPUserIdentityOther];
    XCTAssertEqualObjects(@"bar", [request.userIdentities objectForKey:@(MPUserIdentityOther)]);
}

@end
