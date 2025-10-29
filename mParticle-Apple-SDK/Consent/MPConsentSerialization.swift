//
//  MPConsentSerialization.swift
//  mParticle-Apple-SDK
//
//  Created by Denis Chilik on 10/29/25.
//

@objcMembers
public class MPConsentSerializationNew: NSObject {
    // GDPR Consent
    static let kMPConsentStateGDPR = "gdpr"
    
    // CCPA Consent
    static let kMPConsentStateCCPA = "ccpa"
    static let kMPConsentStateCCPAPurpose = "data_sale_opt_out"

    static let kMPConsentStateConsented = "c"
    static let kMPConsentStateDocument = "d"
    static let kMPConsentStateTimestamp = "ts"
    static let kMPConsentStateLocation = "l"
    static let kMPConsentStateHardwareId = "h"
    
    // Consent serialization
    static let kMPConsentStateKey = "consent_state"
    static let kMPConsentStateGDPRKey = "gdpr"
    static let kMPConsentStateConsentedKey = "consented"
    static let kMPConsentStateDocumentKey = "document"
    static let kMPConsentStateTimestampKey = "timestamp"
    static let kMPConsentStateLocationKey = "location"
    static let kMPConsentStateHardwareIdKey = "hardware_id"
    
    // Consent filtering
    static let kMPConsentKitFilter = "crvf"
    static let kMPConsentKitFilterIncludeOnMatch = "i"
    static let kMPConsentKitFilterItems = "v"
    static let kMPConsentKitFilterItemConsented = "c"
    static let kMPConsentKitFilterItemHash = "h"
    static let kMPConsentRegulationFilters = "reg"
    static let kMPConsentPurposeFilters = "pur"
    static let kMPConsentGDPRRegulationType = "1"
    static let kMPConsentCCPARegulationType = "2"
    static let kMPConsentCCPAPurposeName = "data_sale_opt_out"
    
