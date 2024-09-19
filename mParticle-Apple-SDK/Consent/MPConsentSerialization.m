#import "MPConsentSerialization.h"
#import "MPConsentState.h"
#import "MPILogger.h"
#import "MPIConstants.h"
#import "MPConsentKitFilter.h"
#import "mParticle.h"
#import "MParticleSwift.h"

@implementation MPConsentSerialization

#pragma mark public methods

+ (nullable NSDictionary *)serverDictionaryFromConsentState:(MPConsentState *)state {
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
            gdprConsentDictionary[kMPConsentStateConsented] = @YES;
        } else {
            gdprConsentDictionary[kMPConsentStateConsented] = @NO;
        }
        
        if (gdprConsent.document) {
            gdprConsentDictionary[kMPConsentStateDocument] = gdprConsent.document;
        }
        
        if (gdprConsent.timestamp) {
            gdprConsentDictionary[kMPConsentStateTimestamp] = @(gdprConsent.timestamp.timeIntervalSince1970 * 1000);
        }
        
        if (gdprConsent.location) {
            gdprConsentDictionary[kMPConsentStateLocation] = gdprConsent.location;
        }
        
        if (gdprConsent.hardwareId) {
            gdprConsentDictionary[kMPConsentStateHardwareId] = gdprConsent.hardwareId;
        }
        
        gdprDictionary[purpose] = [gdprConsentDictionary copy];
    }
    
    if (gdprDictionary.count) {
        dictionary[kMPConsentStateGDPR] = gdprDictionary;
    }
    
    NSMutableDictionary *ccpaDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *ccpaConsentDictionary = [NSMutableDictionary dictionary];
    if (ccpaState) {
        if (ccpaState.consented) {
            ccpaConsentDictionary[kMPConsentStateConsented] = @YES;
        } else {
            ccpaConsentDictionary[kMPConsentStateConsented] = @NO;
        }
        
        if (ccpaState.document) {
            ccpaConsentDictionary[kMPConsentStateDocument] = ccpaState.document;
        }
        
        if (ccpaState.timestamp) {
            ccpaConsentDictionary[kMPConsentStateTimestamp] = @(ccpaState.timestamp.timeIntervalSince1970 * 1000);
        }
        
        if (ccpaState.location) {
            ccpaConsentDictionary[kMPConsentStateLocation] = ccpaState.location;
        }
        
        if (ccpaState.hardwareId) {
            ccpaConsentDictionary[kMPConsentStateHardwareId] = ccpaState.hardwareId;
        }
    }
    if (ccpaConsentDictionary.count) {
        ccpaDictionary[kMPConsentStateCCPAPurpose] = ccpaConsentDictionary;
    }
    
    if (ccpaDictionary.count) {
        dictionary[kMPConsentStateCCPA] = ccpaDictionary;
    }
    
    return dictionary;
}

