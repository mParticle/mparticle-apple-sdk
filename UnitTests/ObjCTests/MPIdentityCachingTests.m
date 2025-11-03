#ifndef MPARTICLE_LOCATION_DISABLE
@import mParticle_Apple_SDK;
#else
@import mParticle_Apple_SDK_NoLocation;
#endif

#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "MPIdentityCaching.h"
#import "MPIdentityDTO.h"

// Dictionary keys
static NSString *const kMPIdentityCachingBodyData = @"kMPIdentityCachingBodyData";
static NSString *const kMPIdentityCachingStatusCode = @"kMPIdentityCachingStatusCode";
static NSString *const kMPIdentityCachingExpires = @"kMPIdentityCachingExpires";

@interface MPIdentityCachedResponse()
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary;
@end

@interface MPIdentityCaching()
+ (void)cacheIdentityResponse:(nonnull MPIdentityCachedResponse *)cachedResponse endpoint:(MPEndpoint)endpoint identities:(nonnull NSDictionary *)identities;
+ (nullable MPIdentityCachedResponse *)getCachedIdentityResponseForEndpoint:(MPEndpoint)endpoint identities:(nonnull NSDictionary *)identities;
+ (nullable NSDictionary<NSString*, NSDictionary*> *)getCache;
+ (void)setCache:(nullable NSDictionary<NSString*, NSDictionary*> *)cache;
+ (nullable NSString *)keyWithEndpoint:(MPEndpoint)endpoint identities:(nonnull NSDictionary *)identities;
+ (nullable NSDictionary *)identitiesFromIdentityRequest:(nonnull MPIdentityHTTPBaseRequest *)identityRequest;
+ (nullable NSString *)hashIdentities:(NSDictionary *)identities;
+ (nullable NSString *)serializeIdentities:(NSDictionary *)identities;
+ (nullable NSString *)sha256Hash:(NSString *)string;
@end

@interface MPIdentityCachingTests : MPBaseTestCase
@end

@implementation MPIdentityCachingTests

- (void)setUp {
    [super setUp];
    [MPIdentityCaching setCache:nil];
}

- (void)testGetCachedResponse {
    NSDictionary *identities = @{
        @"ios_idfv": @"abcdefg",
        @"email": @"test1@test2.com",
        @"customerid": @"12345",
        @"google": [NSNull null]
    };
    
    NSDictionary *cache = @{
        @"0::6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1": @{
            kMPIdentityCachingBodyData: [@"0" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [NSDate date] // Expired
        },
        @"1::6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1": @{
            kMPIdentityCachingBodyData: [@"1" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:50] // Valid
        },
        @"2::6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1": @{
            kMPIdentityCachingBodyData: [@"2" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:-100] // Expired
        },
        @"3::6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1": @{
            kMPIdentityCachingBodyData: [@"3" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:8000] // Valid
        }
    };
    [MPIdentityCaching setCache:cache];
    
    // Test valid match
    MPIdentityCachedResponse *cached1 = [MPIdentityCaching getCachedIdentityResponseForEndpoint:MPEndpointIdentityLogout identities:identities];
    NSDictionary *dict1 = [cache objectForKey:@"1::6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1"];
    MPIdentityCachedResponse *original1 = [[MPIdentityCachedResponse alloc] initWithDictionary:dict1];
    XCTAssertEqualObjects(cached1, original1);
    
    // Test expired match
    MPIdentityCachedResponse *cached2 = [MPIdentityCaching getCachedIdentityResponseForEndpoint:MPEndpointIdentityLogin identities:identities];
    XCTAssertNil(cached2);
    
    // Test partial match
    NSDictionary *partialIdentities = @{
        @"email": @"test1@test2.com",
        @"customerid": @"12345"
    };
    MPIdentityCachedResponse *cached3 = [MPIdentityCaching getCachedIdentityResponseForEndpoint:MPEndpointIdentityModify identities:partialIdentities];
    XCTAssertNil(cached3);
    
    // Test no match
    NSDictionary *noMatchIdentities = @{
        @"MPIdentityEmail": @"test5@test10.com",
        @"MPIdentityCustomerId": @"67890"
    };
    MPIdentityCachedResponse *cached4 = [MPIdentityCaching getCachedIdentityResponseForEndpoint:MPEndpointIdentityModify identities:noMatchIdentities];
    XCTAssertNil(cached4);
}

- (void)testSetGetCache {
    NSDictionary *cache = @{
        @"0::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"0" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [NSDate date] // Expired
        },
        @"1::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"1" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:50] // Valid
        },
        @"2::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"2" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:-100] // Expired
        },
        @"3::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"3" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:8000] // Valid
        }
    };
    
    XCTAssertNil([MPIdentityCaching getCache]);
    
    [MPIdentityCaching setCache:cache];
    XCTAssertEqualObjects(cache, [MPIdentityCaching getCache]);
}

