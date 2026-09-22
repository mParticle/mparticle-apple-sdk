import CryptoKit
import Foundation

protocol MPIdentityCachingStorage: AnyObject {
    func mpObject(forKey key: String, userId: NSNumber) -> Any?
    func setMPObject(_ value: Any?, forKey key: String, userId: NSNumber)
}

extension MPUserDefaults: MPIdentityCachingStorage {}

@objc public final class MPIdentityCachedResponse: NSObject {
    @objc public let bodyData: Data
    @objc public let statusCode: Int
    @objc public let expires: Date

    @objc(initWithBodyData:statusCode:expires:)
    public init(bodyData: Data, statusCode: Int, expires: Date) {
        self.bodyData = bodyData
        self.statusCode = statusCode
        self.expires = expires
        super.init()
    }

    init?(dictionary: NSDictionary) {
        guard dictionary.count == 3,
              let bodyData = dictionary[MPIdentityCaching.Keys.bodyData] as? Data,
              let statusCode = dictionary[MPIdentityCaching.Keys.statusCode] as? NSNumber,
              let expires = dictionary[MPIdentityCaching.Keys.expires] as? Date
        else {
            return nil
        }

        self.bodyData = bodyData
        self.statusCode = statusCode.intValue
        self.expires = expires
        super.init()
    }

    var dictionaryRepresentation: NSDictionary {
        return [
            MPIdentityCaching.Keys.bodyData: bodyData,
            MPIdentityCaching.Keys.statusCode: NSNumber(value: statusCode),
            MPIdentityCaching.Keys.expires: expires
        ]
    }

    override public var hash: Int {
        return (bodyData as NSData).hash ^ statusCode ^ (expires as NSDate).hash
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let response = object as? MPIdentityCachedResponse else {
            return false
        }
        return bodyData == response.bodyData
            && statusCode == response.statusCode
            && expires == response.expires
    }
}

@objc public final class MPIdentityCaching: NSObject {
    enum Keys {
        static let cache = "kMPIdentityCachingCachedIdentityCallsKey"
        static let bodyData = "kMPIdentityCachingBodyData"
        static let statusCode = "kMPIdentityCachingStatusCode"
        static let expires = "kMPIdentityCachingExpires"
        static let knownIdentities = "known_identities"
        static let identityChanges = "identity_changes"
        static let identityType = "identity_type"
    }

    private static let cacheUserId = NSNumber(value: 0)

    private let storage: MPIdentityCachingStorage
    private let logger: MPLog
    private let now: () -> Date

    @objc(initWithUserDefaults:logger:)
    public convenience init(userDefaults: MPUserDefaults, logger: MPLog) {
        self.init(storage: userDefaults, logger: logger)
    }

    init(
        storage: MPIdentityCachingStorage,
        logger: MPLog,
        now: @escaping () -> Date = Date.init
    ) {
        self.storage = storage
        self.logger = logger
        self.now = now
        super.init()
    }

    @objc(cacheIdentityResponse:endpoint:requestDictionary:)
    public func cacheIdentityResponse(
        _ cachedResponse: MPIdentityCachedResponse,
        endpoint: MPEndpoint,
        requestDictionary: NSDictionary
    ) {
        guard endpoint == .identityIdentify || endpoint == .identityLogin,
              let identities = identities(from: requestDictionary)
        else {
            return
        }
        cacheIdentityResponse(cachedResponse, endpoint: endpoint, identities: identities)
    }

    @objc(getCachedIdentityResponseForEndpoint:requestDictionary:)
    public func getCachedIdentityResponse(
        for endpoint: MPEndpoint,
        requestDictionary: NSDictionary
    ) -> MPIdentityCachedResponse? {
        switch endpoint {
        case .identityIdentify, .identityLogin:
            guard let identities = identities(from: requestDictionary) else {
                return nil
            }
            return getCachedIdentityResponse(for: endpoint, identities: identities)
        case .identityModify, .identityLogout:
            clearAllCache()
            return nil
        case .events, .config, .alias:
            return nil
        }
    }

    @objc public func clearAllCache() {
        setCache(nil)
        logger.verbose("Identity Caching - Removed all cached responses")
    }

    @objc public func clearExpiredCache() {
        guard let cache = getCache() else {
            logger.verbose("Identity Caching - Removed 0 expired cached responses")
            return
        }
        guard let mutableCache = cache.mutableCopy() as? NSMutableDictionary else {
            return
        }

        var numberRemoved = 0
        cache.enumerateKeysAndObjects { key, object, _ in
            guard let dictionary = object as? NSDictionary,
                  let cachedResponse = MPIdentityCachedResponse(dictionary: dictionary),
                  cachedResponse.expires.timeIntervalSince(self.now()) >= 0
            else {
                mutableCache.removeObject(forKey: key)
                numberRemoved += 1
                return
            }
        }

        logger.verbose("Identity Caching - Removed \(numberRemoved) expired cached responses")
        if cache.count != mutableCache.count {
            setCache(mutableCache)
        }
    }

