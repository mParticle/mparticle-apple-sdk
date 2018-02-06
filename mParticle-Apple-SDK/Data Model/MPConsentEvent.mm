#import "MPConsentEvent.h"
#import "MPEnums.h"
#import "MPIConstants.h"
#include "EventTypeName.h"
#import "MPILogger.h"

@implementation MPConsentEvent

+ (NSString *)enumDescriptionForRegulation:(MPConsentRegulation)regulation {
    switch (regulation) {
        case MPConsentRegulationUnknown:
            return kMPConsentRegulationUnknown;
            break;
            
        case MPConsentRegulationGDPR:
            return kMPConsentRegulationGDPR;
            break;
            
        default:
            MPILogError(@"Unknown consent regulation enum value: %@", @(regulation));
            return kMPConsentRegulationUnknown;
            break;
    }
}

+ (NSString *)enumDescriptionForCategory:(MPConsentCategory)category {
    switch (category) {
        case MPConsentCategoryUnknown:
            return kMPConsentCategoryTypeUnknown;
            break;
        case MPConsentCategoryParental:
            return kMPConsentCategoryTypeParental;
            break;
        case MPConsentCategoryProcessing:
            return kMPConsentCategoryTypeProcessing;
            break;
        case MPConsentCategoryLocation:
            return kMPConsentCategoryTypeLocation;
            break;
        case MPConsentCategorySensitiveData:
            return kMPConsentCategoryTypeSensitiveData;
            break;
            
        default:
            return kMPConsentCategoryTypeUnknown;
            MPILogError(@"Unknown consent category enum value: %@", @(category));
            break;
    }
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    NSString *regulation = [MPConsentEvent enumDescriptionForRegulation:self.regulation];
    if (regulation) {
        dictionary[kMPConsentEventKeyRegulation] = regulation;
    }
    
    if (self.timestamp) {
        dictionary[kMPTimestampKey] = @([self.timestamp timeIntervalSince1970]);
    }
    
    if (self.document) {
        dictionary[kMPConsentEventKeyDocument] = self.document;
    }
    
    if (self.consentLocation) {
        dictionary[kMPConsentEventKeyConsentLocation] = self.consentLocation;
    }
    
    if (self.hardwareId) {
        dictionary[kMPConsentEventKeyHardwareId] = self.hardwareId;
    }
    
    NSString *category = [MPConsentEvent enumDescriptionForCategory:self.category];
    if (category) {
        dictionary[kMPConsentEventKeyCategory] = category;
    }
    
    if (self.purpose) {
        dictionary[kMPConsentEventKeyPurpose] = self.purpose;
    }
    
    switch (self.type) {
        case MPConsentEventTypeDenied:
            dictionary[kMPConsentEventKeyConsented] = @NO;
            break;
            
        case MPConsentEventTypeGranted:
            dictionary[kMPConsentEventKeyConsented] = @YES;
            break;
            
        default:
            MPILogError(@"Unknown consent event type: %@", @(self.type));
            break;
    }
    
    if (self.customAttributes) {
        dictionary[kMPConsentEventKeyCustomAttributes] = self.customAttributes;
    }
    
    return [dictionary copy];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"MPConsentEvent: \n%@", [self dictionaryRepresentation]];
}

@end
