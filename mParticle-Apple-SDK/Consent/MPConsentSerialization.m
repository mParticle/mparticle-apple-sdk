#import "MPConsentSerialization.h"
#import "MPConsentState.h"
#import "MPILogger.h"
#import "mParticle.h"
@import mParticle_Apple_SDK_Swift;

@interface MPConsentState ()
@property (nonatomic, strong) MPConsentStatePRIVATE *implementation;
@end

@implementation MPConsentSerialization

+ (nullable NSDictionary *)serverDictionaryFromConsentState:(MPConsentState *)state {
    NSDictionary *gdprRecords = state ? [state.implementation gdprConsentRecords] : @{};
    MPConsentRecordPRIVATE *ccpaRecord = [state.implementation ccpaConsentRecord];
    return [MPConsentSerializationPRIVATE serverDictionaryFromGDPR:gdprRecords ccpa:ccpaRecord];
}

+ (nullable NSString *)stringFromConsentState:(MPConsentState *)state {
    if (!state) {
        return nil;
    }

    NSDictionary *gdprRecords = [state.implementation gdprConsentRecords];
    MPConsentRecordPRIVATE *ccpaRecord = [state.implementation ccpaConsentRecord];
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
        (void)[state.implementation addGDPRConsentRecord:gdprRecords[purpose] purpose:purpose];
    }
    if (ccpaRecord) {
        [state.implementation setCCPAConsentRecord:ccpaRecord];
    }
    return state;
}

+ (MPConsentKitFilter *)filterFromDictionary:(NSDictionary *)configDictionary {
    return [MPConsentSerializationPRIVATE filterFrom:configDictionary];
}

+ (nullable NSDictionary *)dictionaryFromString:(NSString *)string {
    return [MPConsentSerializationPRIVATE dictionaryFrom:string];
}

@end
