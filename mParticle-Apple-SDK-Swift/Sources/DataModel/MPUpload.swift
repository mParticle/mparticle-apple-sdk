import Foundation

@objc(MPUpload)
public final class MPUploadPRIVATE: NSObject, NSCopying {
    @objc public var sessionId: NSNumber?
    @objc public var uploadId: Int64
    @objc public var uuid: String?
    @objc public var uploadData: Data
    @objc public var timestamp: TimeInterval
    @objc public var uploadType: UInt
    @objc public var containsOptOutMessage = false
    @objc public var dataPlanId: String?
    @objc public var dataPlanVersion: NSNumber?
    @objc public var uploadSettings: NSObject

    @objc(initWithSessionId:uploadId:UUID:uploadData:timestamp:uploadType:dataPlanId:dataPlanVersion:uploadSettings:)
    public init(
        sessionId: NSNumber?,
        uploadId: Int64,
        uuid: String?,
        uploadData: Data,
        timestamp: TimeInterval,
        uploadType: UInt,
        dataPlanId: String?,
        dataPlanVersion: NSNumber?,
        uploadSettings: NSObject
    ) {
        self.sessionId = sessionId
        self.uploadId = uploadId
        self.uuid = uuid
        self.uploadData = uploadData
        self.timestamp = timestamp
        self.uploadType = uploadType
        self.dataPlanId = dataPlanId
        self.dataPlanVersion = dataPlanVersion
        self.uploadSettings = uploadSettings
        super.init()
    }

    @objc(initWithSessionId:uploadDictionary:dataPlanId:dataPlanVersion:uploadSettings:)
    public convenience init?(
        sessionId: NSNumber?,
        uploadDictionary: NSDictionary,
        dataPlanId: String?,
        dataPlanVersion: NSNumber?,
        uploadSettings: NSObject
    ) {
        guard let uploadData = Self.serializedUpload(from: uploadDictionary),
              let safeDictionary = try? JSONSerialization.jsonObject(with: uploadData, options: []) as? NSDictionary
        else {
            return nil
        }

        self.init(
            sessionId: sessionId,
            uploadId: 0,
            uuid: safeDictionary["id"] as? String,
            uploadData: uploadData,
            timestamp: (safeDictionary["ct"] as? NSNumber)?.doubleValue ?? 0,
            uploadType: 0,
            dataPlanId: dataPlanId,
            dataPlanVersion: dataPlanVersion,
            uploadSettings: uploadSettings
        )
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

    @objc public func copy(with _: NSZone? = nil) -> Any {
        let settings = (uploadSettings as? NSCopying)?.copy(with: nil) as? NSObject ?? uploadSettings
        let copy = MPUploadPRIVATE(
            sessionId: sessionId,
            uploadId: uploadId,
            uuid: uuid,
            uploadData: uploadData,
            timestamp: timestamp,
            uploadType: uploadType,
            dataPlanId: dataPlanId,
            dataPlanVersion: dataPlanVersion,
            uploadSettings: settings
        )
        copy.containsOptOutMessage = containsOptOutMessage
        return copy
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MPUploadPRIVATE else { return false }
        return isEqual(toUpload: other)
    }

    @objc(isEqualToUpload:)
    public func isEqual(toUpload other: MPUploadPRIVATE) -> Bool {
        sessionId == other.sessionId
            && uploadId == other.uploadId
            && timestamp == other.timestamp
            && dataPlanId == other.dataPlanId
            && dataPlanVersion == other.dataPlanVersion
    }

    override public var hash: Int {
        (sessionId?.hashValue ?? 0)
            ^ (dataPlanId?.hashValue ?? 0)
            ^ (dataPlanVersion?.hashValue ?? 0)
            ^ Int(truncatingIfNeeded: uploadId)
            ^ Int(timestamp)
    }

    override public var description: String {
        "Upload\n Id: \(uploadId)\n UUID: \(uuid ?? "(null)")\n Content: "
            + "\(dictionaryRepresentation()?.description ?? "(null)")\n timestamp: \(String(format: "%.0f", timestamp))"
            + "\n Data Plan: \(dataPlanId ?? "(null)") \(dataPlanVersion?.description ?? "(null)")\n"
    }
}
