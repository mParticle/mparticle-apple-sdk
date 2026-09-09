import XCTest
@testable import mParticle_Apple_SDK_Swift

private final class TestUploadSettingsCodec: NSObject, MPUploadSettingsCoding {
    let decodedSettings = NSObject()
    var shouldEncode = true

    func archiveUploadSettings(_: NSObject) -> Data? {
        shouldEncode ? Data("settings".utf8) : nil
    }

    func unarchiveUploadSettings(_ data: Data) -> NSObject? {
        data == Data("settings".utf8) ? decodedSettings : nil
    }
}

private final class TestPersistenceKeyValueStorage: MPPersistenceKeyValueStorage {
    var values: [String: Any] = [:]
    private(set) var synchronizeCount = 0

    func mpObject(forKey key: String, userId: NSNumber) -> Any? {
        values["\(userId)::\(key)"]
    }

    func setMPObject(_ value: Any?, forKey key: String, userId: NSNumber) {
        values["\(userId)::\(key)"] = value
    }

    func removeMPObject(forKey key: String, userId: NSNumber) {
        values.removeValue(forKey: "\(userId)::\(key)")
    }

    func synchronize() {
        synchronizeCount += 1
    }
}

final class MPPersistenceStoreTests: XCTestCase {
    private var rootDirectory: URL!
    private var logger: MPLog!
    private var fileSystem: MPPersistenceFileSystemPRIVATE!

