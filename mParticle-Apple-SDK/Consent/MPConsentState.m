#import "MPConsentState.h"
#import "MPCCPAConsent.h"
#import "MPGDPRConsent.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "mParticle.h"
@import mParticle_Apple_SDK_Swift;

@interface MPGDPRConsent ()
@property (nonatomic, strong) MPConsentRecordPRIVATE *implementation;
- (instancetype)initWithConsentRecord:(MPConsentRecordPRIVATE *)record;
@end

@interface MPCCPAConsent ()
@property (nonatomic, strong) MPConsentRecordPRIVATE *implementation;
- (instancetype)initWithConsentRecord:(MPConsentRecordPRIVATE *)record;
@end

@interface MPConsentState ()
@property (nonatomic, strong) MPConsentStatePRIVATE *implementation;
@end

@implementation MPConsentState

- (instancetype)init {
    self = [super init];
    if (self) {
        _implementation = [[MPConsentStatePRIVATE alloc] init];
    }
    return self;
}

+ (nullable NSString *)canonicalizeForDeduplication:(nullable NSString *)source {
    return [MPConsentStatePRIVATE canonicalizeForDeduplication:source];
}

- (nullable NSDictionary<NSString *, MPGDPRConsent *> *)gdprConsentState {
    NSDictionary *records = [self.implementation gdprConsentRecords];
    NSMutableDictionary<NSString *, MPGDPRConsent *> *state = [NSMutableDictionary dictionaryWithCapacity:records.count];
    for (NSString *purpose in records) {
        MPConsentRecordPRIVATE *record = records[purpose];
        if (![record isKindOfClass:[MPConsentRecordPRIVATE class]]) {
            continue;
        }
        state[purpose] = [[MPGDPRConsent alloc] initWithConsentRecord:record];
    }
    return [state copy];
}

- (void)addGDPRConsentState:(MPGDPRConsent *)consent purpose:(NSString *)purpose {
    MPConsentStateMutationResult result;
    if (MPIsNull(consent)) {
        result = MPConsentStateMutationResultInvalidConsent;
    } else {
        result = [self.implementation addGDPRConsentRecord:consent.implementation purpose:purpose];
    }
    switch (result) {
        case MPConsentStateMutationResultInvalidPurpose:
            MPILogError(@"Cannot set GDPR Consent with nil, NSNull or empty purpose.")
            break;
        case MPConsentStateMutationResultInvalidConsent:
            MPILogError("Cannot set GDPR Consent with nil or NSNull GDPRConsent object.");
            break;
        case MPConsentStateMutationResultTooManyPurposes:
            MPILogError("Cannot add more than %@ GDPR consent states.", @(MPConsentStatePRIVATE.maxGDPRConsentPurposes));
            break;
        case MPConsentStateMutationResultSuccess:
            break;
    }
}

- (void)removeGDPRConsentStateWithPurpose:(NSString *)purpose {
    MPConsentStateMutationResult result = [self.implementation removeGDPRConsentRecordWithPurpose:purpose];
    if (result == MPConsentStateMutationResultInvalidPurpose) {
        MPILogError(@"Cannot remove GDPR Consent with nil, NSNull or empty purpose.")
    }
}

- (void)setGDPRConsentState:(nullable NSDictionary<NSString *, MPGDPRConsent *> *)consentState {
    if ((NSNull *)consentState == [NSNull null]) {
        MPILogError(@"Cannot set GDPR Consent with NSNull.")
        return;
    }

    [self.implementation removeAllGDPRConsentRecords];

    if (!consentState || consentState.count == 0) {
        return;
    }

    NSDictionary *consentStateCopy = [consentState copy];
    for (NSString *purpose in consentStateCopy) {
        [self addGDPRConsentState:consentStateCopy[purpose] purpose:purpose];
    }
}

- (nullable MPCCPAConsent *)ccpaConsentState {
    MPConsentRecordPRIVATE *record = [self.implementation ccpaConsentRecord];
    if (!record) {
        return nil;
    }
    return [[MPCCPAConsent alloc] initWithConsentRecord:record];
}

- (void)setCCPAConsentState:(MPCCPAConsent *)consent {
    if ((NSNull *)consent == [NSNull null]) {
        MPILogError(@"Cannot set CCPA Consent with NSNull.")
        return;
    }

    [self.implementation setCCPAConsentRecord:consent.implementation];
}

- (void)removeCCPAConsentState {
    [self.implementation removeCCPAConsentRecord];
}

@end
