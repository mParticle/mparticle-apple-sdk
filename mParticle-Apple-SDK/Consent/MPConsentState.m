#import "MPConsentState.h"
#import "MPGDPRConsent.h"
#import "MPIConstants.h"
#import "MPILogger.h"

@interface MPConsentState () {
    NSMutableDictionary<NSString *, MPGDPRConsent *> *_gdprConsentState;
}

@end

@implementation MPConsentState

- (instancetype)init
{
    self = [super init];
    if (self) {
        _gdprConsentState = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (nullable NSString *)canonicalizeForDeduplication:(nullable NSString *)source {
    if (MPIsNull(source) || source.length == 0) {
        return nil;
    }
    
    return [[source lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSDictionary<NSString *, MPGDPRConsent *> *)gdprConsentState {
    return [_gdprConsentState copy];
}

- (void)addGDPRConsentState:(MPGDPRConsent *)consent purpose:(NSString *)purpose {
    
    NSString *normalizedPurpose = [MPConsentState canonicalizeForDeduplication:purpose];
    
    if (!normalizedPurpose) {
        MPILogError(@"Cannot set GDPR Consent with nil, NSNull or empty purpose.")
        return;
    }
    
    if (MPIsNull(consent)) {
        MPILogError("Cannot set GDPR Consent with nil or NSNull GDPRConsent object.");
        return;
    }
    
    _gdprConsentState[normalizedPurpose] = consent;
}

- (void)removeGDPRConsentStateWithPurpose:(NSString *)purpose {
    
    NSString *normalizedPurpose = [MPConsentState canonicalizeForDeduplication:purpose];
    if (!normalizedPurpose) {
        MPILogError(@"Cannot remove GDPR Consent with nil, NSNull or empty purpose.")
        return;
    }
    
    [_gdprConsentState removeObjectForKey:normalizedPurpose];
}

- (void)setGDPRConsentState:(nullable NSDictionary<NSString *, MPGDPRConsent *> *)consentState {
    if ((NSNull *)consentState == [NSNull null]) {
        MPILogError(@"Cannot set GDPR Consent with NSNull.")
        return;
    }
    
    [_gdprConsentState removeAllObjects];
    
    if (!consentState || consentState.count == 0) {
        return;
    }
    
    NSDictionary *consentStateCopy = [consentState copy];
    for (NSString *purpose in consentStateCopy) {
        MPGDPRConsent *consent = consentStateCopy[purpose];
        [self addGDPRConsentState:consent purpose:purpose];
    }
}

@end
