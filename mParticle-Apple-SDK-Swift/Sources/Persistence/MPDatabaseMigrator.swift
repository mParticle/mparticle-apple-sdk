import Foundation

@objc public protocol MPUploadSettingsProviding: AnyObject {
    func currentUploadSettings() -> NSObject?
}

@objc(MPDatabaseMigratorPRIVATE)
public final class MPDatabaseMigratorPRIVATE: NSObject {
    private let databaseVersions: [NSNumber]
    private let fileSystem: MPPersistenceFileSystemPRIVATE
    private let logger: MPLog
    private let uploadSettingsProvider: () -> NSObject?
    private let uploadSettingsCodec: MPUploadSettingsCoding

    init(
        databaseVersions: [NSNumber],
        fileSystem: MPPersistenceFileSystemPRIVATE,
        logger: MPLog,
        uploadSettingsProvider: @escaping () -> NSObject?,
        uploadSettingsCodec: MPUploadSettingsCoding
    ) {
        self.databaseVersions = databaseVersions
        self.fileSystem = fileSystem
        self.logger = logger
        self.uploadSettingsProvider = uploadSettingsProvider
        self.uploadSettingsCodec = uploadSettingsCodec
        super.init()
    }

    @objc(initWithDatabaseVersions:fileSystem:logger:uploadSettingsProvider:uploadSettingsCodec:)
    public convenience init(
        databaseVersions: NSArray,
        fileSystem: MPPersistenceFileSystemPRIVATE,
        logger: MPLog,
        uploadSettingsProvider: MPUploadSettingsProviding,
        uploadSettingsCodec: MPUploadSettingsCoding
    ) {
        self.init(
            databaseVersions: databaseVersions.compactMap { $0 as? NSNumber },
            fileSystem: fileSystem,
            logger: logger,
            uploadSettingsProvider: { uploadSettingsProvider.currentUploadSettings() },
            uploadSettingsCodec: uploadSettingsCodec
        )
    }

    @objc
    public func versionNeedingMigration() -> NSNumber? {
        fileSystem.versionNeedingMigration(from: databaseVersions as NSArray)
    }

    @objc(migrateFromVersion:)
    public func objectiveCMigrate(from oldVersion: NSNumber) -> Bool {
        do {
            try migrate(from: oldVersion)
            return true
        } catch {
            logger.error("Failed to migrate persistence database: \(error)")
            return false
        }
    }

    func migrate(from oldVersion: NSNumber, deleteOldDatabase: Bool = true) throws {
        guard let currentVersion = databaseVersions.last,
              let oldPath = fileSystem.existingPath(
                  forDatabaseName: MPPersistenceSchemaPRIVATE.databaseName(for: oldVersion)
              )
        else {
            return
        }
        let currentPath = fileSystem.resolvedDatabasePath(
            databaseName: MPPersistenceSchemaPRIVATE.databaseName(for: currentVersion)
        )
        let current = try MPSQLiteConnection(path: currentPath, logger: logger)
        try createCurrentSchema(in: current, version: currentVersion)
        let old = try MPSQLiteConnection(path: oldPath, logger: logger)
        try deleteExpiredRecords(in: old)

        try current.transaction {
            try migrateSessions(from: old, to: current)
            try migrateMessages(from: old, to: current)
            try migrateUploads(from: old, to: current)
            try migrateForwardRecords(from: old, to: current)
            try migrateConsumerInfo(from: old, to: current)
            try migrateCookies(from: old, to: current)
            try migrateIntegrationAttributes(from: old, to: current)
        }
        old.close()
        current.close()
        if deleteOldDatabase {
            fileSystem.removeDatabaseFileIfExists(atPath: oldPath)
        }
    }

    private func createCurrentSchema(in database: MPSQLiteConnection, version: NSNumber) throws {
        for sql in MPPersistenceSchemaPRIVATE.createTableStatements {
            if let sql = sql as? String {
                try database.execute(sql)
            }
        }
        try database.execute(MPPersistenceSchemaPRIVATE.userVersionPragma(for: version))
    }

    private func deleteExpiredRecords(in database: MPSQLiteConnection) throws {
        let cutoff = Date().timeIntervalSince1970 - MPPersistenceSchemaPRIVATE.sevenDays
        try database.transaction {
            for sql in MPDatabaseMigrationLogicPRIVATE.deleteRecordsOlderThanStatements {
                guard let sql = sql as? String else {
                    continue
                }
                let statement = try database.prepare(sql)
                try statement.bind(cutoff, at: 1)
                _ = try statement.step()
            }
        }
    }

    private func migrateSessions(from old: MPSQLiteConnection, to current: MPSQLiteConnection) throws {
        let select = try old.prepare(MPDatabaseMigrationLogicPRIVATE.migrateSessionsSelectSQL)
        let insert = try current.prepare(MPDatabaseMigrationLogicPRIVATE.migrateSessionsInsertSQL)
        while try select.step() == .row {
            try insert.bind(select.string(at: 0), at: 1)
            try insert.bind(select.double(at: 5), at: 2)
            try insert.bind(select.double(at: 1), at: 3)
            try insert.bind(select.double(at: 2), at: 4)
            try insert.bind(select.data(at: 3), at: 5)
            try insert.bind(Int64(0), at: 6)
            try insert.bind(select.int(at: 6), at: 7)
            try insert.bind(select.int(at: 7), at: 8)
            try insert.bind(select.double(at: 8), at: 9)
            try insert.bind(select.double(at: 9), at: 10)
            try insert.bind(select.int64(at: 10), at: 11)
            try insert.bind(select.string(at: 11), at: 12)
            try insert.bind(select.data(at: 12), at: 13)
            try insert.bind(select.data(at: 13), at: 14)
            _ = try insert.step()
            try insert.reset()
        }
    }