- (void)testClearAllCache {
    NSDictionary *cache = @{
        @"0::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"0" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [NSDate date] // Expired
        },
        @"1::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"1" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:50] // Valid
        },
        @"2::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"2" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:-100] // Expired
        },
        @"3::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"3" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:8000] // Valid
        }
    };
    [MPIdentityCaching setCache:cache];
    XCTAssertEqualObjects(cache, [MPIdentityCaching getCache]);
    
    [MPIdentityCaching clearAllCache];
    XCTAssertNil([MPIdentityCaching getCache]);
}

- (void)testClearExpiredCache {
    NSDictionary *cache = @{
        @"0::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"0" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [NSDate date] // Expired
        },
        @"1::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"1" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:50] // Valid
        },
        @"2::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"2" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:-100] // Expired
        },
        @"3::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d": @{
            kMPIdentityCachingBodyData: [@"3" dataUsingEncoding:NSUTF8StringEncoding],
            kMPIdentityCachingStatusCode: @200,
            kMPIdentityCachingExpires: [[NSDate date] dateByAddingTimeInterval:8000] // Valid
        }
    };
    
    NSMutableDictionary *onlyValidCache = [cache mutableCopy];
    [onlyValidCache removeObjectForKey:@"0::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d"];
    [onlyValidCache removeObjectForKey:@"2::fd54ce706ef89564f0d25321dc38cefce06fc0b886aae7c71f38e293fb67789d"];
    
    [MPIdentityCaching setCache:cache];
    XCTAssertEqualObjects(cache, [MPIdentityCaching getCache]);
    
    [MPIdentityCaching clearExpiredCache];
    XCTAssertEqualObjects(onlyValidCache, [MPIdentityCaching getCache]);
}

- (void)testKeyWithEndpointAndIdentities {
    NSDictionary *identities = @{
        @"ios_idfv": @"abcdefg",
        @"email": @"test1@test2.com",
        @"customerid": @"12345",
        @"google": [NSNull null]
    };
    
    NSString *key1 = [MPIdentityCaching keyWithEndpoint:MPEndpointIdentityLogin identities:identities];
    XCTAssertEqualObjects(key1, @"0::6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1");
    
    NSString *key2 = [MPIdentityCaching keyWithEndpoint:MPEndpointIdentityLogout identities:identities];
    XCTAssertEqualObjects(key2, @"1::6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1");
    
    NSString *key3 = [MPIdentityCaching keyWithEndpoint:MPEndpointIdentityIdentify identities:identities];
    XCTAssertEqualObjects(key3, @"2::6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1");
    
    NSString *key4 = [MPIdentityCaching keyWithEndpoint:MPEndpointIdentityModify identities:identities];
    XCTAssertEqualObjects(key4, @"3::6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1");
}

- (void)testIdentitiesFromIdentifyHTTPRequest {
    MPIdentifyHTTPRequest *identifyRequest = [[MPIdentifyHTTPRequest alloc] init];
    identifyRequest.knownIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:@{
        @(MPIdentityIOSVendorId): @"abcdefg",
        @(MPIdentityEmail): @"test1@test2.com",
        @(MPIdentityCustomerId): @"12345",
        @(MPIdentityGoogle): [NSNull null]
    }];
    
    NSDictionary *identities = [MPIdentityCaching identitiesFromIdentityRequest:identifyRequest];
    NSDictionary *expected = @{
        @"ios_idfv": @"abcdefg",
        @"email": @"test1@test2.com",
        @"customerid": @"12345",
        @"google": [NSNull null]
    };
    XCTAssertEqualObjects(identities, expected);
}

