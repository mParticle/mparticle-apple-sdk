import Foundation
import SQLite3

@objc(MPPersistenceStorePRIVATE)
public final class MPPersistenceStorePRIVATE: NSObject {
    private let fileSystem: MPPersistenceFileSystemPRIVATE
    private let logger: MPLog
    private let mpidProvider: () -> NSNumber
    private let uploadSettingsCodec: MPUploadSettingsCoding?
    private let isOptedOut: () -> Bool
    private(set) var connection: MPSQLiteConnection?
    private var isDatabaseSetUp = false
    @objc public let databasePath: String

    var isDatabaseOpen: Bool {
        connection != nil
    }

    init(
        fileSystem: MPPersistenceFileSystemPRIVATE,
        logger: MPLog,
        openImmediately: Bool = true,
        mpidProvider: @escaping () -> NSNumber = { MPUserDefaults.storedMpId() },
        uploadSettingsCodec: MPUploadSettingsCoding? = nil,
        isOptedOut: @escaping () -> Bool = { false }
    ) {
        self.fileSystem = fileSystem
        self.logger = logger
        self.mpidProvider = mpidProvider
        self.uploadSettingsCodec = uploadSettingsCodec
        self.isOptedOut = isOptedOut

        fileSystem.migrateLegacyDatabaseDirectoryIfNeeded()
        fileSystem.removeLegacySessionNumberFileIfNeeded()
        let databaseName = MPPersistenceSchemaPRIVATE.databaseName(
            for: MPPersistenceSchemaPRIVATE.currentDatabaseVersion
        )
        databasePath = fileSystem.resolvedDatabasePath(databaseName: databaseName)
        super.init()

        do {
            // Raise the protection of a file from an earlier SDK version before any connection
            // holds it open.
            fileSystem.protectDatabaseFiles(atPath: databasePath)
            try setupDatabase()
            if openImmediately {
                try openDatabase()
            }
        } catch {
            logger.error("Failed to initialize persistence database: \(error)")
        }
    }

    @objc(initWithFileSystem:logger:uploadSettingsCodec:)
    public convenience init(
        fileSystem: MPPersistenceFileSystemPRIVATE,
        logger: MPLog,
        uploadSettingsCodec: MPUploadSettingsCoding
    ) {
        self.init(
            fileSystem: fileSystem,
            logger: logger,
            openImmediately: true,
            mpidProvider: { MPUserDefaults.storedMpId() },
            uploadSettingsCodec: uploadSettingsCodec,
            isOptedOut: { false }
        )
    }

    @discardableResult
    func openDatabase() throws -> Bool {
        if connection != nil {
            return true
        }
        fileSystem.protectDatabaseFiles(atPath: databasePath)
        if !isDatabaseSetUp {
            // A launch before the first unlock after a reboot cannot open a protected file, so
            // the setup skipped at launch runs at the first open that can read the file.
            do {
                try setupDatabase()
            } catch {
                logger.error("Failed to set up persistence database: \(error)")
            }
        }
        connection = try MPSQLiteConnection(path: databasePath, logger: logger)
        fileSystem.excludeDatabaseFromBackup(atPath: databasePath)
        return true
    }

    func closeDatabase() {
        connection?.close()
        connection = nil
    }

    func resetDatabase() {
        closeDatabase()
        fileSystem.removeDatabaseFileIfExists(atPath: databasePath)
    }

    func resetDatabaseForWorkspaceSwitching() throws {
        try openDatabase()
        defer {
            closeDatabase()
        }
        guard let connection else {
            return
        }
        for statement in MPPersistenceSchemaPRIVATE.workspaceSwitchDeleteStatements {
            guard let statement = statement as? String else {
                continue
            }
            do {
                try connection.execute(statement)
            } catch {
                logger.error("Failed to delete workspace persistence records: \(error)")
            }
        }
    }

    func deleteRecordsOlderThan(_ timestamp: TimeInterval) throws {
        try openDatabase()
        guard let connection else {
            return
        }
        try connection.transaction {
            for sql in MPDatabaseMigrationLogicPRIVATE.deleteRecordsOlderThanStatements {
                guard let sql = sql as? String else {
                    continue
                }
                let statement = try connection.prepare(sql)
                try statement.bind(timestamp, at: 1)
                guard try statement.step() == .done else {
                    continue
                }
            }
        }
    }

    func purgeMemory() {
        connection?.releaseMemory()
    }

    func currentMpid() -> NSNumber {
        mpidProvider()
    }

    func encodeUploadSettings(_ settings: NSObject) -> Data? {
        uploadSettingsCodec?.archiveUploadSettings(settings)
    }

    func decodeUploadSettings(_ data: Data) -> NSObject? {
        uploadSettingsCodec?.unarchiveUploadSettings(data)
    }

    func shouldSuppress(_ upload: MPUploadPRIVATE, optedOut: Bool) -> Bool {
        (optedOut || isOptedOut()) && !upload.containsOptOutMessage
    }

    func requireConnection() throws -> MPSQLiteConnection {
        try openDatabase()
        guard let connection else {
            throw MPSQLiteError(code: SQLITE_CANTOPEN, message: "Database is not open", sql: nil)
        }
        return connection
    }

    private func setupDatabase() throws {
        var database = try MPSQLiteConnection(path: databasePath, logger: logger)
        do {
            guard try database.integrityCheck() else {
                throw MPSQLiteError(code: SQLITE_CORRUPT, message: "Database is corrupted", sql: nil)
            }
        } catch {
            // Only a corrupt file is replaced. A file the device cannot read yet, such as a
            // protected file before the first unlock, keeps its queued events.
            guard Self.shouldRecreateDatabase(after: error) else {
                throw error
            }
            logger.error("Database is corrupted; recreating it.")
            database.close()
            fileSystem.removeDatabaseFileIfExists(atPath: databasePath)
            database = try MPSQLiteConnection(path: databasePath, logger: logger)
        }

        let versionQuery = try database.prepare("PRAGMA user_version")
        let userVersion: Int32
        if try versionQuery.step() == .row {
            userVersion = versionQuery.int(at: 0)
        } else {
            userVersion = 0
        }

        let currentVersion = MPPersistenceSchemaPRIVATE.currentDatabaseVersion.int32Value
        guard userVersion != currentVersion else {
            isDatabaseSetUp = true
            return
        }

        for statement in MPPersistenceSchemaPRIVATE.createTableStatements {
            guard let statement = statement as? String else {
                continue
            }
            try database.execute(statement)
        }
        try database.execute(
            MPPersistenceSchemaPRIVATE.userVersionPragma(
                for: MPPersistenceSchemaPRIVATE.currentDatabaseVersion
            )
        )
        isDatabaseSetUp = true
    }

    static func shouldRecreateDatabase(after error: Error) -> Bool {
        guard let error = error as? MPSQLiteError else {
            return false
        }
        let primaryCode = error.code & 0xFF
        return primaryCode == SQLITE_CORRUPT || primaryCode == SQLITE_NOTADB
    }
}
