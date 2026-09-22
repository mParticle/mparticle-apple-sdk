import Foundation

@objc public enum MPConsentStateMutationResult: Int {
    case success
    case invalidPurpose
    case invalidConsent
    case tooManyPurposes
}

@objc public final class MPConsentStatePRIVATE: NSObject {
    @objc public static let maxGDPRConsentPurposes: Int = 100

    private var gdprRecords = NSMutableDictionary()
    private var ccpaRecord: MPConsentRecordPRIVATE?

    @objc(canonicalizeForDeduplication:)
    public static func canonicalizeForDeduplication(_ source: Any?) -> String? {
        guard let source = source as? String, !MPSwiftIsNull(source), !source.isEmpty else {
            return nil
        }
        let canonicalized = source.lowercased().trimmingCharacters(in: .whitespaces)
        return canonicalized.isEmpty ? nil : canonicalized
    }

    @objc public func gdprConsentRecords() -> NSDictionary {
        let records = NSMutableDictionary(capacity: gdprRecords.count)
        for purpose in gdprRecords.allKeys {
            guard let record = gdprRecords[purpose] as? MPConsentRecordPRIVATE else { continue }
            records[purpose] = record.copyRecord()
        }
        return records.copy() as? NSDictionary ?? NSDictionary()
    }

    @objc public func addGDPRConsentRecord(_ record: Any?, purpose: Any?) -> MPConsentStateMutationResult {
        guard let purpose = MPConsentStatePRIVATE.canonicalizeForDeduplication(purpose) else {
            return .invalidPurpose
        }
        guard let record = record as? MPConsentRecordPRIVATE, !MPSwiftIsNull(record) else {
            return .invalidConsent
        }
        if gdprRecords.count >= Self.maxGDPRConsentPurposes {
            return .tooManyPurposes
        }
        gdprRecords[purpose] = record.copyRecord()
        return .success
    }

    @objc public func removeGDPRConsentRecord(withPurpose purpose: Any?) -> MPConsentStateMutationResult {
        guard let purpose = MPConsentStatePRIVATE.canonicalizeForDeduplication(purpose) else {
            return .invalidPurpose
        }
        gdprRecords.removeObject(forKey: purpose)
        return .success
    }

    @objc public func removeAllGDPRConsentRecords() {
        gdprRecords.removeAllObjects()
    }

    @objc public func ccpaConsentRecord() -> MPConsentRecordPRIVATE? {
        ccpaRecord?.copyRecord()
    }

    @objc public func setCCPAConsentRecord(_ record: MPConsentRecordPRIVATE?) {
        ccpaRecord = record?.copyRecord()
    }

    @objc public func removeCCPAConsentRecord() {
        ccpaRecord = nil
    }
}
