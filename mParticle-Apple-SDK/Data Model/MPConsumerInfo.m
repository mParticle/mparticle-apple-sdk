#import "MPConsumerInfo.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPPersistenceController.h"
#import "mParticle.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

NSString *const kMPCKContent = @"c";
NSString *const kMPCKDomain = @"d";
NSString *const kMPCKExpiration = @"e";

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@interface MPCookie ()
@property (nonatomic, strong) MPCookiePRIVATE *implementation;
@end

#pragma mark - MPCookie
@implementation MPCookie

- (instancetype)init {
    self = [super init];
    if (self) {
        _implementation = [[MPCookiePRIVATE alloc] init];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name configuration:(NSDictionary *)configuration {
    MPCookiePRIVATE *implementation = [[MPCookiePRIVATE alloc] initWithName:name configuration:configuration];
    if (!implementation) {
        return nil;
    }

    self = [super init];
    if (!self) {
        return nil;
    }

    _implementation = implementation;
    return self;
}

- (BOOL)isEqual:(MPCookie *)object {
    if (MPIsNull(object) || ![object isKindOfClass:[MPCookie class]]) {
        return NO;
    }
    return [self.implementation isEqualToCookie:object.implementation];
}

- (NSUInteger)hash {
    return (NSUInteger)self.implementation.hash;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];

    if (self.content) {
        [coder encodeObject:self.content forKey:@"content"];
    }
    
    if (self.domain) {
        [coder encodeObject:self.domain forKey:@"domain"];
    }
    
    if (self.expiration) {
        [coder encodeObject:self.expiration forKey:@"expiration"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    NSString *name = [coder decodeObjectForKey:@"name"];
    
    NSMutableDictionary *configuration = [[NSMutableDictionary alloc] initWithCapacity:2];
    NSString *value = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"content"];
    if (value) {
        configuration[kMPCKContent] = value;
    }
    
    value = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"domain"];
    if (value) {
        configuration[kMPCKDomain] = value;
    }
    
    value = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"expiration"];
    if (value) {
        configuration[kMPCKExpiration] = value;
    }
    
    self = [self initWithName:name configuration:configuration];
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Public accessors
- (int64_t)cookieId {
    return self.implementation.cookieId;
}

- (void)setCookieId:(int64_t)cookieId {
    self.implementation.cookieId = cookieId;
}

- (NSString *)content {
    return self.implementation.content;
}

- (void)setContent:(NSString *)content {
    self.implementation.content = content;
}

- (NSString *)domain {
    return self.implementation.domain;
}

- (void)setDomain:(NSString *)domain {
    self.implementation.domain = domain;
}

- (NSString *)expiration {
    return self.implementation.expiration;
}

- (void)setExpiration:(NSString *)expiration {
    self.implementation.expiration = expiration;
}

- (NSString *)name {
    return self.implementation.name;
}

- (void)setName:(NSString *)name {
    NSAssert(name, @"Name cannot be nil");
    self.implementation.name = name ?: @"";
}

- (BOOL)expired {
    return self.implementation.expired;
}

#pragma mark Public methods
- (NSDictionary *)dictionaryRepresentation {
    return [self.implementation dictionaryRepresentation];
}

@end

@interface MPConsumerInfo ()
@property (nonatomic, strong) MPConsumerInfoPRIVATE *implementation;
@end

#pragma mark - MPConsumerInfo
@implementation MPConsumerInfo

@synthesize cookies = _cookies;

- (id)init {
    self = [super init];
    if (self) {
        _implementation = [[MPConsumerInfoPRIVATE alloc] init];
    }
    
    return self;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.cookies) {
        [coder encodeObject:_cookies forKey:@"cookies"];
    }
    if (self.uniqueIdentifier) {
        [coder encodeObject:self.uniqueIdentifier forKey:@"uniqueIdentifier"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _implementation = [[MPConsumerInfoPRIVATE alloc] init];
        _cookies = [coder decodeObjectOfClass:[NSArray<MPCookie *> class] forKey:@"cookies"];
        _implementation.uniqueIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"uniqueIdentifier"];
    }
    
    return self;
}

- (int64_t)consumerInfoId {
    return self.implementation.consumerInfoId;
}

