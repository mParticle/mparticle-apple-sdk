#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "MPIdentityApiRequest.h"

@interface MPIdentityApiRequestTests : MPBaseTestCase

@end

@interface MPIdentityApiRequest ()
@property (nonatomic) NSMutableDictionary<NSNumber*, NSObject*> *mutableIdentities;
@end

@implementation MPIdentityApiRequestTests

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

- (void)testSetIdentity {
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

- (void)testSetEmail {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    XCTAssertNil(request.email);
    request.email = @"test@test.com";
    XCTAssertEqualObjects(@"test@test.com", request.email);
    XCTAssertEqualObjects(@"test@test.com", request.mutableIdentities[@(MPIdentityEmail)]);
    
    request.email = nil;
    XCTAssertNil(request.email);
    XCTAssertEqualObjects(request.mutableIdentities[@(MPIdentityEmail)], [NSNull null]);
}

- (void)testSetCustomerId {
    MPIdentityApiRequest *request = [[MPIdentityApiRequest alloc] init];
    XCTAssertNil(request.customerId);
    request.customerId = @"some id";
    XCTAssertEqualObjects(@"some id", request.customerId);
    XCTAssertEqualObjects(@"some id", request.mutableIdentities[@(MPIdentityCustomerId)]);
    
    request.customerId = nil;
    XCTAssertNil(request.customerId);
    XCTAssertEqualObjects(request.mutableIdentities[@(MPIdentityCustomerId)], [NSNull null]);
}

@end
