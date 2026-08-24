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
}
