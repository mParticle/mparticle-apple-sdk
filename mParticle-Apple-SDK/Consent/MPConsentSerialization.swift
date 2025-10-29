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

}