    private func migrateMessages(from old: MPSQLiteConnection, to current: MPSQLiteConnection) throws {
        let select = try old.prepare(MPDatabaseMigrationLogicPRIVATE.migrateMessagesSelectSQL)
        let insert = try current.prepare(MPDatabaseMigrationLogicPRIVATE.migrateMessagesInsertSQL)
        while try select.step() == .row {
            try insert.bind(select.string(at: 0), at: 1)
            try bindNullableInt64(from: select, column: 1, to: insert, index: 2)
            try insert.bind(select.string(at: 2), at: 3)
            try insert.bind(select.double(at: 3), at: 4)
            try insert.bind(select.data(at: 4), at: 5)
            try insert.bind(select.int(at: 5), at: 6)
            try insert.bind(select.string(at: 6), at: 7)
            try bindNullableInt64(from: select, column: 7, to: insert, index: 8)
            try insert.bind(select.int64(at: 8), at: 9)
            _ = try insert.step()
            try insert.reset()
        }
    }

    private func migrateUploads(from old: MPSQLiteConnection, to current: MPSQLiteConnection) throws {
        guard let settings = uploadSettingsProvider(),
              let settingsData = uploadSettingsCodec.archiveUploadSettings(settings)
        else {
            return
        }
        let select = try old.prepare(MPDatabaseMigrationLogicPRIVATE.migrateUploadsSelectSQL)
        let insert = try current.prepare(MPDatabaseMigrationLogicPRIVATE.migrateUploadsInsertSQL)
        while try select.step() == .row {
            try insert.bind(select.string(at: 0), at: 1)
            try insert.bind(select.data(at: 1), at: 2)
            try insert.bind(select.double(at: 2), at: 3)
            try bindNullableInt64(from: select, column: 3, to: insert, index: 4)
            try insert.bind(select.int64(at: 4), at: 5)
            try insert.bind(select.string(at: 5), at: 6)
            try bindNullableInt64(from: select, column: 6, to: insert, index: 7)
            try insert.bind(settingsData, at: 8)
            _ = try insert.step()
            try insert.reset()
        }
    }

    private func migrateForwardRecords(
        from old: MPSQLiteConnection,
        to current: MPSQLiteConnection
    ) throws {
        let select = try old.prepare(MPDatabaseMigrationLogicPRIVATE.migrateForwardingRecordsSelectSQL)
        let insert = try current.prepare(MPDatabaseMigrationLogicPRIVATE.migrateForwardingRecordsInsertSQL)
        while try select.step() == .row {
            try insert.bind(select.int64(at: 0), at: 1)
            try insert.bind(select.data(at: 1), at: 2)
            try insert.bind(select.int64(at: 2), at: 3)
            _ = try insert.step()
            try insert.reset()
        }
    }

    private func migrateConsumerInfo(from old: MPSQLiteConnection, to current: MPSQLiteConnection) throws {
        let select = try old.prepare(MPDatabaseMigrationLogicPRIVATE.migrateConsumerInfoSelectSQL)
        let insert = try current.prepare(MPDatabaseMigrationLogicPRIVATE.migrateConsumerInfoInsertSQL)
        while try select.step() == .row {
            try insert.bind(select.int64(at: 0), at: 1)
            try insert.bind(select.int64(at: 1), at: 2)
            try insert.bind(select.string(at: 2), at: 3)
            _ = try insert.step()
            try insert.reset()
        }
    }

    private func migrateCookies(from old: MPSQLiteConnection, to current: MPSQLiteConnection) throws {
        let select = try old.prepare(MPDatabaseMigrationLogicPRIVATE.migrateCookiesSelectSQL)
        let insert = try current.prepare(MPDatabaseMigrationLogicPRIVATE.migrateCookiesInsertSQL)
        while try select.step() == .row {
            try insert.bind(select.int64(at: 0), at: 1)
            try insert.bind(select.int64(at: 1), at: 2)
            try insert.bind(select.string(at: 2), at: 3)
            try insert.bind(select.string(at: 3), at: 4)
            try insert.bind(select.string(at: 4), at: 5)
            try insert.bind(select.string(at: 5), at: 6)
            try insert.bind(select.int64(at: 6), at: 7)
            _ = try insert.step()
            try insert.reset()
        }
    }

    private func migrateIntegrationAttributes(
        from old: MPSQLiteConnection,
        to current: MPSQLiteConnection
    ) throws {
        let select = try old.prepare(MPDatabaseMigrationLogicPRIVATE.migrateIntegrationAttributesSelectSQL)
        let insert = try current.prepare(MPDatabaseMigrationLogicPRIVATE.migrateIntegrationAttributesInsertSQL)
        while try select.step() == .row {
            try insert.bind(select.int64(at: 0), at: 1)
            try insert.bind(select.int(at: 1), at: 2)
            try insert.bind(select.data(at: 2), at: 3)
            _ = try insert.step()
            try insert.reset()
        }
    }

    private func bindNullableInt64(
        from source: MPSQLiteStatement,
        column: Int32,
        to destination: MPSQLiteStatement,
        index: Int32
    ) throws {
        if source.isNull(at: column) || source.int64(at: column) == 0 {
            try destination.bindNull(at: index)
        } else {
            try destination.bind(source.int64(at: column), at: index)
        }
    }
}
