import Foundation

private enum ConsentKeys {
    static let gdpr = "gdpr"
    static let ccpa = "ccpa"
    static let ccpaPurpose = "data_sale_opt_out"

    static let serverConsented = "c"
    static let serverDocument = "d"
    static let serverTimestamp = "ts"
    static let serverLocation = "l"
    static let serverHardwareId = "h"

    static let storageConsented = "consented"
    static let storageDocument = "document"
    static let storageTimestamp = "timestamp"
    static let storageLocation = "location"
    static let storageHardwareId = "hardware_id"
}

@objc public final class MPConsentSerializationPRIVATE: NSObject {
    @objc public static func serverDictionary(fromGDPR gdpr: NSDictionary, ccpa: MPConsentRecordPRIVATE?) -> NSDictionary {
        dictionary(
            fromGDPR: gdpr,
            ccpa: ccpa,
            gdprKey: ConsentKeys.gdpr,
            consentedKey: ConsentKeys.serverConsented,
            documentKey: ConsentKeys.serverDocument,
            timestampKey: ConsentKeys.serverTimestamp,
            locationKey: ConsentKeys.serverLocation,
            hardwareIdKey: ConsentKeys.serverHardwareId
        )
    }

    @objc public static func storageDictionary(fromGDPR gdpr: NSDictionary, ccpa: MPConsentRecordPRIVATE?) -> NSDictionary? {
        let dictionary = dictionary(
            fromGDPR: gdpr,
            ccpa: ccpa,
            gdprKey: ConsentKeys.gdpr,
            consentedKey: ConsentKeys.storageConsented,
            documentKey: ConsentKeys.storageDocument,
            timestampKey: ConsentKeys.storageTimestamp,
            locationKey: ConsentKeys.storageLocation,
            hardwareIdKey: ConsentKeys.storageHardwareId
        )
        return dictionary.allKeys.isEmpty ? nil : dictionary
    }

    @objc public static func dictionary(from string: String) -> NSDictionary? {
        let nsString = string as NSString
        guard let rawString = nsString.utf8String, nsString.length > 0 else {
            NSLog("mParticle -> Empty or invalid UTF-8 C string when trying to convert string=%@", string)
            return nil
        }

        let data = Data(bytes: rawString, count: nsString.length)
        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            NSLog(
                "mParticle -> Creating JSON object failed with error=%@ when trying to deserialize data=%@",
                error.localizedDescription,
                data as NSData
            )
            return nil
        }

