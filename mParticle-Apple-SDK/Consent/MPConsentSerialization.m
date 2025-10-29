#import "MPConsentSerialization.h"
#import "MPILogger.h"
#import "MPIConstants.h"
#import "mParticle.h"
#import "MParticleSwift.h"

@implementation MPConsentSerialization

#pragma mark public methods

+ (nullable NSDictionary *)serverDictionaryFromConsentState:(MPConsentStateSwift *)state {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSDictionary<NSString *, MPGDPRConsent *> *gdprStateDictionary = [state gdprConsentState];
    MPCCPAConsent *ccpaState = [state ccpaConsentState];
    if ((!gdprStateDictionary || gdprStateDictionary.count == 0) && ccpaState == nil) {
        return dictionary;
    }
    
    NSMutableDictionary *gdprDictionary = [NSMutableDictionary dictionary];
    for (NSString *purpose in gdprStateDictionary) {
        MPGDPRConsent *gdprConsent = gdprStateDictionary[purpose];
        NSMutableDictionary *gdprConsentDictionary = [NSMutableDictionary dictionary];
        
        if (gdprConsent.consented) {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateConsented] = @YES;
        } else {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateConsented] = @NO;
        }
        
        if (gdprConsent.document) {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateDocument] = gdprConsent.document;
        }
        
        if (gdprConsent.timestamp) {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateTimestamp] = @(gdprConsent.timestamp.timeIntervalSince1970 * 1000);
        }
        
        if (gdprConsent.location) {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateLocation] = gdprConsent.location;
        }
        
        if (gdprConsent.hardwareId) {
            gdprConsentDictionary[MPConsentSerializationNew.kMPConsentStateHardwareId] = gdprConsent.hardwareId;
        }
        
        gdprDictionary[purpose] = [gdprConsentDictionary copy];
    }
    
    if (gdprDictionary.count) {
        dictionary[MPConsentSerializationNew.kMPConsentStateGDPR] = gdprDictionary;
    }
    
    NSMutableDictionary *ccpaDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *ccpaConsentDictionary = [NSMutableDictionary dictionary];
    if (ccpaState) {
        if (ccpaState.consented) {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateConsented] = @YES;
        } else {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateConsented] = @NO;
        }
        
        if (ccpaState.document) {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateDocument] = ccpaState.document;
        }
        
        if (ccpaState.timestamp) {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateTimestamp] = @(ccpaState.timestamp.timeIntervalSince1970 * 1000);
        }
        
        if (ccpaState.location) {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateLocation] = ccpaState.location;
        }
        
        if (ccpaState.hardwareId) {
            ccpaConsentDictionary[MPConsentSerializationNew.kMPConsentStateHardwareId] = ccpaState.hardwareId;
        }
    }
    if (ccpaConsentDictionary.count) {
        ccpaDictionary[MPConsentSerializationNew.kMPConsentStateCCPAPurpose] = ccpaConsentDictionary;
    }
    
    if (ccpaDictionary.count) {
        dictionary[MPConsentSerializationNew.kMPConsentStateCCPA] = ccpaDictionary;
    }
    
    return dictionary;
}

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
    
    NSString *string = [self stringFromDictionary:dictionary];
    if (!string) {
        MPILogError(@"Failed to create string from consent dictionary=%@", dictionary);
        return nil;
    }
    return string;
}

+ (nullable MPConsentStateSwift *)consentStateFromString:(NSString *)string {
    MPConsentStateSwift *state = nil;
    NSDictionary *dictionary = [self dictionaryFromString:string];
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

+ (nullable NSDictionary *)dictionaryFromString:(NSString *)string {
    const char *rawString = string.UTF8String;
    NSUInteger length = string.length;
    if (rawString == NULL || length == 0) {
        MPILogError(@"Empty or invalid UTF-8 C string when trying to convert string=%@", string);
        return nil;
    }
    
    NSData *data = [NSData dataWithBytes:rawString length:length];
    if (!data) {
        MPILogError(@"Unable to create NSData with UTF-8 rawString=%s length=%@", rawString, @(length));
        return nil;
    }
    
    NSError *error = nil;
    id jsonObject = nil;
    @try {
        jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    } @catch(NSException *e) {
        MPILogError(@"Caught exception while creating dictionary from data: %@", data);
        return nil;
    }
    
    if (error) {
        MPILogError(@"Creating JSON object failed with error=%@ when trying to deserialize data=%@", error, data);
        return nil;
    }
    
    if (!jsonObject) {
        MPILogError(@"Unable to create JSON object from data=%@", data);
        return nil;
    }
    
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        MPILogError(@"Unable to create NSDictionary (got %@ instead) when trying to deserialize JSON data=%@", [jsonObject class], data);
        return nil;
    }
    
    NSDictionary *dictionary = (NSDictionary *)jsonObject;
    return dictionary;
}

+ (nullable NSString *)stringFromDictionary:(NSDictionary *)dictionary {
    NSError *error = nil;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    } @catch(NSException *e) {
        MPILogError(@"Caught exception while creating data from dictionary: %@", dictionary);
        return nil;
    }

    if (error) {
        MPILogError(@"NSJSONSerialization returned an error=%@ when trying to serialize dictionary=%@", error, dictionary);
        return nil;
    }
    if (!data) {
        MPILogError(@"Unable to create NSData with dictionary=%@", dictionary);
        return nil;
    }
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!string) {
        MPILogError(@"Unable to create UTF-8 string from JSON data=%@ dictionary=%@", data, dictionary);
        return nil;
    }
    return string;
}

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
