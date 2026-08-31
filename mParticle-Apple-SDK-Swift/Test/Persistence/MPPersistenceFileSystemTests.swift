import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPPersistenceFileSystemTests: XCTestCase {
    private var root: URL!
    private var applicationSupport: URL!
    private var caches: URL!
    private var documents: URL!
    private var logger: MPLog!
    private var messages: [String]!

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        applicationSupport = root.appendingPathComponent("ApplicationSupport")
        caches = root.appendingPathComponent("Caches")
        documents = root.appendingPathComponent("Documents")
        try FileManager.default.createDirectory(at: applicationSupport, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        messages = []
        logger = MPLog(logLevel: .error)
        logger.customLogger = { [weak self] in self?.messages.append($0) }
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
        messages = nil
        logger = nil
        documents = nil
        caches = nil
        applicationSupport = nil
        root = nil
        try super.tearDownWithError()
    }

    func testDatabaseDirectoryIsCreated() {
        let fileSystem = makeFileSystem()
        let directory = fileSystem.databaseDirectoryPath()

        #if os(tvOS)
            XCTAssertEqual(directory, caches.path)
        #else
            XCTAssertEqual(directory, applicationSupport.appendingPathComponent("mParticle").path)
        #endif
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory))
    }

    #if os(iOS)
        func testMigratesLegacyDatabaseAndSidecars() throws {
            let fileSystem = makeFileSystem()
            let legacyDatabase = documents.appendingPathComponent("mParticle31.db")
            let legacyWAL = URL(fileURLWithPath: legacyDatabase.path + "-wal")
            try Data("database".utf8).write(to: legacyDatabase)
            try Data("wal".utf8).write(to: legacyWAL)

            fileSystem.migrateLegacyDatabaseDirectoryIfNeeded()

            let currentDatabase = applicationSupport
                .appendingPathComponent("mParticle")
                .appendingPathComponent("mParticle31.db")
            XCTAssertFalse(FileManager.default.fileExists(atPath: legacyDatabase.path))
            XCTAssertFalse(FileManager.default.fileExists(atPath: legacyWAL.path))
            XCTAssertEqual(try Data(contentsOf: currentDatabase), Data("database".utf8))
            XCTAssertEqual(
                try Data(contentsOf: URL(fileURLWithPath: currentDatabase.path + "-wal")),
                Data("wal".utf8)
            )
        }

        func testExistingCurrentDatabaseRemovesLegacyDatabaseAndSidecars() throws {
            let fileSystem = makeFileSystem()
            let currentDirectory = URL(fileURLWithPath: fileSystem.databaseDirectoryPath())
            let currentDatabase = currentDirectory.appendingPathComponent("mParticle31.db")
            let legacyDatabase = documents.appendingPathComponent("mParticle31.db")
            let legacyWAL = URL(fileURLWithPath: legacyDatabase.path + "-wal")
            try Data("current".utf8).write(to: currentDatabase)
            try Data("legacy".utf8).write(to: legacyDatabase)
            try Data("legacy-wal".utf8).write(to: legacyWAL)

            fileSystem.migrateLegacyDatabaseDirectoryIfNeeded()

            XCTAssertEqual(try Data(contentsOf: currentDatabase), Data("current".utf8))
            XCTAssertFalse(FileManager.default.fileExists(atPath: legacyDatabase.path))
            XCTAssertFalse(FileManager.default.fileExists(atPath: legacyWAL.path))
        }

        func testOrphanLegacySidecarIsRemoved() throws {
            let fileSystem = makeFileSystem()
            let legacyWAL = URL(fileURLWithPath: documents.appendingPathComponent("mParticle31.db").path + "-wal")
            try Data("orphan".utf8).write(to: legacyWAL)

            fileSystem.migrateLegacyDatabaseDirectoryIfNeeded()

            XCTAssertFalse(FileManager.default.fileExists(atPath: legacyWAL.path))
        }

        func testFailedMigrationPreservesLegacyDatabaseAndLogsThroughInjectedLogger() throws {
            let blockedDirectory = applicationSupport.appendingPathComponent("mParticle")
            try Data("not-a-directory".utf8).write(to: blockedDirectory)
            let fileSystem = makeFileSystem()
            let legacyDatabase = documents.appendingPathComponent("mParticle31.db")
            try Data("queued-events".utf8).write(to: legacyDatabase)

            fileSystem.migrateLegacyDatabaseDirectoryIfNeeded()

            XCTAssertTrue(FileManager.default.fileExists(atPath: legacyDatabase.path))
            XCTAssertTrue(messages.contains {
                $0.contains("Failed to migrate database from Documents to Application Support")
                    && $0.contains(legacyDatabase.path)
            })
        }

        func testRemovesLegacySessionNumberFile() throws {
            let fileSystem = makeFileSystem()
            let sessionNumber = documents.appendingPathComponent("SessionNumber")
            try Data("42".utf8).write(to: sessionNumber)

            fileSystem.removeLegacySessionNumberFileIfNeeded()

            XCTAssertFalse(FileManager.default.fileExists(atPath: sessionNumber.path))
        }
    #endif

    func testExistingAndResolvedDatabasePathsUseFileSystemDirectories() throws {
        let fileSystem = makeFileSystem()
        let databaseName = "mParticle30.db"
        let preferredDirectory = URL(fileURLWithPath: fileSystem.databaseDirectoryPath())
        let preferredDatabase = preferredDirectory.appendingPathComponent(databaseName)
        try Data("database".utf8).write(to: preferredDatabase)

        XCTAssertEqual(fileSystem.existingPath(forDatabaseName: databaseName), preferredDatabase.path)
        XCTAssertEqual(fileSystem.resolvedDatabasePath(databaseName: databaseName), preferredDatabase.path)
        XCTAssertEqual(fileSystem.versionNeedingMigration(from: [30, 31]), 30)
    }

    func testRemovesDatabaseFile() throws {
        let fileSystem = makeFileSystem()
        let database = root.appendingPathComponent("database.db")
        try Data("database".utf8).write(to: database)

        XCTAssertTrue(fileSystem.removeDatabaseFileIfExists(atPath: database.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: database.path))
        XCTAssertFalse(fileSystem.removeDatabaseFileIfExists(atPath: database.path))
    }

    func testDirectoryCreationFailureUsesInjectedLogger() throws {
        let blockedParent = root.appendingPathComponent("blocked")
        try Data("not-a-directory".utf8).write(to: blockedParent)
        let nestedDirectory = blockedParent.appendingPathComponent("nested").path
        let fileSystem = MPPersistenceFileSystemPRIVATE(
            fileManager: .default,
            logger: logger,
            applicationSupportDirectory: nestedDirectory,
            cachesDirectory: nestedDirectory,
            documentsDirectory: documents.path,
            shouldExcludeDirectoryFromBackup: false
        )

        _ = fileSystem.databaseDirectoryPath()

        XCTAssertTrue(messages.contains { $0.contains("Failed to create database directory") })
    }

    private func makeFileSystem() -> MPPersistenceFileSystemPRIVATE {
        MPPersistenceFileSystemPRIVATE(
            fileManager: .default,
            logger: logger,
            applicationSupportDirectory: applicationSupport.path,
            cachesDirectory: caches.path,
            documentsDirectory: documents.path,
            shouldExcludeDirectoryFromBackup: false
        )
    }
}
