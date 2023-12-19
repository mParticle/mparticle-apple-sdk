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
    [request setIdentity:@"foo" identityType:MPIdentityOther];
    XCTAssertEqualObjects(@"foo", [request.identities objectForKey:@(MPIdentityOther)]);
    [request setIdentity:nil identityType:MPIdentityOther];
    XCTAssertEqualObjects([NSNull null], [request.identities objectForKey:@(MPIdentityOther)]);
}

- (void)testSetNullIdentity {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"foo" identityType:MPIdentityOther];
    XCTAssertEqualObjects(@"foo", [request.identities objectForKey:@(MPIdentityOther)]);
    [request setIdentity:(id)[NSNull null] identityType:MPIdentityOther];
    XCTAssertEqualObjects([NSNull null], [request.identities objectForKey:@(MPIdentityOther)]);
}

- (void)testsetIdentity {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    [request setIdentity:@"foo" identityType:MPIdentityOther];
    XCTAssertEqualObjects(@"foo", [request.identities objectForKey:@(MPIdentityOther)]);
    
    [request setIdentity:@"bar" identityType:MPIdentityOther];
    XCTAssertEqualObjects(@"bar", [request.identities objectForKey:@(MPIdentityOther)]);
}

- (void)testImmutableIdentitiesProperty {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    id identities = request.identities;
    BOOL isImmutableKind = [identities isKindOfClass:[NSDictionary class]];
    BOOL isMutableKind = [identities isKindOfClass:[NSMutableDictionary class]];
    XCTAssert(isImmutableKind && !isMutableKind);
}

- (void)testIdentitiesAreNotNull {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    request.customerId = nil;
    request.email = nil;
    XCTAssertNotEqualObjects(request.email, [NSNull null]);
    XCTAssertNotEqualObjects(request.customerId, [NSNull null]);
}

@end
