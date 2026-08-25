import Foundation

@objc public final class MPConsentRecordPRIVATE: NSObject {
    @objc public var consented = false
    @objc public var document: String?
    @objc public var timestamp = Date()
    @objc public var location: String?
    @objc public var hardwareId: String?

    @objc public func copyRecord() -> MPConsentRecordPRIVATE {
        let copy = MPConsentRecordPRIVATE()
        copy.consented = consented
        copy.document = document
        copy.timestamp = timestamp
        copy.location = location
        copy.hardwareId = hardwareId
        return copy
    }

    @objc public func dictionaryRepresentation(
        consentedKey: String,
        documentKey: String,
        timestampKey: String,
        locationKey: String,
        hardwareIdKey: String
    ) -> NSDictionary {
        let dictionary = NSMutableDictionary()
        dictionary[consentedKey] = consented ? NSNumber(value: true) : NSNumber(value: false)
        if let document {
            dictionary[documentKey] = document
        }
        dictionary[timestampKey] = NSNumber(value: timestamp.timeIntervalSince1970 * 1000)
        if let location {
            dictionary[locationKey] = location
        }
        if let hardwareId {
            dictionary[hardwareIdKey] = hardwareId
        }
        return dictionary
    }

    @objc public static func record(
        from dictionary: NSDictionary,
        consentedKey: String,
        documentKey: String,
        timestampKey: String,
        locationKey: String,
        hardwareIdKey: String
    ) -> MPConsentRecordPRIVATE {
        let record = MPConsentRecordPRIVATE()
        record.consented = (dictionary[consentedKey] as? NSNumber)?.isEqual(to: NSNumber(value: true)) == true
        if let document = dictionary[documentKey] as? String {
            record.document = document
        }
        if let timestamp = dictionary[timestampKey] as? NSNumber {
            record.timestamp = Date(timeIntervalSince1970: timestamp.doubleValue/1000)
        }
        if let location = dictionary[locationKey] as? String {
            record.location = location
        }
        if let hardwareId = dictionary[hardwareIdKey] as? String {
            record.hardwareId = hardwareId
        }
        return record
    }
}
