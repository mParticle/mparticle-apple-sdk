import XCTest
@testable import mParticle_Apple_SDK_Swift

private final class InMemoryIdentityCachingStorage: MPIdentityCachingStorage {
    var object: Any?
    var writeCount = 0

    func mpObject(forKey _: String, userId _: NSNumber) -> Any? {
        return object
    }

    func setMPObject(_ value: Any?, forKey _: String, userId _: NSNumber) {
        object = value
        writeCount += 1
    }
}

final class MPIdentityCachingTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000)
    private let identities: NSDictionary = [
        "ios_idfv": "abcdefg",
        "email": "test1@test2.com",
        "customerid": "12345",
        "google": NSNull()
    ]

    private func makeCaching() -> (MPIdentityCaching, InMemoryIdentityCachingStorage) {
        let storage = InMemoryIdentityCachingStorage()
        let logger = MPLog(logLevel: .none)
        let caching = MPIdentityCaching(storage: storage, logger: logger, now: { self.now })
        return (caching, storage)
    }

    private func response(expires: Date? = nil) -> MPIdentityCachedResponse {
        return MPIdentityCachedResponse(
            bodyData: Data("response".utf8),
            statusCode: 200,
            expires: expires ?? now.addingTimeInterval(60)
        )
    }

    func testEndpointRawValuesRemainStable() {
        XCTAssertEqual(MPEndpoint.identityLogin.rawValue, 0)
        XCTAssertEqual(MPEndpoint.identityLogout.rawValue, 1)
        XCTAssertEqual(MPEndpoint.identityIdentify.rawValue, 2)
        XCTAssertEqual(MPEndpoint.identityModify.rawValue, 3)
        XCTAssertEqual(MPEndpoint.events.rawValue, 4)
        XCTAssertEqual(MPEndpoint.config.rawValue, 5)
        XCTAssertEqual(MPEndpoint.alias.rawValue, 6)
    }

    func testCachedResponseDictionaryRoundTripAndEquality() {
        let original = response()

        let restored = MPIdentityCachedResponse(dictionary: original.dictionaryRepresentation)

        XCTAssertEqual(restored, original)
        XCTAssertEqual(restored?.bodyData, Data("response".utf8))
        XCTAssertEqual(restored?.statusCode, 200)
        XCTAssertEqual(restored?.expires, now.addingTimeInterval(60))
        XCTAssertEqual(restored?.hash, original.hash)
    }

    func testCachedResponseRejectsMalformedPersistedDictionaries() {
        XCTAssertNil(MPIdentityCachedResponse(dictionary: [:]))
        XCTAssertNil(MPIdentityCachedResponse(dictionary: [
            MPIdentityCaching.Keys.bodyData: "not data",
            MPIdentityCaching.Keys.statusCode: 200,
            MPIdentityCaching.Keys.expires: now
        ]))
        XCTAssertNil(MPIdentityCachedResponse(dictionary: [
            MPIdentityCaching.Keys.bodyData: Data(),
            MPIdentityCaching.Keys.statusCode: "200",
            MPIdentityCaching.Keys.expires: now
        ]))
    }

    func testSerializationAndHashVectorsRemainStable() {
        let (caching, _) = makeCaching()

        XCTAssertEqual(caching.serializeIdentities(nil), "")
        XCTAssertEqual(caching.serializeIdentities([:]), "")
        XCTAssertEqual(
            caching.serializeIdentities(identities),
            "::customerid:12345::email:test1@test2.com::google:null::ios_idfv:abcdefg"
        )
        XCTAssertEqual(
            caching.hashIdentities(identities),
            "6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1"
        )
        XCTAssertEqual(
            caching.sha256Hash("::email:test@test.com::customerid:12435"),
            "aa58bbc1adccecb75fbb00cf9f424ca2098b8b7273a235a07c473b1b129810b5"
        )
        XCTAssertEqual(
            caching.sha256Hash("::email:null"),
            "46bdfb15bd51f77b7955516d3ac92ec1a90856cac70e9343c510cf39532d2007"
        )
        XCTAssertNil(caching.sha256Hash(nil))
        XCTAssertNil(caching.sha256Hash(""))
    }

    func testSerializationSupportsNumericKeysAndRejectsUnsupportedValues() {
        let (caching, _) = makeCaching()
        let numericIdentity: NSDictionary = [NSNumber(value: 7): "test@test.com"]

        XCTAssertEqual(caching.serializeIdentities(numericIdentity), "::7:test@test.com")
        XCTAssertNil(caching.serializeIdentities(["email": NSNumber(value: 7)]))
    }

    func testCacheKeysIncludeStableEndpointRawValue() {
        let (caching, _) = makeCaching()
        let hash = "6aeb076bd3732431628b4d88c6019274b3d4444393ec041f8975f4e69773e4f1"

        XCTAssertEqual(caching.key(endpoint: .identityLogin, identities: identities), "0::\(hash)")
        XCTAssertEqual(caching.key(endpoint: .identityLogout, identities: identities), "1::\(hash)")
        XCTAssertEqual(caching.key(endpoint: .identityIdentify, identities: identities), "2::\(hash)")
        XCTAssertEqual(caching.key(endpoint: .identityModify, identities: identities), "3::\(hash)")
    }

    func testExtractsKnownIdentities() {
        let (caching, _) = makeCaching()
        let request: NSDictionary = [MPIdentityCaching.Keys.knownIdentities: identities]

        XCTAssertEqual(caching.identities(from: request), identities)
    }

    func testHashesModifyIdentityChangesByIdentityType() {
        let (caching, _) = makeCaching()
        let request: NSDictionary = [
            MPIdentityCaching.Keys.identityChanges: [
                ["old_value": "test1@test1.com", "new_value": "test2@test2.com", "identity_type": "email"],
                ["old_value": NSNull(), "new_value": "12345", "identity_type": "customerid"],
                ["old_value": "1234", "new_value": "5678", "identity_type": "other2"]
            ]
        ]

        let extracted = caching.identities(from: request)

        XCTAssertEqual(extracted?["email"] as? String, "f7d23cbd1bf6f52cb02dc284975e82d6736e7f78c91debe52b8ff662a91bba3f")
        XCTAssertEqual(extracted?["customerid"] as? String, "01b5fceb64d02bf05e06b21e733ad2352f603535c278b1c5da37f7d36e51ed57")
        XCTAssertEqual(extracted?["other2"] as? String, "e544742c897e61c4a4d6fddf3bec3182ba9f611a5f6b6c6bc4b20cfdf4bd7495")
    }

    func testRejectsMalformedRequestDictionaries() {
        let (caching, _) = makeCaching()

        XCTAssertNil(caching.identities(from: [:]))
        XCTAssertNil(caching.identities(from: [MPIdentityCaching.Keys.knownIdentities: "invalid"]))
        XCTAssertNil(caching.identities(from: [MPIdentityCaching.Keys.identityChanges: ["invalid"]]))
        XCTAssertNil(caching.identities(from: [
            MPIdentityCaching.Keys.identityChanges: [["new_value": "value"]]
        ]))
    }

    func testOnlyLoginAndIdentifyResponsesAreCached() {
        let (caching, storage) = makeCaching()
        let request: NSDictionary = [MPIdentityCaching.Keys.knownIdentities: identities]

        caching.cacheIdentityResponse(response(), endpoint: .identityLogout, requestDictionary: request)
        XCTAssertNil(storage.object)
        caching.cacheIdentityResponse(response(), endpoint: .identityModify, requestDictionary: request)
        XCTAssertNil(storage.object)

        caching.cacheIdentityResponse(response(), endpoint: .identityLogin, requestDictionary: request)
        caching.cacheIdentityResponse(response(), endpoint: .identityIdentify, requestDictionary: request)
        XCTAssertEqual((storage.object as? NSDictionary)?.count, 2)
    }

    func testReturnsValidResponseAndMissesExpiredResponse() {
        let (caching, _) = makeCaching()

        caching.cacheIdentityResponse(response(), endpoint: .identityLogin, identities: identities)
        XCTAssertEqual(caching.getCachedIdentityResponse(for: .identityLogin, identities: identities), response())

        caching.cacheIdentityResponse(
            response(expires: now.addingTimeInterval(-1)),
            endpoint: .identityIdentify,
            identities: identities
        )
        XCTAssertNil(caching.getCachedIdentityResponse(for: .identityIdentify, identities: identities))
    }

    func testResponseExpiringExactlyNowRemainsValid() {
        let (caching, _) = makeCaching()
        let expiringNow = response(expires: now)

        caching.cacheIdentityResponse(expiringNow, endpoint: .identityLogin, identities: identities)

        XCTAssertEqual(caching.getCachedIdentityResponse(for: .identityLogin, identities: identities), expiringNow)
    }

    func testModifyAndLogoutLookupsClearAllCachedResponses() {
        let (caching, storage) = makeCaching()
        let request: NSDictionary = [MPIdentityCaching.Keys.knownIdentities: identities]
        caching.cacheIdentityResponse(response(), endpoint: .identityLogin, requestDictionary: request)

        XCTAssertNil(caching.getCachedIdentityResponse(for: .identityModify, requestDictionary: request))
        XCTAssertNil(storage.object)

        caching.cacheIdentityResponse(response(), endpoint: .identityIdentify, requestDictionary: request)
        XCTAssertNil(caching.getCachedIdentityResponse(for: .identityLogout, requestDictionary: request))
        XCTAssertNil(storage.object)
    }

    func testClearExpiredCacheRemovesExpiredAndMalformedEntries() {
        let (caching, storage) = makeCaching()
        caching.setCache([
            "expired": response(expires: now.addingTimeInterval(-1)).dictionaryRepresentation,
            "valid": response().dictionaryRepresentation,
            "invalid-response": "not a dictionary",
            "invalid-expiry": [MPIdentityCaching.Keys.expires: "not a date"],
            "invalid-body": [
                MPIdentityCaching.Keys.bodyData: "not data",
                MPIdentityCaching.Keys.statusCode: 200,
                MPIdentityCaching.Keys.expires: now.addingTimeInterval(60)
            ]
        ])
        let writesBeforeCleanup = storage.writeCount

        caching.clearExpiredCache()

        let cache = storage.object as? NSDictionary
        XCTAssertEqual(cache?.count, 1)
        XCTAssertNotNil(cache?["valid"])
        XCTAssertEqual(storage.writeCount, writesBeforeCleanup + 1)
    }

    func testClearExpiredCacheDoesNotRewriteUnchangedCache() {
        let (caching, storage) = makeCaching()
        caching.setCache(["valid": response().dictionaryRepresentation])
        let writesBeforeCleanup = storage.writeCount

        caching.clearExpiredCache()

        XCTAssertEqual(storage.writeCount, writesBeforeCleanup)
    }

    func testMalformedCachedResponseIsAMiss() {
        let (caching, _) = makeCaching()
        guard let key = caching.key(endpoint: .identityLogin, identities: identities) else {
            return XCTFail("expected cache key")
        }
        caching.setCache([key: [
            MPIdentityCaching.Keys.bodyData: "not data",
            MPIdentityCaching.Keys.statusCode: 200,
            MPIdentityCaching.Keys.expires: now.addingTimeInterval(60)
        ]])

        XCTAssertNil(caching.getCachedIdentityResponse(for: .identityLogin, identities: identities))
    }
}
