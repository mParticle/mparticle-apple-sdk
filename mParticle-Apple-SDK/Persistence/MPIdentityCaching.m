//
//  MPIdentityCaching.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 12/12/23.
//

#import "MPIdentityCaching.h"
#import "MPILogger.h"
#import "mParticle.h"
#import <CommonCrypto/CommonCrypto.h>
#import "MParticleSwift.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

// User defaults key
static NSString *const kMPIdentityCachingCachedIdentityCallsKey = @"kMPIdentityCachingCachedIdentityCallsKey";

// Dictionary keys
static NSString *const kMPIdentityCachingBodyData = @"kMPIdentityCachingBodyData";
static NSString *const kMPIdentityCachingStatusCode = @"kMPIdentityCachingStatusCode";
static NSString *const kMPIdentityCachingExpires = @"kMPIdentityCachingExpires";

@interface MPIdentityCachedResponse()
@property (nonnull, nonatomic, readwrite) NSData *bodyData;
@property (nonatomic, readwrite) NSInteger statusCode;
@property (nonnull, nonatomic, readwrite) NSDate *expires;
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;
@end

@implementation MPIdentityCachedResponse

- (nonnull instancetype)initWithBodyData:(nonnull NSData *)bodyData statusCode:(NSInteger)statusCode expires:(nonnull NSDate *)expires {
    if (self = [super init]) {
        _bodyData = bodyData;
        _statusCode = statusCode;
        _expires = expires;
    }
    return self;
}

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if ([dictionary count] != 3) {
        return nil;
    }
    
    NSData *bodyData = dictionary[kMPIdentityCachingBodyData];
    NSNumber *statusCode = dictionary[kMPIdentityCachingStatusCode];
    NSDate *expires = dictionary[kMPIdentityCachingExpires];
    if (bodyData == nil || statusCode == nil || expires == nil) {
        return nil;
    }
    
    if (self = [super init]) {
        _bodyData = bodyData;
        _statusCode = [statusCode integerValue];
        _expires = expires;
    }
    return self;
}

- (nonnull NSDictionary *)dictionaryRepresentation {
    return @{
        kMPIdentityCachingBodyData: _bodyData,
        kMPIdentityCachingStatusCode: @(_statusCode),
        kMPIdentityCachingExpires: _expires
    };
}

- (NSUInteger)hash {
    return _bodyData.hash ^ _statusCode ^ _expires.hash;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
    MPIdentityCachedResponse *rhs = object;
    return [_bodyData isEqualToData:rhs.bodyData] && _statusCode == rhs.statusCode && [_expires isEqualToDate:rhs.expires];
}

@end

@implementation MPIdentityCaching

#pragma mark - Public

+ (void)cacheIdentityResponse:(nonnull MPIdentityCachedResponse *)cachedResponse endpoint:(MPEndpoint)endpoint identityRequest:(nonnull MPIdentityHTTPBaseRequest *)identityRequest {
    NSDictionary *identities = [self identitiesFromIdentityRequest:identityRequest];
    return [self cacheIdentityResponse:cachedResponse endpoint:endpoint identities:identities];
}

+ (nullable MPIdentityCachedResponse *)getCachedIdentityResponseForEndpoint:(MPEndpoint)endpoint identityRequest:(nonnull MPIdentityHTTPBaseRequest *)identityRequest {
    if (endpoint == MPEndpointIdentityIdentify || endpoint == MPEndpointIdentityLogin) {
        // Cache identify and login calls
        NSDictionary *identities = [self identitiesFromIdentityRequest:identityRequest];
        return [self getCachedIdentityResponseForEndpoint:endpoint identities:identities];
    } else if (endpoint == MPEndpointIdentityModify || endpoint == MPEndpointIdentityLogout) {
        // Clear cache on modify and logout calls
        [self clearAllCache];
    }
    return nil;
}

+ (void)cacheIdentityResponse:(nonnull MPIdentityCachedResponse *)cachedResponse endpoint:(MPEndpoint)endpoint identities:(nonnull NSDictionary *)identities {
    // Only cache identify and login calls
    if (endpoint == MPEndpointIdentityIdentify || endpoint == MPEndpointIdentityLogin) {
        NSString *key = [self keyWithEndpoint:endpoint identities:identities];
        if (key.length == 0) {
            return;
        }
        
        NSDictionary *cache = [self getCache] ?: @{};
        NSMutableDictionary *mutableCache = [cache mutableCopy];
        [mutableCache setObject:cachedResponse.dictionaryRepresentation forKey:key];
        [self setCache:mutableCache];
        MPILogVerbose(@"Identity Caching - Cached response for endpoint %ld, key: %@, expires: %@, bodyData.length: %lu", (long)endpoint, key, cachedResponse.expires, (unsigned long)cachedResponse.bodyData.length);
    }
}