- (void)setConsumerInfoId:(int64_t)consumerInfoId {
    self.implementation.consumerInfoId = consumerInfoId;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Private methods
- (void)configureCookiesWithDictionary:(NSDictionary *)cookiesDictionary {
    if (MPIsNull(cookiesDictionary)) {
        return;
    }
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    NSMutableArray<MPCookie *> *cookies = [[NSMutableArray alloc] init];
    NSArray<MPCookie *> *fetchedCookies = [persistence fetchCookiesForUserId:[MPPersistenceController_PRIVATE mpId]];
    if (fetchedCookies) {
        [cookies addObjectsFromArray:fetchedCookies];
    }

    NSDictionary *localCookiesDictionary = [self localCookiesDictionary];
    if (localCookiesDictionary) {
        NSMutableDictionary *mCookiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:(localCookiesDictionary.count + cookiesDictionary.count)];
        [mCookiesDictionary addEntriesFromDictionary:localCookiesDictionary];
        [mCookiesDictionary addEntriesFromDictionary:cookiesDictionary];
        cookiesDictionary = (NSDictionary *)mCookiesDictionary;
    }
    
    NSArray *keys = [cookiesDictionary allKeys];
    for (NSString *aKey in keys) {
        if (MPIsNull(aKey)) {
            continue;
        }
        
        MPCookie *cookie = [[MPCookie alloc] initWithName:aKey configuration:cookiesDictionary[aKey]];
        
        if (cookie) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", cookie.name];
            MPCookie *existingCookie = [[cookies filteredArrayUsingPredicate:predicate] firstObject];
            
            if (existingCookie) {
                existingCookie.content = cookie.content;
                existingCookie.domain = cookie.domain;
                existingCookie.expiration = cookie.expiration;
            } else {
                [cookies addObject:cookie];
            }
        }
    }
    
    _cookies = (NSArray *)cookies;
}

- (NSDictionary *)localCookiesDictionary {
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    NSDictionary *localCookies = [userDefaults mpObjectForKey:kMPRemoteConfigCookiesKey userId:[MPPersistenceController_PRIVATE mpId]];
    
    if (!localCookies) {
        return nil;
    }
    
    NSMutableDictionary *cookiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:localCookies.count];
    NSString *key;
    
    NSEnumerator *cookiesEnumerator = [localCookies keyEnumerator];
    while ((key = [cookiesEnumerator nextObject])) {
        NSDictionary *cookieDictionary = localCookies[key];
        cookiesDictionary[key] = cookieDictionary;
    }
    
    [userDefaults removeMPObjectForKey:kMPRemoteConfigCookiesKey];
    
    return cookiesDictionary;
}

- (NSString *)uniqueIdentifier {
    if (self.implementation.uniqueIdentifier) {
        return self.implementation.uniqueIdentifier;
    }
    
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    if (userDefaults[kMPRemoteConfigUniqueIdentifierKey]) {
        NSString *uniqueIdentifier = userDefaults[kMPRemoteConfigUniqueIdentifierKey];
        [userDefaults removeMPObjectForKey:kMPRemoteConfigUniqueIdentifierKey];

        if (MPIsNull(uniqueIdentifier)) {
            uniqueIdentifier = nil;
        }
        self.implementation.uniqueIdentifier = uniqueIdentifier;
    }
    
    return self.implementation.uniqueIdentifier;
}

- (void)setUniqueIdentifier:(NSString *)uniqueIdentifier {
    [self.implementation escapeAndSetUniqueIdentifier:uniqueIdentifier];
}

- (NSString *)deviceApplicationStamp {
    __block NSString *value = nil;
    
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    value = userDefaults[kMPDeviceApplicationStampStorageKey];
    
    if (!value) {
        [self.cookies enumerateObjectsUsingBlock:^(MPCookie * _Nonnull cookie, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cookie.name isEqualToString:@"uid"]) {
                NSString *content = cookie.content;
                NSString *dummyURL = [NSString stringWithFormat:@"https://example.com/?%@", content];
                NSArray *queryItems = [[NSURLComponents alloc] initWithString:dummyURL].queryItems;
                [queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([item.name isEqualToString:@"g"]) {
                        value = item.value;
                    }
                }];
            }
        }];
        if (!value) {
            value = [NSUUID UUID].UUIDString;
        }
        userDefaults[kMPDeviceApplicationStampStorageKey] = value;
        [userDefaults synchronize];
    }
    
    return value;
}

#pragma mark Public methods
- (NSDictionary *)cookiesDictionaryRepresentation {
    if (self.cookies.count == 0) {
        return (NSDictionary *)nil;
    }
    
    NSMutableDictionary *cookiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:self.cookies.count];
    
    for (MPCookie *cookie in _cookies) {
        NSDictionary *cookieDictionary = [cookie dictionaryRepresentation];

        if (cookieDictionary) {
            cookiesDictionary[cookie.name] = cookieDictionary;
        }
    }
    
    if (cookiesDictionary.count == 0) {
        return (NSDictionary *)nil;
    }
    
    return (NSDictionary *)cookiesDictionary;
}

- (void)updateWithConfiguration:(NSDictionary *)configuration {
    if (MPIsNull(configuration) || ![configuration isKindOfClass:[NSDictionary class]] || configuration.count == 0) {
        return;
    }
    
    [self configureCookiesWithDictionary:configuration[kMPRemoteConfigCookiesKey]];
}

@end
