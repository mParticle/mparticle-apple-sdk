#import "MPConsentSerialization.h"
#import "MPILogger.h"
#import "MPIConstants.h"
#import "mParticle.h"
#import "MParticleSwift.h"

@implementation MPConsentSerialization

#pragma mark public methods

+ (nullable NSString *)stringFromConsentState:(MPConsentStateSwift *)state {
    if (!state) {
        return nil;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    MPCCPAConsent *ccpaState = [state ccpaConsentState];
    
    NSDictionary<NSString *, MPGDPRConsent *> *gdprStateDictionary = [state gdprConsentState];
    if ((!gdprStateDictionary || gdprStateDictionary.count == 0) && ccpaState == nil) {
        return nil;
    }
    
    NSMutableDictionary *gdprDictionary = [NSMutableDictionary dictionary];
    for (NSString *purpose in gdprStateDictionary) {
        MPGDPRConsent *gdprConsent = gdprStateDictionary[purpose];
        NSMutableDictionary *gdprConsentDictionary = [NSMutableDictionary dictionary];
        
        if (gdprConsent.consented) {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateConsentedKey] = @YES;
        } else {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateConsentedKey] = @NO;
        }
        
        if (gdprConsent.document) {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateDocumentKey] = gdprConsent.document;
        }
        
        if (gdprConsent.timestamp) {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateTimestampKey] = @(gdprConsent.timestamp.timeIntervalSince1970 * 1000);
        }
        
        if (gdprConsent.location) {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateLocationKey] = gdprConsent.location;
        }
        
        if (gdprConsent.hardwareId) {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateHardwareIdKey] = gdprConsent.hardwareId;
        }
        
        gdprDictionary[purpose] = [gdprConsentDictionary copy];
    }
    
    if (gdprDictionary.count) {
        dictionary[MPConsentSerializationNew.kMPConsentStateGDPRKey] = gdprDictionary;
    }
    
    NSMutableDictionary *ccpaDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *ccpaConsentDictionary = [NSMutableDictionary dictionary];
    if (ccpaState) {
        if (ccpaState.consented) {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateConsentedKey] = @YES;
        } else {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateConsentedKey] = @NO;
        }
        
        if (ccpaState.document) {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateDocumentKey] = ccpaState.document;
        }
        
        if (ccpaState.timestamp) {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateTimestampKey] = @(ccpaState.timestamp.timeIntervalSince1970 * 1000);
        }
        
        if (ccpaState.location) {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateLocationKey] = ccpaState.location;
        }
        
        if (ccpaState.hardwareId) {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateHardwareIdKey] = ccpaState.hardwareId;
        }
    }
    if (ccpaConsentDictionary.count) {
        ccpaDictionary[MPConsentSerializationNew.kMPConsentStateCCPAPurpose] = ccpaConsentDictionary;
    }
    
    if (ccpaDictionary.count) {
        dictionary[MPConsentSerializationNew.kMPConsentStateCCPA] = ccpaDictionary;
    }
    
    if (dictionary.count == 0) {
        return nil;
    }
    
    NSString *string = [MPConsentSerializationNew stringFromDictionary:dictionary];
    if (!string) {
        MPILogError(@"Failed to create string from consent dictionary=%@", dictionary);
        return nil;
    }
    return string;
}