        guard let dictionary = jsonObject as? NSDictionary else {
            NSLog(
                "mParticle -> Unable to create NSDictionary (got %@ instead) when trying to deserialize JSON data=%@",
                String(describing: type(of: jsonObject)),
                data as NSData
            )
            return nil
        }
        return dictionary
    }

    @objc(stringFromDictionary:)
    public static func string(from dictionary: NSDictionary) -> String? {
        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        } catch {
            NSLog(
                "mParticle -> NSJSONSerialization returned an error=%@ when trying to serialize dictionary=%@",
                error.localizedDescription,
                dictionary
            )
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            NSLog("mParticle -> Unable to create UTF-8 string from JSON data=%@ dictionary=%@", data as NSData, dictionary)
            return nil
        }
        return string
    }

    /// Reports whether either top-level consent container is present, regardless of whether it
    /// holds any parsable records. An empty container still represents stored consent.
    @objc public static func storageContainsConsentContainers(_ dictionary: NSDictionary) -> Bool {
        dictionary[ConsentKeys.gdpr] != nil || dictionary[ConsentKeys.ccpa] != nil
    }

    @objc public static func gdprRecords(fromStorage dictionary: NSDictionary) -> NSDictionary {
        let records = NSMutableDictionary()
        guard let gdprDictionary = dictionary[ConsentKeys.gdpr] as? NSDictionary else {
            return records
        }
        for purpose in gdprDictionary.allKeys {
            guard let purpose = purpose as? String,
                  let consentDictionary = gdprDictionary[purpose] as? NSDictionary
            else { continue }
            records[purpose] = MPConsentRecordPRIVATE.record(
                from: consentDictionary,
                consentedKey: ConsentKeys.storageConsented,
                documentKey: ConsentKeys.storageDocument,
                timestampKey: ConsentKeys.storageTimestamp,
                locationKey: ConsentKeys.storageLocation,
                hardwareIdKey: ConsentKeys.storageHardwareId
            )
        }
        return records
    }

    @objc public static func ccpaRecord(fromStorage dictionary: NSDictionary) -> MPConsentRecordPRIVATE? {
        guard let ccpaDictionary = dictionary[ConsentKeys.ccpa] as? NSDictionary,
              let consentDictionary = ccpaDictionary[ConsentKeys.ccpaPurpose] as? NSDictionary
        else {
            return nil
        }
        return MPConsentRecordPRIVATE.record(
            from: consentDictionary,
            consentedKey: ConsentKeys.storageConsented,
            documentKey: ConsentKeys.storageDocument,
            timestampKey: ConsentKeys.storageTimestamp,
            locationKey: ConsentKeys.storageLocation,
            hardwareIdKey: ConsentKeys.storageHardwareId
        )
    }

    @objc public static func filter(from configDictionary: Any?) -> MPConsentKitFilter? {
        guard let configDictionary = configDictionary as? NSDictionary else {
            return nil
        }

        let filter = MPConsentKitFilter()
        if let include = configDictionary[ConsentFilteringSwift.kMPConsentKitFilterIncludeOnMatch] as? NSNumber {
            filter.shouldIncludeOnMatch = include.boolValue
        }

        if let itemsArray = configDictionary[ConsentFilteringSwift.kMPConsentKitFilterItems] as? [Any] {
            var items: [MPConsentKitFilterItem] = []
            for itemObject in itemsArray {
                guard let itemDictionary = itemObject as? NSDictionary else { continue }
                let item = MPConsentKitFilterItem()
                if let consented = itemDictionary[ConsentFilteringSwift.kMPConsentKitFilterItemConsented] as? NSNumber {
                    item.consented = consented.boolValue
                }
                if let hash = itemDictionary[ConsentFilteringSwift.kMPConsentKitFilterItemHash] as? NSNumber {
                    item.javascriptHash = hash.int32Value
                }
                items.append(item)
            }
            filter.filterItems = items
        }
        return filter
    }

    private static func dictionary(
        fromGDPR gdpr: NSDictionary,
        ccpa: MPConsentRecordPRIVATE?,
        gdprKey: String,
        consentedKey: String,
        documentKey: String,
        timestampKey: String,
        locationKey: String,
        hardwareIdKey: String
    ) -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()
        let gdprDictionary = NSMutableDictionary()
        for purpose in gdpr.allKeys {
            guard let purpose = purpose as? String,
                  let record = gdpr[purpose] as? MPConsentRecordPRIVATE
            else { continue }
            gdprDictionary[purpose] = record.dictionaryRepresentation(
                consentedKey: consentedKey,
                documentKey: documentKey,
                timestampKey: timestampKey,
                locationKey: locationKey,
                hardwareIdKey: hardwareIdKey
            )
        }
        if !gdprDictionary.allKeys.isEmpty {
            dictionary[gdprKey] = gdprDictionary
        }

        if let ccpa {
            let ccpaDictionary = NSMutableDictionary()
            ccpaDictionary[ConsentKeys.ccpaPurpose] = ccpa.dictionaryRepresentation(
                consentedKey: consentedKey,
                documentKey: documentKey,
                timestampKey: timestampKey,
                locationKey: locationKey,
                hardwareIdKey: hardwareIdKey
            )
            dictionary[ConsentKeys.ccpa] = ccpaDictionary
        }
        return dictionary
    }
}
