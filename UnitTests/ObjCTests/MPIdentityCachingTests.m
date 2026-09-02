@import mParticle_Apple_SDK;
@import mParticle_Apple_SDK_Swift;

#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "MPIdentityDTO.h"
#import "MPUserDefaultsConnector.h"

static NSString *const kMPIdentityCachingCacheKey = @"kMPIdentityCachingCachedIdentityCallsKey";
static NSString *const kMPIdentityCachingBodyData = @"kMPIdentityCachingBodyData";
static NSString *const kMPIdentityCachingStatusCode = @"kMPIdentityCachingStatusCode";
static NSString *const kMPIdentityCachingExpires = @"kMPIdentityCachingExpires";

@interface MPIdentityCachingTests : MPBaseTestCase

@property (nonatomic, strong) MPIdentityCaching *identityCaching;
@property (nonatomic, strong) MPUserDefaults *userDefaults;

@end

@implementation MPIdentityCachingTests

- (void)setUp {
    [super setUp];
    self.userDefaults = MPUserDefaultsConnector.userDefaults;
    [self.userDefaults setMPObject:nil forKey:kMPIdentityCachingCacheKey userId:@0];
    MPLog *logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:0]];
    self.identityCaching = [[MPIdentityCaching alloc] initWithUserDefaults:self.userDefaults logger:logger];
}

- (void)tearDown {
    [self.userDefaults setMPObject:nil forKey:kMPIdentityCachingCacheKey userId:@0];
    [super tearDown];
}

- (NSDictionary *)requestDictionary {
    return @{
        @"known_identities": @{
            @"ios_idfv": @"abcdefg",
            @"email": @"test1@test2.com",
            @"customerid": @"12345",
            @"google": NSNull.null
        }
    };
}

- (MPIdentityCachedResponse *)responseExpiringAfter:(NSTimeInterval)interval {
    return [[MPIdentityCachedResponse alloc] initWithBodyData:[@"response" dataUsingEncoding:NSUTF8StringEncoding]
                                                   statusCode:200
                                                      expires:[NSDate dateWithTimeIntervalSinceNow:interval]];
}

- (NSDictionary *)storedCache {
    return [self.userDefaults mpObjectForKey:kMPIdentityCachingCacheKey userId:@0];
}

- (void)testCachesAndReadsIdentifyResponseUsingStablePersistedKey {
    MPIdentityCachedResponse *response = [self responseExpiringAfter:60];

    [self.identityCaching cacheIdentityResponse:response
                                       endpoint:MPEndpointIdentityIdentify
                              requestDictionary:self.requestDictionary];

    NSString *expectedKey = @"2::6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1";
    XCTAssertNotNil(self.storedCache[expectedKey]);
    MPIdentityCachedResponse *cached = [self.identityCaching getCachedIdentityResponseForEndpoint:MPEndpointIdentityIdentify
                                                                                 requestDictionary:self.requestDictionary];
    XCTAssertEqualObjects(cached, response);
}

- (void)testOnlyLoginAndIdentifyResponsesAreCached {
    MPIdentityCachedResponse *response = [self responseExpiringAfter:60];

    [self.identityCaching cacheIdentityResponse:response
                                       endpoint:MPEndpointIdentityLogout
                              requestDictionary:self.requestDictionary];
    XCTAssertNil(self.storedCache);

    [self.identityCaching cacheIdentityResponse:response
                                       endpoint:MPEndpointIdentityLogin
                              requestDictionary:self.requestDictionary];
    XCTAssertEqual(self.storedCache.count, 1);
}

- (void)testModifyAndLogoutLookupsClearTheCache {
    MPIdentityCachedResponse *response = [self responseExpiringAfter:60];
    [self.identityCaching cacheIdentityResponse:response
                                       endpoint:MPEndpointIdentityLogin
                              requestDictionary:self.requestDictionary];

    XCTAssertNil([self.identityCaching getCachedIdentityResponseForEndpoint:MPEndpointIdentityModify
                                                           requestDictionary:self.requestDictionary]);
    XCTAssertNil(self.storedCache);

    [self.identityCaching cacheIdentityResponse:response
                                       endpoint:MPEndpointIdentityIdentify
                              requestDictionary:self.requestDictionary];
    XCTAssertNil([self.identityCaching getCachedIdentityResponseForEndpoint:MPEndpointIdentityLogout
                                                           requestDictionary:self.requestDictionary]);
    XCTAssertNil(self.storedCache);
}

- (void)testExpiredResponseIsNotReturned {
    MPIdentityCachedResponse *response = [self responseExpiringAfter:-1];
    [self.identityCaching cacheIdentityResponse:response
                                       endpoint:MPEndpointIdentityLogin
                              requestDictionary:self.requestDictionary];

    XCTAssertNil([self.identityCaching getCachedIdentityResponseForEndpoint:MPEndpointIdentityLogin
                                                           requestDictionary:self.requestDictionary]);
}

- (void)testClearAllCache {
    MPIdentityCachedResponse *response = [self responseExpiringAfter:60];
    [self.identityCaching cacheIdentityResponse:response
                                       endpoint:MPEndpointIdentityLogin
                              requestDictionary:self.requestDictionary];

    [self.identityCaching clearAllCache];

    XCTAssertNil(self.storedCache);
}

- (void)testClearExpiredCacheKeepsOnlyValidEntries {
    NSDictionary *cache = @{
        @"expired": @{
            kMPIdentityCachingBodyData: [@"expired" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [NSDate dateWithTimeIntervalSinceNow:-10]
        },
        @"valid": @{
            kMPIdentityCachingBodyData: [@"valid" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @202,
            kMPIdentityCachingExpires: [NSDate dateWithTimeIntervalSinceNow:60]
        },
        @"invalid": @"not a response"
    };
    [self.userDefaults setMPObject:cache forKey:kMPIdentityCachingCacheKey userId:@0];

    [self.identityCaching clearExpiredCache];

    XCTAssertEqual(self.storedCache.count, 1);
    XCTAssertNotNil(self.storedCache[@"valid"]);
}

- (void)testAcceptsDictionaryFromRealIdentityRequestFacade {
    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] init];
    request.knownIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:@{
        @(MPIdentityEmail): @"test@example.com",
        @(MPIdentityGoogle): NSNull.null
    }];
    NSDictionary *requestDictionary = request.dictionaryRepresentation;
    MPIdentityCachedResponse *response = [self responseExpiringAfter:60];

    [self.identityCaching cacheIdentityResponse:response
                                       endpoint:MPEndpointIdentityIdentify
                              requestDictionary:requestDictionary];

    XCTAssertEqualObjects(
        [self.identityCaching getCachedIdentityResponseForEndpoint:MPEndpointIdentityIdentify
                                                 requestDictionary:requestDictionary],
        response
    );
}

@end
