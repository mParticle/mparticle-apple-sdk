import Foundation

@objc public final class MPUploadPRIVATE: NSObject {
    @objc public var sessionId: NSNumber?
    @objc public var uploadId: Int64
    @objc public var uuid: String?
    @objc public var uploadData: Data
    @objc public var timestamp: TimeInterval
    @objc public var uploadType: UInt
    @objc public var containsOptOutMessage = false
    @objc public var dataPlanId: String?
    @objc public var dataPlanVersion: NSNumber?

    @objc(initWithSessionId:uploadId:UUID:uploadData:timestamp:uploadType:dataPlanId:dataPlanVersion:)
    public init(
        sessionId: NSNumber?,
        uploadId: Int64,
        uuid: String?,
        uploadData: Data,
        timestamp: TimeInterval,
        uploadType: UInt,
        dataPlanId: String?,
        dataPlanVersion: NSNumber?
    ) {
        self.sessionId = sessionId
        self.uploadId = uploadId
        self.uuid = uuid
        self.uploadData = uploadData
        self.timestamp = timestamp
        self.uploadType = uploadType
        self.dataPlanId = dataPlanId
        self.dataPlanVersion = dataPlanVersion
        super.init()
    }

    @objc(serializedUploadFromDictionary:)
    public static func serializedUpload(from dictionary: NSDictionary) -> Data? {
        do {
            guard let safeDictionary = MPJSONCopyPRIVATE.deepCopyJSONObject(dictionary) as? NSDictionary,
                  JSONSerialization.isValidJSONObject(safeDictionary)
            else {
                return nil
            }
            return try JSONSerialization.data(withJSONObject: safeDictionary, options: [])
        } catch {
            NSLog("mParticle -> Exception serializing upload dictionary: %@", error.localizedDescription)
            return nil
        }
    }

    @objc public func dictionaryRepresentation() -> NSDictionary? {
        (try? JSONSerialization.jsonObject(with: uploadData, options: [])) as? NSDictionary
    }

    @objc public func serializedString() -> String? {
        String(data: uploadData, encoding: .utf8)
    }

    @objc public func copyUpload() -> MPUploadPRIVATE {
        let copy = MPUploadPRIVATE(
            sessionId: sessionId,
            uploadId: uploadId,
            uuid: uuid,
            uploadData: uploadData,
            timestamp: timestamp,
            uploadType: uploadType,
            dataPlanId: dataPlanId,
            dataPlanVersion: dataPlanVersion
        )
        copy.containsOptOutMessage = containsOptOutMessage
        return copy
    }

    @objc public func isEqual(toUpload other: MPUploadPRIVATE) -> Bool {
        optionalNumberEqual(sessionId, other.sessionId)
            && uploadId == other.uploadId
            && timestamp == other.timestamp
            && optionalEqual(dataPlanId, other.dataPlanId)
            && optionalNumberEqual(dataPlanVersion, other.dataPlanVersion)
    }

    override public var hash: Int {
        (sessionId?.hashValue ?? 0)
            ^ (dataPlanId?.hashValue ?? 0)
            ^ (dataPlanVersion?.hashValue ?? 0)
            ^ Int(truncatingIfNeeded: uploadId)
            ^ Int(timestamp)
    }

    private func optionalEqual(_ lhs: String?, _ rhs: String?) -> Bool {
        (lhs == nil && rhs == nil) || lhs == rhs
    }

    private func optionalNumberEqual(_ lhs: NSNumber?, _ rhs: NSNumber?) -> Bool {
        (lhs == nil && rhs == nil) || lhs == rhs
    }
}