    override func setUpWithError() throws {
        rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MPPersistenceStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: rootDirectory,
            withIntermediateDirectories: true
        )
        logger = MPLog(logLevel: .none)
        fileSystem = MPPersistenceFileSystemPRIVATE(
            fileManager: .default,
            logger: logger,
            applicationSupportDirectory: rootDirectory.path,
            cachesDirectory: rootDirectory.path,
            documentsDirectory: nil,
            shouldExcludeDirectoryFromBackup: false
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: rootDirectory)
    }

    func testInitializesCurrentSchemaAndOpensDatabase() throws {
        let store = MPPersistenceStorePRIVATE(fileSystem: fileSystem, logger: logger)

        XCTAssertTrue(store.isDatabaseOpen)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.databasePath))
        let version = try XCTUnwrap(store.connection?.prepare("PRAGMA user_version"))
        XCTAssertEqual(try version.step(), .row)
        XCTAssertEqual(version.int(at: 0), MPPersistenceSchemaPRIVATE.currentDatabaseVersion.int32Value)

        let tableCount = try XCTUnwrap(store.connection?.prepare(
            "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = 'messages'"
        ))
        XCTAssertEqual(try tableCount.step(), .row)
        XCTAssertEqual(tableCount.int(at: 0), 1)
    }

    func testOpenAndCloseAreIdempotent() throws {
        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            openImmediately: false
        )

        XCTAssertFalse(store.isDatabaseOpen)
        XCTAssertTrue(try store.openDatabase())
        XCTAssertTrue(try store.openDatabase())
        XCTAssertTrue(store.isDatabaseOpen)
        store.closeDatabase()
        store.closeDatabase()
        XCTAssertFalse(store.isDatabaseOpen)
    }

    func testResetRemovesDatabase() {
        let store = MPPersistenceStorePRIVATE(fileSystem: fileSystem, logger: logger)

        store.resetDatabase()

        XCTAssertFalse(store.isDatabaseOpen)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.databasePath))
    }

    func testWorkspaceResetClearsEveryWorkspaceTableAndClosesDatabase() throws {
        let store = MPPersistenceStorePRIVATE(fileSystem: fileSystem, logger: logger)
        let connection = try XCTUnwrap(store.connection)
        try connection.execute(
            "INSERT INTO integration_attributes (kit_code, attributes_data) VALUES (1, X'01')"
        )
        try connection.execute(
            "INSERT INTO forwarding_records (forwarding_data, mpid) VALUES (X'01', 1)"
        )

        try store.resetDatabaseForWorkspaceSwitching()

        XCTAssertFalse(store.isDatabaseOpen)
        try store.openDatabase()
        for table in ["integration_attributes", "forwarding_records"] {
            let count = try XCTUnwrap(store.connection?.prepare("SELECT COUNT(*) FROM \(table)"))
            XCTAssertEqual(try count.step(), .row)
            XCTAssertEqual(count.int(at: 0), 0)
        }
    }

    func testWorkspaceResetContinuesAfterDeleteFailureAndClosesDatabase() throws {
        let store = MPPersistenceStorePRIVATE(fileSystem: fileSystem, logger: logger)
        let connection = try XCTUnwrap(store.connection)
        try connection.execute(
            "INSERT INTO forwarding_records (forwarding_data, mpid) VALUES (X'01', 1)"
        )
        try connection.execute(
            "INSERT INTO integration_attributes (kit_code, attributes_data) VALUES (1, X'01')"
        )
        try connection.execute("DROP TABLE messages")

        try store.resetDatabaseForWorkspaceSwitching()

        XCTAssertFalse(store.isDatabaseOpen)
        try store.openDatabase()
        for table in ["forwarding_records", "integration_attributes"] {
            let count = try XCTUnwrap(store.connection?.prepare("SELECT COUNT(*) FROM \(table)"))
            XCTAssertEqual(try count.step(), .row)
            XCTAssertEqual(count.int(at: 0), 0)
        }
    }

    func testRetentionDeletesOnlyExpiredRecords() throws {
        let store = MPPersistenceStorePRIVATE(fileSystem: fileSystem, logger: logger)
        let connection = try XCTUnwrap(store.connection)
        try connection.execute(
            "INSERT INTO messages "
                + "(message_type, uuid, timestamp, message_data, mpid) "
                + "VALUES ('e', 'old', 10, X'01', 1), ('e', 'new', 30, X'01', 1)"
        )
        try connection.execute(
            "INSERT INTO uploads "
                + "(uuid, message_data, timestamp, upload_type, upload_settings) "
                + "VALUES ('old', X'01', 10, 0, X'01'), ('new', X'01', 30, 0, X'01')"
        )
        try connection.execute(
            "INSERT INTO sessions "
                + "(uuid, end_time, attributes_data, session_number, mpid, session_user_ids) "
                + "VALUES ('old', 10, X'01', 0, 1, ''), ('new', 30, X'01', 0, 1, '')"
        )

        try store.deleteRecordsOlderThan(20)

        for table in ["messages", "uploads", "sessions"] {
            let uuids = try connection.prepare("SELECT uuid FROM \(table) ORDER BY uuid")
            XCTAssertEqual(try uuids.step(), .row)
            XCTAssertEqual(uuids.string(at: 0), "new")
            XCTAssertEqual(try uuids.step(), .done)
        }
    }

    func testCorruptDatabaseIsRecreated() throws {
        let databaseDirectory = fileSystem.databaseDirectoryPath()
        let databaseName = MPPersistenceSchemaPRIVATE.databaseName(
            for: MPPersistenceSchemaPRIVATE.currentDatabaseVersion
        )
        let databasePath = (databaseDirectory as NSString).appendingPathComponent(databaseName)
        try Data("not a database".utf8).write(to: URL(fileURLWithPath: databasePath))

        let store = MPPersistenceStorePRIVATE(fileSystem: fileSystem, logger: logger)

        XCTAssertTrue(store.isDatabaseOpen)
        XCTAssertTrue(try XCTUnwrap(store.connection).integrityCheck())
    }

    func testSessionRoundTripUpdateArchiveAndDelete() throws {
        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            mpidProvider: { 42 }
        )
        let session = MPSessionPRIVATE(
            sessionId: 0,
            uuid: "session",
            backgroundTime: 2,
            startTime: 10,
            endTime: 20,
            attributes: ["first": "value"],
            numberOfInterruptions: 1,
            eventCounter: 2,
            suspendTime: 15,
            userId: 42,
            sessionUserIds: "42",
            applicationInfo: ["app": "info"],
            deviceInfo: ["device": "info"]
        )

        try store.saveSession(session)
        XCTAssertNotEqual(session.sessionId, 0)
        var fetched = try XCTUnwrap(store.fetchSessions().first)
        XCTAssertEqual(fetched.uuid, "session")
        XCTAssertEqual(fetched.attributesDictionary["first"] as? String, "value")
        XCTAssertEqual(fetched.appInfo?["app"] as? String, "info")

        session.attributesDictionary["second"] = "updated"
        session.endTime = 30
        try store.updateSession(session)
        fetched = try XCTUnwrap(store.fetchSessions().first)
        XCTAssertEqual(fetched.attributesDictionary["second"] as? String, "updated")
        XCTAssertEqual(fetched.endTime, 30)

        XCTAssertNotNil(try store.archiveSession(session))
        XCTAssertNil(try store.archiveSession(session))
        XCTAssertEqual(try store.fetchPreviousSession()?.uuid, "session")

        try store.deleteSession(session)
        XCTAssertTrue(try store.fetchSessions().isEmpty)
    }

    func testMessagesRoundTripGroupAndDelete() throws {
        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            mpidProvider: { 42 }
        )
        let session = MPSessionPRIVATE(startTime: 1, userId: 42, uuid: "session")
        try store.saveSession(session)
        let message = MPMessagePRIVATE(
            sessionId: NSNumber(value: session.sessionId),
            messageId: 0,
            uuid: "message",
            messageType: "e",
            messageData: Data(#"{"event":"value"}"#.utf8),
            timestamp: 10,
            uploadStatus: 1,
            userId: 42,
            dataPlanId: "plan",
            dataPlanVersion: 3
        )

        try store.saveMessage(message)
        XCTAssertNotEqual(message.messageId, 0)
        let groups = try store.fetchMessagesForUploading()
        let grouped = groups[42]?[NSNumber(value: session.sessionId)]?["plan"]?[3]
        XCTAssertEqual(grouped?.first?.uuid, "message")

        message.uploadStatus = 2
        try store.deleteMessages([message])
        XCTAssertTrue(try store.fetchMessagesForUploading().isEmpty)
    }

    func testSessionlessMessagesGroupUnderZeroSessionId() throws {
        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            mpidProvider: { 42 }
        )
        let message = MPMessagePRIVATE(
            sessionId: nil,
            messageId: 0,
            uuid: "sessionless",
            messageType: "e",
            messageData: Data(#"{"event":"value"}"#.utf8),
            timestamp: 10,
            uploadStatus: 1,
            userId: 42,
            dataPlanId: nil,
            dataPlanVersion: nil
        )

        try store.saveMessage(message)

        let groups = try store.fetchMessagesForUploading()
        XCTAssertEqual(groups[42]?[0]?["0"]?[0]?.map(\.uuid), ["sessionless"])
        XCTAssertNil(groups[42]?[-1])
    }

    func testSessionEndAndUploadedMessageQueries() throws {
        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            mpidProvider: { 42 }
        )
        let session = MPSessionPRIVATE(startTime: 1, userId: 42, uuid: "session")
        try store.saveSession(session)
        let message = MPMessagePRIVATE(
            sessionId: NSNumber(value: session.sessionId),
            messageId: 0,
            uuid: "end",
            messageType: "se",
            messageData: Data("{}".utf8),
            timestamp: 10,
            uploadStatus: 2,
            userId: 42,
            dataPlanId: nil,
            dataPlanVersion: nil
        )
        try store.saveMessage(message)

        XCTAssertEqual(try store.fetchSessionEndMessage(in: session)?.uuid, "end")
        XCTAssertEqual(try store.fetchUploadedMessages(in: session).map(\.uuid), ["end"])
    }

    func testBreadcrumbsAreScopedAndPruned() throws {
        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            mpidProvider: { 42 }
        )
        for index in 0...MPPersistenceSchemaPRIVATE.maxBreadcrumbs {
            let message = MPMessagePRIVATE(
                sessionId: nil,
                messageId: 0,
                uuid: "breadcrumb-\(index)",
                messageType: "b",
                messageData: Data(#"{"message":"value"}"#.utf8),
                timestamp: TimeInterval(index),
                uploadStatus: 1,
                userId: 42,
                dataPlanId: nil,
                dataPlanVersion: nil
            )
            try store.saveBreadcrumb(message)
        }

        let breadcrumbs = try store.fetchBreadcrumbs()
        XCTAssertEqual(breadcrumbs.count, MPPersistenceSchemaPRIVATE.maxBreadcrumbs)
        XCTAssertEqual(breadcrumbs.first?.uuid, "breadcrumb-1")
        XCTAssertEqual(breadcrumbs.last?.uuid, "breadcrumb-50")
    }

    func testUploadRoundTripOrderingAndDelete() throws {
        let codec = TestUploadSettingsCodec()
        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            uploadSettingsCodec: codec
        )
        let later = upload(uuid: "later", timestamp: 20)
        let earlier = upload(uuid: "earlier", timestamp: 10)

        XCTAssertTrue(try store.saveUpload(later))
        XCTAssertTrue(try store.saveUpload(earlier))

        var fetched = try store.fetchUploads()
        XCTAssertEqual(fetched.map(\.uuid), ["earlier", "later"])
        XCTAssertTrue(fetched.allSatisfy { $0.uploadSettings === codec.decodedSettings })

        try store.deleteUpload(earlier)
        fetched = try store.fetchUploads()
        XCTAssertEqual(fetched.map(\.uuid), ["later"])
    }

    func testOptOutSuppressesOrdinaryUploadsButKeepsOptOutMessage() throws {
        let codec = TestUploadSettingsCodec()
        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            uploadSettingsCodec: codec,
            isOptedOut: { true }
        )
        let ordinary = upload(uuid: "ordinary", timestamp: 1)
        let optOut = upload(uuid: "opt-out", timestamp: 2)
        optOut.containsOptOutMessage = true

        XCTAssertTrue(try store.saveUpload(ordinary))
        XCTAssertEqual(ordinary.uploadId, 0)
        XCTAssertTrue(try store.saveUpload(optOut))
        XCTAssertEqual(try store.fetchUploads().map(\.uuid), ["opt-out"])
    }

    func testAtomicBatchRollsBackWhenUploadSettingsCannotEncode() throws {
        let codec = TestUploadSettingsCodec()
        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            uploadSettingsCodec: codec
        )
        let message = MPMessagePRIVATE(
            sessionId: nil,
            messageId: 0,
            uuid: "message",
            messageType: "e",
            messageData: Data("{}".utf8),
            timestamp: 1,
            uploadStatus: 1,
            userId: 42,
            dataPlanId: nil,
            dataPlanVersion: nil
        )
        try store.saveMessage(message)
        codec.shouldEncode = false

        XCTAssertFalse(try store.saveUploads([upload(uuid: "upload", timestamp: 1)], deleting: [message]))
        XCTAssertFalse(try store.fetchMessagesForUploading().isEmpty)
        XCTAssertTrue(try store.fetchUploads().isEmpty)
    }

    func testAtomicBatchPersistsUploadsAndDeletesMessages() throws {
        let codec = TestUploadSettingsCodec()
        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            uploadSettingsCodec: codec
        )
        let message = MPMessagePRIVATE(
            sessionId: nil,
            messageId: 0,
            uuid: "message",
            messageType: "e",
            messageData: Data("{}".utf8),
            timestamp: 1,
            uploadStatus: 1,
            userId: 42,
            dataPlanId: nil,
            dataPlanVersion: nil
        )
        try store.saveMessage(message)

        XCTAssertTrue(try store.saveUploads([upload(uuid: "upload", timestamp: 1)], deleting: [message]))
        XCTAssertTrue(try store.fetchMessagesForUploading().isEmpty)
        XCTAssertEqual(try store.fetchUploads().map(\.uuid), ["upload"])
    }

    func testForwardRecordsAndIntegrationAttributesRoundTrip() throws {
        let store = MPPersistenceStorePRIVATE(fileSystem: fileSystem, logger: logger)
        let record = MPForwardRecordPRIVATE(
            recordId: 0,
            dataDictionary: ["timestamp": 1],
            mpid: 42
        )
        try store.saveForwardRecord(record)
        XCTAssertNotEqual(record.forwardRecordId, 0)
        XCTAssertEqual(try store.fetchForwardRecords().first?.mpid, 42)

        let attributes = try XCTUnwrap(MPIntegrationAttributesPRIVATE(
            integrationId: 7,
            attributes: ["key": "value"]
        ))
        try store.saveIntegrationAttributes(attributes)
        XCTAssertEqual(
            try store.fetchIntegrationAttributes(for: 7)?["key"] as? String,
            "value"
        )

        try store.deleteForwardRecords(ids: [NSNumber(value: record.forwardRecordId)])
        try store.deleteIntegrationAttributes(for: 7)
        XCTAssertTrue(try store.fetchForwardRecords().isEmpty)
        XCTAssertTrue(try store.fetchIntegrationAttributes().isEmpty)
    }

    func testConsumerInfoAndCookiesRoundTrip() throws {
        let store = MPPersistenceStorePRIVATE(fileSystem: fileSystem, logger: logger)
        let cookie = MPPersistedCookie(
            id: 0,
            consumerInfoId: 0,
            content: "content",
            domain: "example.com",
            expiration: nil,
            name: "cookie",
            mpid: 42
        )

        let id = try store.saveConsumerInfo(
            mpid: 42,
            uniqueIdentifier: "identifier",
            cookies: [cookie]
        )
        let fetched = try XCTUnwrap(store.fetchConsumerInfo(for: 42))
        XCTAssertEqual(fetched.id, id)
        XCTAssertEqual(fetched.uniqueIdentifier, "identifier")
        XCTAssertEqual(fetched.cookies.first?.name, "cookie")

        try store.deleteConsumerInfo()
        XCTAssertNil(try store.fetchConsumerInfo(for: 42))
        XCTAssertTrue(try store.fetchCookies(for: 42).isEmpty)
    }

    func testMovesDatabaseContentFromMpidZero() throws {
        let store = MPPersistenceStorePRIVATE(fileSystem: fileSystem, logger: logger)
        let connection = try XCTUnwrap(store.connection)
        try connection.execute(
            "INSERT INTO messages (message_type, uuid, timestamp, message_data, mpid) "
                + "VALUES ('e', 'message', 1, X'01', 0)"
        )

        try store.moveDatabaseContentFromMpidZero(to: 42)

        let mpid = try connection.prepare("SELECT mpid FROM messages")
        XCTAssertEqual(try mpid.step(), .row)
        XCTAssertEqual(mpid.int64(at: 0), 42)
    }

    func testConsentStringStoragePrefersDeviceConsent() {
        let storage = TestPersistenceKeyValueStorage()
        let consent = MPPersistenceConsentStringStore(storage: storage)

        consent.setConsentString("user", forMpid: 42)
        XCTAssertEqual(consent.effectiveConsentString(forMpid: 42), "user")
        consent.setDeviceConsentString("device")
        XCTAssertEqual(consent.effectiveConsentString(forMpid: 42), "device")
        consent.setDeviceConsentString(nil)
        XCTAssertEqual(consent.effectiveConsentString(forMpid: 42), "user")
        XCTAssertEqual(storage.synchronizeCount, 3)
    }

    func testUserDefaultsMpidZeroMigrationDoesNotOverwriteDestination() throws {
        let suiteName = "MPPersistenceStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("source", forKey: "mParticle::0::source")
        defaults.set("existing", forKey: "mParticle::42::existing")
        defaults.set("ignored", forKey: "other::0::value")

        MPPersistenceUserDefaultsMigrator(userDefaults: defaults)
            .moveContentFromMpidZero(to: 42)

        XCTAssertEqual(defaults.string(forKey: "mParticle::42::source"), "source")
        XCTAssertEqual(defaults.string(forKey: "mParticle::42::existing"), "existing")
        XCTAssertNil(defaults.object(forKey: "mParticle::0::source"))
        XCTAssertEqual(defaults.string(forKey: "other::0::value"), "ignored")
    }

    func testMigratesVersion30RowsAndPurgesExpiredRecords() throws {
        let oldName = MPPersistenceSchemaPRIVATE.databaseName(for: 30)
        let oldPath = fileSystem.resolvedDatabasePath(databaseName: oldName)
        let old = try MPSQLiteConnection(path: oldPath, logger: logger)
        for sql in MPPersistenceSchemaPRIVATE.createTableStatements {
            try old.execute(try XCTUnwrap(sql as? String))
        }
        try old.execute("DROP TABLE uploads")
        try old.execute(
            "CREATE TABLE uploads ("
                + "_id INTEGER PRIMARY KEY AUTOINCREMENT, session_id INTEGER, uuid TEXT NOT NULL, "
                + "message_data BLOB NOT NULL, timestamp REAL NOT NULL, upload_type INTEGER NOT NULL, "
                + "data_plan_id TEXT, data_plan_version INTEGER)"
        )
        let freshTimestamp = Date().timeIntervalSince1970
        let staleTimestamp = freshTimestamp - MPPersistenceSchemaPRIVATE.sevenDays - 1
        try old.execute(
            "INSERT INTO messages (message_type, uuid, timestamp, message_data, upload_status, mpid) "
                + "VALUES ('e', 'fresh', \(freshTimestamp), X'7B7D', 1, 42), "
                + "('e', 'stale', \(staleTimestamp), X'7B7D', 1, 42)"
        )
        try old.execute(
            "INSERT INTO uploads (uuid, message_data, timestamp, upload_type) "
                + "VALUES ('upload', X'7B7D', \(freshTimestamp), 0)"
        )
        try old.execute(MPPersistenceSchemaPRIVATE.userVersionPragma(for: 30))
        old.close()

        let codec = TestUploadSettingsCodec()
        let migrator = MPDatabaseMigratorPRIVATE(
            databaseVersions: [30, 31],
            fileSystem: fileSystem,
            logger: logger,
            uploadSettingsProvider: { NSObject() },
            uploadSettingsCodec: codec
        )
        XCTAssertEqual(migrator.versionNeedingMigration(), 30)

        try migrator.migrate(from: 30)

        let store = MPPersistenceStorePRIVATE(
            fileSystem: fileSystem,
            logger: logger,
            mpidProvider: { 42 },
            uploadSettingsCodec: codec
        )
        let messages = try store.fetchMessagesForUploading()
        XCTAssertEqual(messages[42]?[-1]?["0"]?[0]?.map(\.uuid), ["fresh"])
        XCTAssertEqual(try store.fetchUploads().map(\.uuid), ["upload"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldPath))
    }

    private func upload(uuid: String, timestamp: TimeInterval) -> MPUploadPRIVATE {
        MPUploadPRIVATE(
            sessionId: nil,
            uploadId: 0,
            uuid: uuid,
            uploadData: Data(#"{"events":[]}"#.utf8),
            timestamp: timestamp,
            uploadType: 0,
            dataPlanId: nil,
            dataPlanVersion: nil,
            uploadSettings: NSObject()
        )
    }
}
