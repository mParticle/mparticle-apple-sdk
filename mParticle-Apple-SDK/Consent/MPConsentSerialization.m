#import "MPConsentSerialization.h"
#import "MPConsentState.h"
#import "MPCCPAConsent.h"
#import "MPGDPRConsent.h"
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

@implementation MPConsentSerialization

+ (nullable NSDictionary *)serverDictionaryFromConsentState:(MPConsentState *)state {
    NSDictionary *gdprRecords = [self gdprRecordsFromConsentState:state];
    MPConsentRecordPRIVATE *ccpaRecord = [self ccpaRecordFromConsentState:state];
    return [MPConsentSerializationPRIVATE serverDictionaryFromGDPR:gdprRecords ccpa:ccpaRecord];
}

+ (nullable NSString *)stringFromConsentState:(MPConsentState *)state {
    if (!state) {
        return nil;
    }

    NSDictionary *gdprRecords = [self gdprRecordsFromConsentState:state];
    MPConsentRecordPRIVATE *ccpaRecord = [self ccpaRecordFromConsentState:state];
    NSDictionary *dictionary = [MPConsentSerializationPRIVATE storageDictionaryFromGDPR:gdprRecords ccpa:ccpaRecord];
    if (!dictionary) {
        return nil;
    }

    NSString *string = [MPConsentSerializationPRIVATE stringFromDictionary:dictionary];
    if (!string) {
        MPILogError(@"Failed to create string from consent dictionary=%@", dictionary);
        return nil;
    }
    return string;
}

+ (nullable MPConsentState *)consentStateFromString:(NSString *)string {
    NSDictionary *dictionary = [self dictionaryFromString:string];
    if (!dictionary) {
        MPILogError(@"Failed to create consent state from string=%@", string);
        return nil;
    }

    if (![MPConsentSerializationPRIVATE storageContainsConsentContainers:dictionary]) {
        return nil;
    }

    NSDictionary *gdprRecords = [MPConsentSerializationPRIVATE gdprRecordsFromStorage:dictionary];
    MPConsentRecordPRIVATE *ccpaRecord = [MPConsentSerializationPRIVATE ccpaRecordFromStorage:dictionary];

    MPConsentState *state = [[MPConsentState alloc] init];
    for (NSString *purpose in gdprRecords) {
        MPConsentRecordPRIVATE *record = gdprRecords[purpose];
        MPGDPRConsent *gdprState = [[MPGDPRConsent alloc] initWithConsentRecord:record];
        [state addGDPRConsentState:gdprState purpose:purpose];
    }
    if (ccpaRecord) {
        [state setCCPAConsentState:[[MPCCPAConsent alloc] initWithConsentRecord:ccpaRecord]];
    }
    return state;
}

+ (MPConsentKitFilter *)filterFromDictionary:(NSDictionary *)configDictionary {
    return [MPConsentSerializationPRIVATE filterFrom:configDictionary];
}

+ (nullable NSDictionary *)dictionaryFromString:(NSString *)string {
    return [MPConsentSerializationPRIVATE dictionaryFrom:string];
}

+ (NSDictionary *)gdprRecordsFromConsentState:(MPConsentState *)state {
    NSMutableDictionary *records = [NSMutableDictionary dictionary];
    NSDictionary<NSString *, MPGDPRConsent *> *gdprState = [state gdprConsentState];
    for (NSString *purpose in gdprState) {
        MPConsentRecordPRIVATE *record = gdprState[purpose].implementation;
        if (record) {
            records[purpose] = record;
        }
    }
    return records;
}

+ (MPConsentRecordPRIVATE *)ccpaRecordFromConsentState:(MPConsentState *)state {
    return [state ccpaConsentState].implementation;
}

@end
