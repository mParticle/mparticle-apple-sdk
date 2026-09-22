import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPPersistenceSchemaTests: XCTestCase {
    func testDatabaseNameAndCurrentVersion() {
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.databaseVersions as? [Int], [30, 31])
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.currentDatabaseVersion, 31)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.databaseName(for: 30), "mParticle30.db")
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.databaseName(for: 31), "mParticle31.db")
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.userVersionPragma(for: 31), "PRAGMA user_version = 31")
    }

    func testMaxBytesUsesCrashType() {
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.maxBytesPerEvent(for: "e"), 100 * 1024)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.maxBytesPerEvent(for: "x"), 1000 * 1024)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.maxBytesPerBatch(for: "e"), 200 * 1024)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.maxBytesPerBatch(for: "x"), 2000 * 1024)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.crashMessageType, "x")
    }

    func testDirectoryPathIsPlatformSpecific() {
        let directory = MPPersistenceSchemaPRIVATE.databaseDirectory(
            applicationSupport: "/app-support",
            cachesDirectory: "/caches"
        )
        #if os(tvOS)
            XCTAssertEqual(directory, "/caches")
        #else
            XCTAssertEqual(directory, "/app-support/mParticle")
        #endif
    }

    func testExistingPathPrefersCurrentDirectoryThenLegacy() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let preferred = root.appendingPathComponent("preferred")
        let legacy = root.appendingPathComponent("legacy")
        try fileManager.createDirectory(at: preferred, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: legacy, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        let name = "mParticle30.db"
        XCTAssertNil(MPPersistenceSchemaPRIVATE.existingPath(
            forDatabaseName: name,
            preferredDirectory: preferred.path,
            legacyDirectory: legacy.path
        ))

        try "legacy".write(to: legacy.appendingPathComponent(name), atomically: true, encoding: .utf8)
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.existingPath(
                forDatabaseName: name,
                preferredDirectory: preferred.path,
                legacyDirectory: legacy.path
            ),
            legacy.appendingPathComponent(name).path
        )

        try "preferred".write(to: preferred.appendingPathComponent(name), atomically: true, encoding: .utf8)
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.existingPath(
                forDatabaseName: name,
                preferredDirectory: preferred.path,
                legacyDirectory: legacy.path
            ),
            preferred.appendingPathComponent(name).path
        )
    }

    func testResolvedDatabasePathFallsBackToPreferredWhenMissing() {
        let path = MPPersistenceSchemaPRIVATE.resolvedDatabasePath(
            preferredDirectory: "/preferred",
            databaseName: "mParticle31.db",
            legacyDirectory: "/legacy"
        )
        XCTAssertEqual(path, "/preferred/mParticle31.db")
    }

    func testVersionNeedingMigrationOnlyChecksFirstOldVersion() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        XCTAssertNil(MPPersistenceSchemaPRIVATE.versionNeedingMigration(
            from: [31],
            preferredDirectory: root.path,
            legacyDirectory: nil
        ))

        try "old".write(to: root.appendingPathComponent("mParticle30.db"), atomically: true, encoding: .utf8)
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.versionNeedingMigration(
                from: [30, 31],
                preferredDirectory: root.path,
                legacyDirectory: nil
            ),
            30
        )
    }

    func testLegacyAndSidecarActions() {
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.legacyFileAction(currentMainExists: true, legacyMainExists: true),
            .removeLegacyMainAndSidecars
        )
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.legacyFileAction(currentMainExists: false, legacyMainExists: false),
            .removeOrphanSidecars
        )
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.legacyFileAction(currentMainExists: false, legacyMainExists: true),
            .migrateMainThenSidecars
        )

        XCTAssertEqual(MPPersistenceSchemaPRIVATE.sidecarAction(legacyExists: false, currentExists: false), .skip)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.sidecarAction(legacyExists: true, currentExists: true), .removeLegacy)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.sidecarAction(legacyExists: true, currentExists: false), .migrate)
    }

    func testDeleteAndMpidSQL() {
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.deleteSQL(table: "messages", ids: [1, 2, 3]),
            "DELETE FROM messages WHERE _id IN (1,2,3)"
        )
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.sqlUpdatingMpid(forTable: "sessions"),
            "UPDATE sessions SET mpid = ? WHERE mpid = 0"
        )
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.mpidKeyedTableNames.count, 6)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.createTableStatements.count, 10)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.maxBreadcrumbs, 50)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.sevenDays, 60 * 60 * 24 * 7)
        XCTAssertEqual(MPPersistenceSchemaPRIVATE.sessionNumberFileName, "SessionNumber")
    }

    func testCookieSQLPreservesOriginalCommaBehavior() {
        let insert = MPPersistenceSchemaPRIVATE.insertCookieSQL(
            content: "c",
            domain: nil,
            expiration: "exp",
            name: "n",
            mpid: 42
        )
        XCTAssertEqual(
            insert,
            "INSERT INTO cookies (consumer_info_id, content, expiration, name, mpid) VALUES (?, 'c', 'exp', 'n', '42')"
        )

        XCTAssertNil(MPPersistenceSchemaPRIVATE.updateCookieSQL(content: nil, domain: nil, expiration: nil))
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.updateCookieSQL(content: "c", domain: "d", expiration: nil),
            "UPDATE cookies SET content = 'c', domain = 'd' WHERE _id = ?"
        )
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.updateCookieSQL(content: nil, domain: "d", expiration: nil),
            "UPDATE cookies SET , domain = 'd' WHERE _id = ?"
        )
    }

    func testUserDefaultsKeyRemap() {
        XCTAssertEqual(
            MPPersistenceSchemaPRIVATE.remappedUserDefaultsKey("mParticle::0::foo", mpid: 99),
            "mParticle::99::foo"
        )
        XCTAssertNil(MPPersistenceSchemaPRIVATE.remappedUserDefaultsKey("other::0::foo", mpid: 99))
    }

    func testMigrationSQLConstants() {
        XCTAssertEqual(MPDatabaseMigrationLogicPRIVATE.deleteRecordsOlderThanStatements.count, 3)
        XCTAssertTrue(MPDatabaseMigrationLogicPRIVATE.migrateSessionsSelectSQL.contains("FROM sessions"))
        XCTAssertTrue(MPDatabaseMigrationLogicPRIVATE.migrateUploadsInsertSQL.contains("upload_settings"))
        XCTAssertTrue(MPDatabaseMigrationLogicPRIVATE.migrateCookiesInsertSQL.contains("consumer_info_id"))
    }
}