+ (nullable MPIdentityCachedResponse *)getCachedIdentityResponseForEndpoint:(MPEndpoint)endpoint identities:(nonnull NSDictionary *)identities {
    NSDictionary *cache = [self getCache];
    NSString *key = [self keyWithEndpoint:endpoint identities:identities];
    if (key.length == 0) {
        return nil;
    }
    
    NSDictionary *dictionary = [cache objectForKey:key];
    if (!dictionary) {
        return nil;
    }
    
    MPIdentityCachedResponse *cachedResponse = [[MPIdentityCachedResponse alloc] initWithDictionary:dictionary];
    NSDate *now = [NSDate date];
    if (!cachedResponse) {
        MPILogVerbose(@"Identity Caching - No cached response found for key: %@", key);
    }
    if (!cachedResponse || [now timeIntervalSinceDate:cachedResponse.expires] > 0) {
        MPILogVerbose(@"Identity Caching - Expired cached response found for key: %@, expired: %@, seconds since expired: %.1f", key, cachedResponse.expires, [now timeIntervalSinceDate:cachedResponse.expires]);
        return nil;
    }
    MPILogVerbose(@"Identity Caching - Valid cached response found for key: %@, expires: %@, seconds left: %.1f", key, cachedResponse.expires, [cachedResponse.expires timeIntervalSinceDate:now]);
    return cachedResponse;
}

+ (void)clearAllCache {
    [self setCache:nil];
    MPILogVerbose(@"Identity Caching - Removed all cached responses");
}

+ (void)clearExpiredCache {
    NSDictionary *cache = [self getCache];
    NSMutableDictionary *mutableCache = [cache mutableCopy];
    __block int numberRemoved = 0;
    [cache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDate *expires = [obj objectForKey:kMPIdentityCachingExpires];
            if (!expires || [expires timeIntervalSinceDate:[NSDate date]] < 0) {
                [mutableCache removeObjectForKey:key];
                numberRemoved++;
            }
        } else {
            // Invalid cache data, remove from cache
            [mutableCache removeObjectForKey:key];
            numberRemoved++;
        }
    }];
    
    MPILogVerbose(@"Identity Caching - Removed %d expired cached responses", numberRemoved);
    
    if ([cache count] != [mutableCache count]) {
        [self setCache:mutableCache];
    }
}

#pragma mark - Private

+ (nullable NSDictionary<NSString*, NSDictionary*> *)getCache {
    return [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] mpObjectForKey:kMPIdentityCachingCachedIdentityCallsKey userId:@0];
}

+ (void)setCache:(nullable NSDictionary<NSString*, NSDictionary*> *)cache {
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setMPObject:cache forKey:kMPIdentityCachingCachedIdentityCallsKey userId:@0];
}

+ (nullable NSString *)keyWithEndpoint:(MPEndpoint)endpoint identities:(nonnull NSDictionary *)identities {
    NSString *hash = [self hashIdentities:identities];
    if (!hash) {
        return nil;
    }
    NSString *key = [NSString stringWithFormat:@"%ld::%@", (long)endpoint, hash];
    return key;
}

+ (nullable NSDictionary *)identitiesFromIdentityRequest:(nonnull MPIdentityHTTPBaseRequest *)identityRequest {
    NSDictionary *dict = identityRequest.dictionaryRepresentation;
    
    // Identify and Login requests include a known identities dictionary which can be used for the cache key
    NSDictionary *knownIdentities = dict[@"known_identities"];
    if (knownIdentities) {
        return knownIdentities;
    }
    
    // Modify requests include an array of identity changes which need to be converted to a dictionary first
    NSArray *identityChanges = dict[@"identity_changes"];
    if (identityChanges) {
        // The data format should be an array of dictionaries, each of which should always have an identity_type key
        // We can use this key as the dictionary key as there can only be one of each type
        // If for some reason it doesn't exist, bail and don't cache
        NSMutableDictionary *identities = [[NSMutableDictionary alloc] initWithCapacity:identityChanges.count];
        for (NSDictionary *change in identityChanges) {
            if (![change isKindOfClass:[NSDictionary class]]) {
                return nil;
            }
            
            NSString *identityType = change[@"identity_type"];
            if (![identityType isKindOfClass:[NSString class]]) {
                return nil;
            }
            // Hash the dictionary to get a reproducible string value
            identities[identityType] = [self hashIdentities:change];
        }
        return identities;
    }
    
    return nil;
}

+ (nullable NSString *)hashIdentities:(NSDictionary *)identities {
    NSString *serializedIdentities = [self serializeIdentities:identities];
    if (!serializedIdentities) {
        return nil;
    }
    
    NSString *hashedString = [self sha256Hash:serializedIdentities];
    return hashedString;
}

+ (nullable NSString *)serializeIdentities:(NSDictionary *)identities {
    NSArray *sortedKeys = [identities.allKeys sortedArrayUsingSelector: @selector(compare:)];
    NSMutableString *serializedString = [[NSMutableString alloc] init];
    for (NSString *key in sortedKeys) {
        [serializedString appendFormat:@"::%@", key];
        
        // Can be either a string or NSNull
        NSObject *value = identities[key];
        if ([value isKindOfClass:[NSString class]]) {
            [serializedString appendFormat:@":%@", (NSString *)value];
        } else if ([value isKindOfClass:[NSNull class]]) {
            [serializedString appendString:@":null"];
        } else {
            // This should never happen, so return nil
            return nil;
        }
    }
    
    return serializedString;
}

+ (nullable NSString *)sha256Hash:(NSString *)string {
    NSData *dataIn = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!dataIn || dataIn.length == 0) {
        return nil;
    }
    
    NSMutableData *dataOut = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(dataIn.bytes, (CC_LONG)dataIn.length, dataOut.mutableBytes);
    
    const uint8_t *dataOutBytes = dataOut.bytes;
    NSMutableString *hexString = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hexString appendFormat:@"%02x", dataOutBytes[i]];
    }
    return hexString;
}

@end