+ (nullable NSString *)stringFromConsentState:(MPConsentState *)state {
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
            gdprConsentDictionary[kMPConsentStateConsentedKey] = @YES;
        } else {
            gdprConsentDictionary[kMPConsentStateConsentedKey] = @NO;
        }
        
        if (gdprConsent.document) {
            gdprConsentDictionary[kMPConsentStateDocumentKey] = gdprConsent.document;
        }
        
        if (gdprConsent.timestamp) {
            gdprConsentDictionary[kMPConsentStateTimestampKey] = @(gdprConsent.timestamp.timeIntervalSince1970 * 1000);
        }
        
        if (gdprConsent.location) {
            gdprConsentDictionary[kMPConsentStateLocationKey] = gdprConsent.location;
        }
        
        if (gdprConsent.hardwareId) {
            gdprConsentDictionary[kMPConsentStateHardwareIdKey] = gdprConsent.hardwareId;
        }
        
        gdprDictionary[purpose] = [gdprConsentDictionary copy];
    }
    
    if (gdprDictionary.count) {
        dictionary[kMPConsentStateGDPRKey] = gdprDictionary;
    }
    
    NSMutableDictionary *ccpaDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *ccpaConsentDictionary = [NSMutableDictionary dictionary];
    if (ccpaState) {
        if (ccpaState.consented) {
            ccpaConsentDictionary[kMPConsentStateConsentedKey] = @YES;
        } else {
            ccpaConsentDictionary[kMPConsentStateConsentedKey] = @NO;
        }
        
        if (ccpaState.document) {
            ccpaConsentDictionary[kMPConsentStateDocumentKey] = ccpaState.document;
        }
        
        if (ccpaState.timestamp) {
            ccpaConsentDictionary[kMPConsentStateTimestampKey] = @(ccpaState.timestamp.timeIntervalSince1970 * 1000);
        }
        
        if (ccpaState.location) {
            ccpaConsentDictionary[kMPConsentStateLocationKey] = ccpaState.location;
        }
        
        if (ccpaState.hardwareId) {
            ccpaConsentDictionary[kMPConsentStateHardwareIdKey] = ccpaState.hardwareId;
        }
    }
    if (ccpaConsentDictionary.count) {
        ccpaDictionary[kMPConsentStateCCPAPurpose] = ccpaConsentDictionary;
    }
    
    if (ccpaDictionary.count) {
        dictionary[kMPConsentStateCCPA] = ccpaDictionary;
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

+ (nullable MPConsentState *)consentStateFromString:(NSString *)string {
    MPConsentState *state = nil;
    NSDictionary *dictionary = [self dictionaryFromString:string];
    if (!dictionary) {
        MPILogError(@"Failed to create consent state from string=%@", string);
        return nil;
    }
    
    NSDictionary *gdprDictionary = dictionary[kMPConsentStateGDPRKey];
    NSDictionary *ccpaDictionary = dictionary[kMPConsentStateCCPA];
    if (!gdprDictionary && !ccpaDictionary) {
        return nil;
    }
    
    state = [[MPConsentState alloc] init];
    
    if (gdprDictionary) {
        for (NSString *purpose in gdprDictionary) {
            NSDictionary *gdprConsentDictionary = gdprDictionary[purpose];
            MPGDPRConsent *gdprState = [[MPGDPRConsent alloc] init];
            
            if ([gdprConsentDictionary[kMPConsentStateConsentedKey] isEqual:@YES]) {
                gdprState.consented = YES;
            } else {
                gdprState.consented = NO;
            }
            
            if (gdprConsentDictionary[kMPConsentStateDocumentKey]) {
                gdprState.document = gdprConsentDictionary[kMPConsentStateDocumentKey];
            }
            
            if (gdprConsentDictionary[kMPConsentStateTimestampKey]) {
                NSNumber *timestamp = gdprConsentDictionary[kMPConsentStateTimestampKey];
                gdprState.timestamp = [NSDate dateWithTimeIntervalSince1970:(timestamp.doubleValue/1000)];
            }
            
            if (gdprConsentDictionary[kMPConsentStateLocationKey]) {
                gdprState.location = gdprConsentDictionary[kMPConsentStateLocationKey];
            }
            
            if (gdprConsentDictionary[kMPConsentStateHardwareIdKey]) {
                gdprState.hardwareId = gdprConsentDictionary[kMPConsentStateHardwareIdKey];
            }
            
            [state addGDPRConsentState:gdprState purpose:purpose];
        }
    }
    
    if (ccpaDictionary && ccpaDictionary[kMPConsentStateCCPAPurpose]) {
        NSDictionary *ccpaConsentDictionary = ccpaDictionary[kMPConsentStateCCPAPurpose];
        MPCCPAConsent *ccpaState = [[MPCCPAConsent alloc] init];
        
        if ([ccpaConsentDictionary[kMPConsentStateConsentedKey] isEqual:@YES]) {
            ccpaState.consented = YES;
        } else {
            ccpaState.consented = NO;
        }
        
        if (ccpaConsentDictionary[kMPConsentStateDocumentKey]) {
            ccpaState.document = ccpaConsentDictionary[kMPConsentStateDocumentKey];
        }
        
        if (ccpaConsentDictionary[kMPConsentStateTimestampKey]) {
            NSNumber *timestamp = ccpaConsentDictionary[kMPConsentStateTimestampKey];
            ccpaState.timestamp = [NSDate dateWithTimeIntervalSince1970:(timestamp.doubleValue/1000)];
        }
        
        if (ccpaConsentDictionary[kMPConsentStateLocationKey]) {
            ccpaState.location = ccpaConsentDictionary[kMPConsentStateLocationKey];
        }
        
        if (ccpaConsentDictionary[kMPConsentStateHardwareIdKey]) {
            ccpaState.hardwareId = ccpaConsentDictionary[kMPConsentStateHardwareIdKey];
        }
        
        [state setCCPAConsentState:ccpaState];
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
            filter.shouldIncludeOnMatch = ((NSNumber *)configDictionary[kMPConsentKitFilterIncludeOnMatch]).boolValue;
        }
        
        NSDictionary *itemsArray = configDictionary[kMPConsentKitFilterItems];
        if (itemsArray && [itemsArray isKindOfClass:[NSArray class]]) {
            NSMutableArray *items = [NSMutableArray array];
            
            for (NSDictionary *itemDictionary in itemsArray) {
                
                if ([itemDictionary isKindOfClass:[NSDictionary class]]) {
                    
                    MPConsentKitFilterItem *item = [[MPConsentKitFilterItem alloc] init];
                    
                    if (itemDictionary[kMPConsentKitFilterItemConsented] && [itemDictionary[kMPConsentKitFilterItemConsented] isKindOfClass:[NSNumber class]]) {
                        item.consented = ((NSNumber *)itemDictionary[kMPConsentKitFilterItemConsented]).boolValue;
                    }
                    
                    if (itemDictionary[kMPConsentKitFilterItemHash]  && [itemDictionary[kMPConsentKitFilterItemHash] isKindOfClass:[NSNumber class]]) {
                        item.javascriptHash = ((NSNumber *)itemDictionary[kMPConsentKitFilterItemHash]).intValue;
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