    static func stringFromDictionary(_ dictionary: [String: Any]) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            print("Caught exception while creating data from dictionary: \(dictionary)")
            return nil
        }
    }
    
    static func dictionaryFromString(_ string: String) -> [String: Any]? {
        guard let data = string.data(using: .utf8), !data.isEmpty else {
            print("Unable to create Data from UTF-8 string=\(string)")
            return nil
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dictionary = jsonObject as? [String: Any] else {
                print("Unable to create Dictionary (got \(type(of: jsonObject)) instead) when trying to deserialize JSON data=\(data)")
                return nil
            }
            return dictionary
        } catch {
            print("Caught exception while creating dictionary from data: \(data)")
            return nil
        }
    }

    static func serverDictionaryFromConsentState(_ state: MPConsentStateSwift) -> [String: Any]? {
        var dictionary = [String: Any]()
        var gdprStateDictionary = state.gdprConsentState
        var ccpaState = state.ccpaConsentState
        if (gdprStateDictionary.count == 0 && ccpaState == nil) {
            return dictionary;
        }
        
        var gdprDictionary = [String: Any]()
        for (purpose, gdprConsent) in gdprStateDictionary {
            var gdprConsentDictionary = [String: Any]()
            
            gdprConsentDictionary[kMPConsentStateConsented] = gdprConsent.consented;
            
            if let document = gdprConsent.document {
                gdprConsentDictionary[kMPConsentStateDocument] = document
            }
            
            gdprConsentDictionary[kMPConsentStateTimestamp] = gdprConsent.timestamp.timeIntervalSince1970 * 1000
            
            if let location = gdprConsent.location {
                gdprConsentDictionary[kMPConsentStateLocation] = location;
            }
            
            if let hardwareId = gdprConsent.hardwareId {
                gdprConsentDictionary[kMPConsentStateHardwareId] = hardwareId
            }
            
            gdprDictionary[purpose] = gdprConsentDictionary
        }
        
        if !gdprDictionary.isEmpty {
            dictionary[MPConsentSerializationNew.kMPConsentStateGDPR] = gdprDictionary;
        }
        
        var ccpaDictionary = [String: Any]()
        var ccpaConsentDictionary = [String: Any]()
        if let ccpaState {
            
            ccpaConsentDictionary[kMPConsentStateConsented] = ccpaState.consented
            
            if let document = ccpaState.document {
                ccpaConsentDictionary[kMPConsentStateDocument] = document;
            }
            
            ccpaConsentDictionary[kMPConsentStateTimestamp] = ccpaState.timestamp.timeIntervalSince1970 * 1000
            
            if let location = ccpaState.location {
                ccpaConsentDictionary[kMPConsentStateLocation] = location;
            }
            
            if let hardwareId = ccpaState.hardwareId {
                ccpaConsentDictionary[kMPConsentStateHardwareId] = hardwareId
            }
        }
        if !ccpaConsentDictionary.isEmpty {
            ccpaDictionary[kMPConsentStateCCPAPurpose] = ccpaConsentDictionary;
        }
        
        if !ccpaDictionary.isEmpty {
            dictionary[kMPConsentStateCCPA] = ccpaDictionary;
        }
        
        return dictionary;
    }
    
    static func stringFromConsentState(_ state: MPConsentStateSwift) -> String? {
        
        var dictionary = [String: Any]()
        var ccpaState = state.ccpaConsentState
        
        var gdprStateDictionary = state.gdprConsentState
        if gdprStateDictionary.count == 0 && ccpaState == nil {
            return nil;
        }
        
        var gdprDictionary = [String: Any]()
        for (purpose, gdprConsent) in gdprStateDictionary {
            var gdprConsentDictionary = [String: Any]()
            
            gdprConsentDictionary[kMPConsentStateConsentedKey] = gdprConsent.consented
            
            if let document = gdprConsent.document {
                gdprConsentDictionary[kMPConsentStateDocumentKey] = document;
            }
            
            gdprConsentDictionary[kMPConsentStateTimestampKey] = gdprConsent.timestamp.timeIntervalSince1970 * 1000;
            
            if let location = gdprConsent.location {
                gdprConsentDictionary[kMPConsentStateLocationKey] = location;
            }
            
            if let hardwareId = gdprConsent.hardwareId {
                gdprConsentDictionary[kMPConsentStateHardwareIdKey] = hardwareId;
            }
            
            gdprDictionary[purpose] = gdprConsentDictionary
        }
        
        if !gdprDictionary.isEmpty {
            dictionary[kMPConsentStateGDPRKey] = gdprDictionary;
        }
        
        var ccpaDictionary = [String: Any]()
        var ccpaConsentDictionary = [String: Any]()
        if let ccpaState {
            ccpaConsentDictionary[kMPConsentStateConsentedKey] = ccpaState.consented
            
            if let document = ccpaState.document {
                ccpaConsentDictionary[kMPConsentStateDocumentKey] = document;
            }
            
            ccpaConsentDictionary[kMPConsentStateTimestampKey] = ccpaState.timestamp.timeIntervalSince1970 * 1000
            
            if let location = ccpaState.location {
                ccpaConsentDictionary[kMPConsentStateLocationKey] = location;
            }
            
            if let hardwareId = ccpaState.hardwareId {
                ccpaConsentDictionary[kMPConsentStateHardwareIdKey] = hardwareId;
            }
        }
        if !ccpaConsentDictionary.isEmpty {
            ccpaDictionary[kMPConsentStateCCPAPurpose] = ccpaConsentDictionary;
        }
        
        if !ccpaDictionary.isEmpty {
            dictionary[kMPConsentStateCCPA] = ccpaDictionary;
        }
        
        if (dictionary.count == 0) {
            return nil;
        }
        
        return MPConsentSerializationNew.stringFromDictionary(dictionary)
    }
    
    static func filterFromDictionary(_ configDictionary: [String: Any]) -> MPConsentKitFilter {
        var filter = MPConsentKitFilter()
        
        filter.shouldIncludeOnMatch = configDictionary[kMPConsentKitFilterIncludeOnMatch] as? NSNumber
        
        if let itemsArray = configDictionary[kMPConsentKitFilterItems] as? NSArray {
            var items = [MPConsentKitFilterItem]();
            
            for itemDictionary in itemsArray {
                if let itemDictionary = itemDictionary as? [String: Any] {
                    items.append(MPConsentKitFilterItem(itemDictionary))
                }
            }
            
            filter.filterItems = items
            
        }
        
        return filter;
    }
}

extension MPConsentKitFilterItem {
    convenience init(_ dictionary: [String: Any]) {
        self.init()
        consented = dictionary[MPConsentSerializationNew.kMPConsentKitFilterItemConsented] as? NSNumber
        javascriptHash = dictionary[MPConsentSerializationNew.kMPConsentKitFilterItemHash] as? NSNumber
    }
}
