import Foundation
import SQLite3

final class MPPersistenceStorePRIVATE {
    private let fileSystem: MPPersistenceFileSystemPRIVATE
    private let logger: MPLog
    private(set) var connection: MPSQLiteConnection?
    let databasePath: String

    var isDatabaseOpen: Bool {
        connection != nil
    }

    init(fileSystem: MPPersistenceFileSystemPRIVATE, logger: MPLog, openImmediately: Bool = true) {
        self.fileSystem = fileSystem
        self.logger = logger

        fileSystem.migrateLegacyDatabaseDirectoryIfNeeded()
        fileSystem.removeLegacySessionNumberFileIfNeeded()
        let databaseName = MPPersistenceSchemaPRIVATE.databaseName(
            for: MPPersistenceSchemaPRIVATE.currentDatabaseVersion
        )
        databasePath = fileSystem.resolvedDatabasePath(databaseName: databaseName)

        do {
            try setupDatabase()
            if openImmediately {
                try openDatabase()
            }
        } catch {
            logger.error("Failed to initialize persistence database: \(error)")
        }
    }

    @discardableResult
    func openDatabase() throws -> Bool {
        if connection != nil {
            return true
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
        guard let connection else {
            return
        }
        for statement in MPPersistenceSchemaPRIVATE.workspaceSwitchDeleteStatements {
            guard let statement = statement as? String else {
                continue
            }
            try connection.execute(statement)
        }
        closeDatabase()
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

    private func setupDatabase() throws {
        var database = try MPSQLiteConnection(path: databasePath, logger: logger)
        do {
            guard try database.integrityCheck() else {
                throw MPSQLiteError(code: SQLITE_CORRUPT, message: "Database is corrupted", sql: nil)
            }
        } catch {
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
    }
}