+ (nullable MPConsentStateSwift *)consentStateFromString:(NSString *)string {
    MPConsentStateSwift *state = nil;
    NSDictionary *dictionary = [MPConsentSerializationNew dictionaryFromString:string];
    if (!dictionary) {
        MPILogError(@"Failed to create consent state from string=%@", string);
        return nil;
    }
    
    NSDictionary *gdprDictionary = dictionary[MPConsentSerializationNew.kMPConsentStateGDPRKey];
    NSDictionary *ccpaDictionary = dictionary[MPConsentSerializationNew.kMPConsentStateCCPA];
    if (!gdprDictionary && !ccpaDictionary) {
        return nil;
    }
    
    state = [[MPConsentStateSwift alloc] init];
    
    if (gdprDictionary) {
        for (NSString *purpose in gdprDictionary) {
            NSDictionary *gdprConsentDictionary = gdprDictionary[purpose];
            MPGDPRConsent *gdprState = [[MPGDPRConsent alloc] init];
            
            if ([gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateConsentedKey] isEqual:@YES]) {
                gdprState.consented = YES;
            } else {
                gdprState.consented = NO;
            }
            
            if (gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateDocumentKey]) {
                gdprState.document = gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateDocumentKey];
            }
            
            if (gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateTimestampKey]) {
                NSNumber *timestamp = gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateTimestampKey];
                gdprState.timestamp = [NSDate dateWithTimeIntervalSince1970:(timestamp.doubleValue/1000)];
            }
            
            if (gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateLocationKey]) {
                gdprState.location = gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateLocationKey];
            }
            
            if (gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateHardwareIdKey]) {
                gdprState.hardwareId = gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateHardwareIdKey];
            }
            
            [state addGDPRConsentStateWithConsent:gdprState purpose:purpose];
        }
    }
    
    if (ccpaDictionary && ccpaDictionary[MPConsentSerializationNew.kMPConsentStateCCPAPurpose]) {
        NSDictionary *ccpaConsentDictionary = ccpaDictionary[MPConsentSerializationNew.kMPConsentStateCCPAPurpose];
        MPCCPAConsent *ccpaState = [[MPCCPAConsent alloc] init];
        
        if ([ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateConsentedKey] isEqual:@YES]) {
            ccpaState.consented = YES;
        } else {
            ccpaState.consented = NO;
        }
        
        if (ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateDocumentKey]) {
            ccpaState.document = ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateDocumentKey];
        }
        
        if (ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateTimestampKey]) {
            NSNumber *timestamp = ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateTimestampKey];
            ccpaState.timestamp = [NSDate dateWithTimeIntervalSince1970:(timestamp.doubleValue/1000)];
        }
        
        if (ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateLocationKey]) {
            ccpaState.location = ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateLocationKey];
        }
        
        if (ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateHardwareIdKey]) {
            ccpaState.hardwareId = ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateHardwareIdKey];
        }
        
        [state setCcpaConsentState:ccpaState];
    }
    
    return state;
}

#pragma mark private helpers


+ (MPConsentKitFilter *)filterFromDictionary:(NSDictionary *)configDictionary {
    
    MPConsentKitFilter *filter = nil;
    
    if (configDictionary && [configDictionary isKindOfClass:[NSDictionary class]]) {
        
        filter = [[MPConsentKitFilter alloc] init];
        
        if (configDictionary[kMPConsentKitFilterIncludeOnMatch]  && [configDictionary[kMPConsentKitFilterIncludeOnMatch] isKindOfClass:[NSNumber class]]) {
            filter.shouldIncludeOnMatch = (NSNumber *)configDictionary[kMPConsentKitFilterIncludeOnMatch];
        }
        
        NSDictionary *itemsArray = configDictionary[kMPConsentKitFilterItems];
        if (itemsArray && [itemsArray isKindOfClass:[NSArray class]]) {
            NSMutableArray *items = [NSMutableArray array];
            
            for (NSDictionary *itemDictionary in itemsArray) {
                
                if ([itemDictionary isKindOfClass:[NSDictionary class]]) {
                    
                    MPConsentKitFilterItem *item = [[MPConsentKitFilterItem alloc] init];
                    
                    if (itemDictionary[kMPConsentKitFilterItemConsented] && [itemDictionary[kMPConsentKitFilterItemConsented] isKindOfClass:[NSNumber class]]) {
                        item.consented = (NSNumber *)itemDictionary[kMPConsentKitFilterItemConsented];
                    }
                    
                    if (itemDictionary[kMPConsentKitFilterItemHash]  && [itemDictionary[kMPConsentKitFilterItemHash] isKindOfClass:[NSNumber class]]) {
                        item.javascriptHash = (NSNumber *)itemDictionary[kMPConsentKitFilterItemHash];
                    }
                    
                    [items addObject:item];
                    
                }
                
            }
            
            filter.filterItems = [items copy];
            
        }
    }
    
    return filter;
}

@end
