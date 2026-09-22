import Foundation

/// A persisted breadcrumb. Keeps the `MPBreadcrumb` Objective-C runtime name the deleted wrapper
/// had, so `Include/MPPersistenceController.h`'s forward declaration and `-fetchBreadcrumbs`
/// signature stay byte-identical. Reference `MPBreadcrumbPRIVATE` from Swift, `MPBreadcrumb` from
/// Objective-C.
@objc(MPBreadcrumb)
public final class MPBreadcrumbPRIVATE: NSObject, NSCopying, NSSecureCoding {
    @objc public var sessionUUID: String?
    @objc public var breadcrumbId: Int64
    @objc public var uuid: String?
    @objc public var breadcrumbData: Data?
    @objc public var timestamp: TimeInterval
    @objc public var content: String?

    @objc(initWithSessionUUID:breadcrumbId:UUID:breadcrumbData:timestamp:)
    public init(sessionUUID: String?, breadcrumbId: Int64, uuid: String?, breadcrumbData: Data?, timestamp: TimeInterval) {
        self.sessionUUID = sessionUUID
        self.breadcrumbId = breadcrumbId
        self.uuid = uuid
        self.breadcrumbData = breadcrumbData
        self.timestamp = timestamp
        if let breadcrumbData {
            content = String(data: breadcrumbData, encoding: .utf8)
        }
        super.init()
    }

    @objc public func dictionaryRepresentation() -> NSDictionary? {
        guard let breadcrumbData,
              let breadcrumbInfo = (try? JSONSerialization.jsonObject(with: breadcrumbData, options: [])) as? NSDictionary else {
            return nil
        }

        let dictionary = NSMutableDictionary()
        dictionary[MessageKeys.kMPMessageTypeKey] = MessageKeys.kMPMessageTypeLeaveBreadcrumbs
        dictionary[MessageKeys.kMPTimestampKey] = breadcrumbInfo[MessageKeys.kMPTimestampKey]
        dictionary[MessageKeys.kMPMessageIdKey] = breadcrumbInfo[MessageKeys.kMPMessageIdKey]
        dictionary[MessageKeys.kMPSessionIdKey] = breadcrumbInfo[MessageKeys.kMPSessionIdKey]
        dictionary[MessageKeys.kMPSessionStartTimestamp] = breadcrumbInfo[MessageKeys.kMPSessionStartTimestamp]

        if let breadcrumbs = breadcrumbInfo[MessageKeys.kMPLeaveBreadcrumbsKey] {
            dictionary[MessageKeys.kMPLeaveBreadcrumbsKey] = breadcrumbs
        }
        if let attributes = breadcrumbInfo[MessageKeys.kMPAttributesKey] {
            dictionary[MessageKeys.kMPAttributesKey] = attributes
        }
        return dictionary
    }

    @objc public func serializedString() -> String? {
        guard let breadcrumbData else { return nil }
        return String(data: breadcrumbData, encoding: .utf8)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        copyBreadcrumb()
    }

    @objc public func copyBreadcrumb() -> MPBreadcrumbPRIVATE {
        MPBreadcrumbPRIVATE(
            sessionUUID: sessionUUID,
            breadcrumbId: breadcrumbId,
            uuid: uuid,
            breadcrumbData: breadcrumbData,
            timestamp: timestamp
        )
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MPBreadcrumbPRIVATE else { return false }
        return isEqual(toBreadcrumb: other)
    }

    @objc public func isEqual(toBreadcrumb other: MPBreadcrumbPRIVATE) -> Bool {
        breadcrumbId == other.breadcrumbId
            && timestamp == other.timestamp
            && nsStringEqual(uuid, other.uuid)
            && nsStringEqual(sessionUUID, other.sessionUUID)
            && nsDataEqual(breadcrumbData, other.breadcrumbData)
    }

    override public var hash: Int {
        var result = Int(truncatingIfNeeded: breadcrumbId)
        result ^= Int(timestamp)
        result ^= uuid?.hashValue ?? 0
        result ^= sessionUUID?.hashValue ?? 0
        result ^= breadcrumbData?.hashValue ?? 0
        return result
    }

    override public var description: String {
        let renderedTimestamp = String(format: "%.0f", timestamp)
        return "Breadcrumb\n UUID: \(uuid ?? "(null)")\n"
            + " Content: \(content ?? "(null)")\n"
            + " timestamp: \(renderedTimestamp)\n"
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    /// Persists `content` rather than `breadcrumbData`; `init(coder:)` rebuilds the data from it.
    /// The asymmetry is load-bearing for archive round-trip equality — do not "fix" it.
    public func encode(with coder: NSCoder) {
        coder.encode(sessionUUID, forKey: CodingKeys.sessionUUID)
        coder.encode(breadcrumbId, forKey: CodingKeys.breadcrumbId)
        coder.encode(uuid, forKey: CodingKeys.uuid)
        coder.encode(content, forKey: CodingKeys.content)
        coder.encode(breadcrumbData, forKey: CodingKeys.breadcrumbData)
        coder.encode(timestamp, forKey: CodingKeys.timestamp)
    }

    public convenience init?(coder: NSCoder) {
        let content = coder.decodeObject(of: NSString.self, forKey: CodingKeys.content) as String?
        self.init(
            sessionUUID: coder.decodeObject(of: NSString.self, forKey: CodingKeys.sessionUUID) as String?,
            breadcrumbId: coder.decodeInt64(forKey: CodingKeys.breadcrumbId),
            uuid: coder.decodeObject(of: NSString.self, forKey: CodingKeys.uuid) as String?,
            breadcrumbData: content?.data(using: .utf8),
            timestamp: coder.decodeDouble(forKey: CodingKeys.timestamp)
        )
    }

    private enum CodingKeys {
        static let sessionUUID = "sessionUUID"
        static let breadcrumbId = "breadcrumbId"
        static let uuid = "uuid"
        static let content = "content"
        static let breadcrumbData = "breadcrumbData"
        static let timestamp = "timestamp"
    }

    private func nsStringEqual(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs, let rhs else { return false }
        return lhs == rhs
    }

    private func nsDataEqual(_ lhs: Data?, _ rhs: Data?) -> Bool {
        guard let lhs, let rhs else { return false }
        return lhs == rhs
    }
}