    func cacheIdentityResponse(
        _ cachedResponse: MPIdentityCachedResponse,
        endpoint: MPEndpoint,
        identities: NSDictionary
    ) {
        guard endpoint == .identityIdentify || endpoint == .identityLogin,
              let key = key(endpoint: endpoint, identities: identities)
        else {
            return
        }

        let mutableCache = (getCache()?.mutableCopy() as? NSMutableDictionary) ?? NSMutableDictionary()
        mutableCache[key] = cachedResponse.dictionaryRepresentation
        setCache(mutableCache)
        logger.verbose(
            "Identity Caching - Cached response for endpoint \(endpoint.rawValue), key: \(key), "
                + "expires: \(cachedResponse.expires), bodyData.length: \(cachedResponse.bodyData.count)"
        )
    }

    func getCachedIdentityResponse(
        for endpoint: MPEndpoint,
        identities: NSDictionary
    ) -> MPIdentityCachedResponse? {
        guard let key = key(endpoint: endpoint, identities: identities),
              let object = getCache()?[key]
        else {
            return nil
        }
        guard let dictionary = object as? NSDictionary,
              let cachedResponse = MPIdentityCachedResponse(dictionary: dictionary)
        else {
            logger.verbose("Identity Caching - No cached response found for key: \(key)")
            return nil
        }

        let currentDate = now()
        let secondsSinceExpiration = currentDate.timeIntervalSince(cachedResponse.expires)
        if secondsSinceExpiration > 0 {
            logger.verbose(
                "Identity Caching - Expired cached response found for key: \(key), "
                    + "expired: \(cachedResponse.expires), "
                    + "seconds since expired: \(String(format: "%.1f", secondsSinceExpiration))"
            )
            return nil
        }

        logger.verbose(
            "Identity Caching - Valid cached response found for key: \(key), "
                + "expires: \(cachedResponse.expires), "
                + "seconds left: \(String(format: "%.1f", cachedResponse.expires.timeIntervalSince(currentDate)))"
        )
        return cachedResponse
    }

    func getCache() -> NSDictionary? {
        return storage.mpObject(forKey: Keys.cache, userId: Self.cacheUserId) as? NSDictionary
    }

    func setCache(_ cache: NSDictionary?) {
        storage.setMPObject(cache, forKey: Keys.cache, userId: Self.cacheUserId)
    }

    func key(endpoint: MPEndpoint, identities: NSDictionary) -> String? {
        guard let hash = hashIdentities(identities) else {
            return nil
        }
        return "\(endpoint.rawValue)::\(hash)"
    }

    func identities(from requestDictionary: NSDictionary) -> NSDictionary? {
        if let knownIdentities = requestDictionary[Keys.knownIdentities] as? NSDictionary {
            return knownIdentities
        }
        if requestDictionary[Keys.knownIdentities] != nil {
            return nil
        }

        guard let identityChanges = requestDictionary[Keys.identityChanges] as? NSArray else {
            return nil
        }

        let identities = NSMutableDictionary(capacity: identityChanges.count)
        for object in identityChanges {
            guard let change = object as? NSDictionary,
                  let identityType = change[Keys.identityType] as? String
            else {
                return nil
            }
            if let hash = hashIdentities(change) {
                identities[identityType] = hash
            }
        }
        return identities
    }

    func hashIdentities(_ identities: NSDictionary?) -> String? {
        guard let serializedIdentities = serializeIdentities(identities) else {
            return nil
        }
        return sha256Hash(serializedIdentities)
    }

    func serializeIdentities(_ identities: NSDictionary?) -> String? {
        guard let identities else {
            return ""
        }

        let sortedKeys = identities.allKeys.sorted(by: compareIdentityKeys)
        var serialized = ""
        for key in sortedKeys {
            serialized += "::\(key)"
            let value = identities[key]
            if let string = value as? String {
                serialized += ":\(string)"
            } else if value is NSNull {
                serialized += ":null"
            } else {
                return nil
            }
        }
        return serialized
    }

    func sha256Hash(_ string: String?) -> String? {
        guard let string, !string.isEmpty else {
            return nil
        }
        let digest = SHA256.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func compareIdentityKeys(_ lhs: Any, _ rhs: Any) -> Bool {
        if let lhs = lhs as? String, let rhs = rhs as? String {
            return lhs.compare(rhs) == .orderedAscending
        }
        if let lhs = lhs as? NSNumber, let rhs = rhs as? NSNumber {
            return lhs.compare(rhs) == .orderedAscending
        }
        return String(describing: lhs).compare(String(describing: rhs)) == .orderedAscending
    }
}
