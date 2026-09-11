#import "MPConsumerInfo.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPPersistenceUtilities.h"
#import "MPPersistenceAdapter.h"
#import "mParticle.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

NSString *const kMPCKContent = @"c";
NSString *const kMPCKDomain = @"d";
NSString *const kMPCKExpiration = @"e";

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceAdapter *persistenceAdapter;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

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
    
    MPPersistenceAdapter *persistence = [MParticle sharedInstance].persistenceAdapter;
    
    NSMutableArray<MPCookie *> *cookies = [[NSMutableArray alloc] init];
    NSArray<MPCookie *> *fetchedCookies = [persistence fetchCookiesForUserId:[MPPersistenceUtilities mpId]];
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
    NSDictionary *localCookies = [userDefaults mpObjectForKey:kMPRemoteConfigCookiesKey userId:[MPPersistenceUtilities mpId]];
    
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