- (void)testIdentitiesFromModifyHTTPRequest {
    MPIdentityHTTPModifyRequest *modifyRequest = [[MPIdentityHTTPModifyRequest alloc] initWithIdentityChanges:@[
        [[MPIdentityHTTPIdentityChange alloc] initWithOldValue:@"test1@test1.com" value:@"test2@test2.com" identityType:@"email"],
        [[MPIdentityHTTPIdentityChange alloc] initWithOldValue:nil value:@"12345" identityType:@"customerid"],
        [[MPIdentityHTTPIdentityChange alloc] initWithOldValue:@"1234" value:@"5678" identityType:@"other2"]
    ]];
    
    NSDictionary *identities = [MPIdentityCaching identitiesFromIdentityRequest:modifyRequest];
    NSDictionary *expected = @{
        @"email": @"f7d23cbd1bf6f52cb02dc284975e82d6736e7f78c91debe52b8ff662a91bba3f",
        @"customerid": @"01b5fceb64d02bf05e06b21e733ad2352f603535c278b1c5da37f7d36e51ed57",
        @"other2": @"e544742c897e61c4a4d6fddf3bec3182ba9f611a5f6b6c6bc4b20cfdf4bd7495"
    };
    XCTAssertEqualObjects(identities, expected);
}

- (void)testHashIdentities {
    NSString *hash1 = [MPIdentityCaching hashIdentities:nil];
    XCTAssertNil(hash1);
    
    NSString *hash2 = [MPIdentityCaching hashIdentities:@{}];
    XCTAssertNil(hash2);
    
    NSDictionary *dict3 = @{
        @(MPIdentityEmail): @"test@test.com"
    };
    NSString *hash3 = [MPIdentityCaching hashIdentities:dict3];
    XCTAssertEqualObjects(hash3, @"c610ba538a9a66cd34b4eb0bc7937ce944bbcf48ca292d500ed85b805aca3e02");

    NSDictionary *dict4 = @{
        @"ios_idfv": @"abcdefg",
        @"email": @"test1@test2.com",
        @"customerid": @"12345",
        @"google": [NSNull null]
    };
    NSString *hash4 = [MPIdentityCaching hashIdentities:dict4];
    XCTAssertEqualObjects(hash4, @"6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1");
}

- (void)testSerializeIdentities {
    NSString *string1 = [MPIdentityCaching serializeIdentities:nil];
    XCTAssertEqualObjects(string1, @"");
    
    NSString *string2 = [MPIdentityCaching serializeIdentities:@{}];
    XCTAssertEqualObjects(string2, @"");
    
    NSDictionary *dict3 = @{
        @(MPIdentityEmail): @"test@test.com"
    };
    NSString *string3 = [MPIdentityCaching serializeIdentities:dict3];
    XCTAssertEqualObjects(string3, @"::7:test@test.com");
    
    NSDictionary *dict4 = @{
        @"ios_idfv": @"abcdefg",
        @"email": @"test1@test2.com",
        @"customerid": @"12345",
        @"google": [NSNull null]
    };
    NSString *string4 = [MPIdentityCaching serializeIdentities:dict4];
    XCTAssertEqualObjects(string4, @"::customerid:12345::email:test1@test2.com::google:null::ios_idfv:abcdefg");
}

- (void)testSha256Hash {
    NSString *hash1 = [MPIdentityCaching sha256Hash:nil];
    XCTAssertNil(hash1);
    
    NSString *hash2 = [MPIdentityCaching sha256Hash:@""];
    XCTAssertNil(hash2);
    
    NSString *hash3 = [MPIdentityCaching sha256Hash:@"::email:test@test.com::customerid:12435"];
    XCTAssertEqualObjects(hash3, @"aa58bbc1adccecb75fbb00cf9f424ca2098b8b7273a235a07c473b1b129810b5");
    
    NSString *hash4 = [MPIdentityCaching sha256Hash:@"::email:null"];
    XCTAssertEqualObjects(hash4, @"46bdfb15bd51f77b7955516d3ac92ec1a90856cac70e9343c510cf39532d2007");
}

@end
