import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPPersistenceAdapterTests: XCTestCase {
    private let mpid: NSNumber = 42
    private let live = "2099-01-01T00:00:00Z"
    private let past = "2000-01-01T00:00:00Z"
    private var rootDirectory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: MPPersistenceStorePRIVATE!
    private var adapter: MPPersistenceAdapter!

    override func setUpWithError() throws {
        rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MPPersistenceAdapterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let logger = MPLog(logLevel: .none)
        let fileSystem = MPPersistenceFileSystemPRIVATE(
            fileManager: .default,
            logger: logger,
            applicationSupportDirectory: rootDirectory.path,
            cachesDirectory: rootDirectory.path,
            documentsDirectory: nil,
            shouldExcludeDirectoryFromBackup: false
        )
        store = MPPersistenceStorePRIVATE(fileSystem: fileSystem, logger: logger, mpidProvider: { 42 })
        suiteName = "MPPersistenceAdapterTests-\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        adapter = MPPersistenceAdapter(store: store, userDefaults: defaults)
    }

    override func tearDownWithError() throws {
        store.closeDatabase()
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: rootDirectory)
    }

    private func cookie(_ name: String, expiration: String?, content: String = "value") -> MPCookiePRIVATE {
        let cookie = MPCookiePRIVATE()
        cookie.name = name
        cookie.content = content
        cookie.expiration = expiration
        return cookie
    }

    func testFetchReturnsNilWhenTheUserHasNoCookies() {
        XCTAssertNil(adapter.fetchCookies(forUserId: mpid))
        XCTAssertNil(adapter.fetchConsumerInfo(forUserId: mpid))
    }

    func testFetchMapsNullColumnsToNilAndANullNameToEmpty() throws {
        try XCTUnwrap(store.connection).execute(
            "INSERT INTO cookies (consumer_info_id, content, domain, expiration, name, mpid) "
                + "VALUES (7, NULL, 'example.com', NULL, NULL, 42)"
        )

        let cookies = try XCTUnwrap(adapter.fetchCookies(forUserId: mpid))

        XCTAssertEqual(cookies.count, 1)
        XCTAssertNotEqual(cookies[0].cookieId, 0)
        XCTAssertNil(cookies[0].content)
        XCTAssertEqual(cookies[0].domain, "example.com")
        XCTAssertNil(cookies[0].expiration)
        XCTAssertEqual(cookies[0].name, "")
        let consumerInfo = try XCTUnwrap(adapter.fetchConsumerInfo(forUserId: mpid))
        XCTAssertEqual(consumerInfo.consumerInfoId, 0)
        XCTAssertEqual(consumerInfo.cookies?.map(\.cookieId), [cookies[0].cookieId])
    }

    func testSaveConsumerInfoSkipsExpiredCookiesAndWritesIdsBackInOrder() throws {
        let first = cookie("first", expiration: live)
        let expired = cookie("expired", expiration: past)
        let second = cookie("second", expiration: live)
        let consumerInfo = MPConsumerInfoPRIVATE()
        consumerInfo.cookies = [first, expired, second]

        adapter.save(consumerInfo)

        XCTAssertNotEqual(consumerInfo.consumerInfoId, 0)
        XCTAssertEqual(expired.cookieId, 0)
        let saved = try XCTUnwrap(adapter.fetchCookies(forUserId: mpid))
        XCTAssertEqual(saved.map(\.name), ["first", "second"])
        XCTAssertEqual(saved.map(\.cookieId), [first.cookieId, second.cookieId])
        XCTAssertNotEqual(first.cookieId, second.cookieId)
    }

    func testUpdateConsumerInfoDeletesSavesAndUpdatesByCookieState() throws {
        let kept = cookie("kept", expiration: live)
        let expiring = cookie("expiring", expiration: live)
        let consumerInfo = MPConsumerInfoPRIVATE()
        consumerInfo.cookies = [kept, expiring]
        adapter.save(consumerInfo)
        let keptId = kept.cookieId

        kept.content = "updated"
        expiring.expiration = past
        let added = cookie("added", expiration: live)
        let expiredUnsaved = cookie("expired-unsaved", expiration: past)
        consumerInfo.cookies = [kept, expiring, added, expiredUnsaved]
        adapter.update(consumerInfo)

        XCTAssertEqual(kept.cookieId, keptId)
        XCTAssertNotEqual(added.cookieId, 0)
        XCTAssertEqual(expiredUnsaved.cookieId, 0)
        let saved = try XCTUnwrap(adapter.fetchCookies(forUserId: mpid))
        XCTAssertEqual(saved.map(\.name), ["kept", "added"])
        XCTAssertEqual(saved.map(\.cookieId), [keptId, added.cookieId])
        XCTAssertEqual(saved.first?.content, "updated")
    }

    func testMoveContentFromMpidZeroNeverOverwritesAnExistingUserDefaultsEntry() throws {
        let moved = "mParticle::0::adapterTestMoved"
        let collided = "mParticle::0::adapterTestCollided"
        let movedTarget = "mParticle::77::adapterTestMoved"
        let collidedTarget = "mParticle::77::adapterTestCollided"
        defaults.set("from zero", forKey: moved)
        defaults.set("from zero", forKey: collided)
        defaults.set("already there", forKey: collidedTarget)
        _ = try store.saveCookie(MPPersistedCookie(
            id: 0, consumerInfoId: 0, content: nil, domain: nil, expiration: nil, name: "anonymous", mpid: 0
        ))

        adapter.moveContentFromMpidZero(toMpid: 77)

        XCTAssertNil(defaults.object(forKey: moved))
        XCTAssertNil(defaults.object(forKey: collided))
        XCTAssertEqual(defaults.string(forKey: movedTarget), "from zero")
        XCTAssertEqual(defaults.string(forKey: collidedTarget), "already there")
        XCTAssertEqual(adapter.fetchCookies(forUserId: 77)?.map(\.name), ["anonymous"])
        XCTAssertNil(adapter.fetchCookies(forUserId: 0))
    }

    func testSaveForwardRecordWritesTheStoreIdIntoTheRecord() throws {
        let record = MPForwardRecordPRIVATE(recordId: 0, dataDictionary: ["mid": 1], mpid: mpid)

        adapter.save(record)
        adapter.save(nil as MPForwardRecordPRIVATE?)

        let saved = try store.fetchForwardRecords()
        XCTAssertEqual(saved.count, 1)
        XCTAssertNotEqual(record.forwardRecordId, 0)
        XCTAssertEqual(saved.first?.forwardRecordId, record.forwardRecordId)
    }
}
