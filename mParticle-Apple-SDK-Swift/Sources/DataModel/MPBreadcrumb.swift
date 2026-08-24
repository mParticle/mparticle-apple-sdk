import Foundation

@objc public final class MPBreadcrumbPRIVATE: NSObject {
    @objc public var sessionUUID: String
    @objc public var breadcrumbId: Int64
    @objc public var uuid: String
    @objc public var breadcrumbData: Data
    @objc public var timestamp: TimeInterval
    @objc public var content: String?

    @objc(initWithSessionUUID:breadcrumbId:UUID:breadcrumbData:timestamp:)
    public init(sessionUUID: String, breadcrumbId: Int64, uuid: String, breadcrumbData: Data, timestamp: TimeInterval) {
        self.sessionUUID = sessionUUID
        self.breadcrumbId = breadcrumbId
        self.uuid = uuid
        self.breadcrumbData = breadcrumbData
        self.timestamp = timestamp
        content = String(data: breadcrumbData, encoding: .utf8)
        super.init()
    }

    @objc public func dictionaryRepresentation() -> NSDictionary? {
        guard let breadcrumbInfo = (try? JSONSerialization.jsonObject(with: breadcrumbData, options: [])) as? NSDictionary else {
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
        String(data: breadcrumbData, encoding: .utf8)
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

    @objc public func isEqual(toBreadcrumb other: MPBreadcrumbPRIVATE) -> Bool {
        breadcrumbId == other.breadcrumbId
            && timestamp == other.timestamp
            && uuid == other.uuid
            && sessionUUID == other.sessionUUID
            && breadcrumbData == other.breadcrumbData
    }

    override public var hash: Int {
        Int(truncatingIfNeeded: breadcrumbId)
            ^ Int(timestamp)
            ^ uuid.hashValue
            ^ sessionUUID.hashValue
            ^ breadcrumbData.hashValue
    }
}
