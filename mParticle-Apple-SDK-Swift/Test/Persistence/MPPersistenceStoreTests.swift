import XCTest
@testable import mParticle_Apple_SDK_Swift

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
}
