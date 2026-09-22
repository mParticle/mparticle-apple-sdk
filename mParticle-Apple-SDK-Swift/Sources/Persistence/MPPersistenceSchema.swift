import Foundation

@objc public enum MPPersistenceLegacyFileActionPRIVATE: Int {
    case none = 0
    case removeLegacyMainAndSidecars = 1
    case removeOrphanSidecars = 2
    case migrateMainThenSidecars = 3
}

@objc public enum MPPersistenceSidecarActionPRIVATE: Int {
    case skip = 0
    case removeLegacy = 1
    case migrate = 2
}

@objc public final class MPPersistenceSchemaPRIVATE: NSObject {
    @objc public static let crashMessageType = "x"
    @objc public static let sessionNumberFileName = "SessionNumber"
    @objc public static let maxBreadcrumbs: Int = 50
    @objc public static let sevenDays: TimeInterval = 60 * 60 * 24 * 7
    @objc public static let maxBytesPerEvent: Int = 100 * 1024
    @objc public static let maxBytesPerBatch: Int = 200 * 1024
    @objc public static let maxBytesPerEventCrash: Int = 1000 * 1024
    @objc public static let maxBytesPerBatchCrash: Int = 2000 * 1024

    @objc public static var databaseVersions: NSArray {
        [30, 31]
    }

    @objc public static var currentDatabaseVersion: NSNumber {
        databaseVersions.lastObject as? NSNumber ?? 31
    }

    @objc public static var sidecarSuffixes: NSArray {
        ["-journal", "-wal", "-shm"]
    }

    @objc public static var mpidKeyedTableNames: NSArray {
        ["sessions", "previous_session", "messages", "breadcrumbs", "cookies", "consumer_info"]
    }

    @objc public static var workspaceSwitchDeleteStatements: NSArray {
        [
            "DELETE FROM sessions",
            "DELETE FROM previous_session",
            "DELETE FROM messages",
            "DELETE FROM breadcrumbs",
            "DELETE FROM consumer_info",
            "DELETE FROM cookies",
            "DELETE FROM product_bags",
            "DELETE FROM forwarding_records",
            "DELETE FROM integration_attributes"
        ]
    }

    @objc public static var createTableStatements: NSArray {
        [
            """
            CREATE TABLE IF NOT EXISTS sessions ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                uuid TEXT NOT NULL, \
                start_time REAL, \
                end_time REAL, \
                background_time REAL, \
                attributes_data BLOB NOT NULL, \
                session_number INTEGER NOT NULL, \
                number_interruptions INTEGER, \
                event_count INTEGER, \
                suspend_time REAL, \
                length REAL, \
                mpid INTEGER NOT NULL, \
                session_user_ids TEXT NOT NULL, \
                app_info BLOB, \
                device_info BLOB \
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS previous_session ( \
                session_id INTEGER, \
                uuid TEXT, \
                start_time REAL, \
                end_time REAL, \
                background_time REAL, \
                attributes_data BLOB, \
                session_number INTEGER, \
                number_interruptions INTEGER, \
                event_count INTEGER, \
                suspend_time REAL, \
                length REAL, \
                mpid INTEGER NOT NULL, \
                session_user_ids TEXT NOT NULL \
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS messages ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                session_id INTEGER, \
                message_type TEXT NOT NULL, \
                uuid TEXT NOT NULL, \
                timestamp REAL NOT NULL, \
                message_data BLOB NOT NULL, \
                upload_status INTEGER, \
                data_plan_id TEXT, \
                data_plan_version INTEGER, \
                mpid INTEGER NOT NULL \
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS uploads ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                session_id INTEGER, \
                uuid TEXT NOT NULL, \
                message_data BLOB NOT NULL, \
                timestamp REAL NOT NULL, \
                upload_type INTEGER NOT NULL, \
                data_plan_id TEXT, \
                data_plan_version INTEGER, \
                upload_settings BLOB NOT NULL \
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS breadcrumbs ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                session_uuid TEXT NOT NULL, \
                uuid TEXT NOT NULL, \
                timestamp REAL NOT NULL, \
                breadcrumb_data BLOB NOT NULL, \
                session_number INTEGER NOT NULL, \
                mpid INTEGER NOT NULL \
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS consumer_info ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                mpid INTEGER, \
                unique_identifier TEXT \
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS cookies ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                consumer_info_id INTEGER NOT NULL, \
                content TEXT, \
                domain TEXT, \
                expiration TEXT, \
                name TEXT, \
                mpid INTEGER NOT NULL \
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS product_bags ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                name TEXT, \
                timestamp REAL NOT NULL, \
                product_data BLOB NOT NULL \
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS forwarding_records ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                forwarding_data BLOB NOT NULL, \
                mpid INTEGER NOT NULL \
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS integration_attributes ( \
                _id INTEGER PRIMARY KEY AUTOINCREMENT, \
                kit_code INTEGER NOT NULL, \
                attributes_data BLOB NOT NULL \
            )
            """
        ]
    }

    @objc(databaseNameForVersion:)
    public static func databaseName(for version: NSNumber) -> String {
        "mParticle\(version).db"
    }

    @objc(userVersionPragmaForVersion:)
    public static func userVersionPragma(for version: NSNumber) -> String {
        "PRAGMA user_version = \(version.intValue)"
    }

    @objc(maxBytesPerEventForMessageType:)
    public static func maxBytesPerEvent(for messageType: String?) -> Int {
        messageType == crashMessageType ? maxBytesPerEventCrash : maxBytesPerEvent
    }

    @objc(maxBytesPerBatchForMessageType:)
    public static func maxBytesPerBatch(for messageType: String?) -> Int {
        messageType == crashMessageType ? maxBytesPerBatchCrash : maxBytesPerBatch
    }

    @objc(databaseDirectoryWithApplicationSupport:cachesDirectory:)
    public static func databaseDirectory(applicationSupport: String?, cachesDirectory: String?) -> String {
        #if os(tvOS)
            return cachesDirectory ?? ""
        #else
            guard let applicationSupport, !applicationSupport.isEmpty else {
                return ""
            }
            return (applicationSupport as NSString).appendingPathComponent("mParticle")
        #endif
    }

    @objc(existingPathForDatabaseName:preferredDirectory:legacyDirectory:)
    public static func existingPath(forDatabaseName name: String, preferredDirectory: String,
                                    legacyDirectory: String?) -> String? {
        let fileManager = FileManager.default
        let preferredPath = (preferredDirectory as NSString).appendingPathComponent(name)
        if fileManager.fileExists(atPath: preferredPath) {
            return preferredPath
        }
        guard let legacyDirectory, !legacyDirectory.isEmpty else {
            return nil
        }
        let legacyPath = (legacyDirectory as NSString).appendingPathComponent(name)
        if fileManager.fileExists(atPath: legacyPath) {
            return legacyPath
        }
        return nil
    }

    @objc(resolvedDatabasePathWithPreferredDirectory:databaseName:legacyDirectory:)
    public static func resolvedDatabasePath(preferredDirectory: String, databaseName: String,
                                            legacyDirectory: String?) -> String {
        existingPath(forDatabaseName: databaseName, preferredDirectory: preferredDirectory, legacyDirectory: legacyDirectory)
            ?? (preferredDirectory as NSString).appendingPathComponent(databaseName)
    }

    @objc(versionNeedingMigrationFromVersions:preferredDirectory:legacyDirectory:)
    public static func versionNeedingMigration(
        from databaseVersions: NSArray,
        preferredDirectory: String,
        legacyDirectory: String?
    ) -> NSNumber? {
        guard let versions = databaseVersions as? [NSNumber], versions.count > 1 else {
            return nil
        }
        let version = versions[0]
        let name = databaseName(for: version)
        if existingPath(forDatabaseName: name, preferredDirectory: preferredDirectory, legacyDirectory: legacyDirectory) != nil {
            return version
        }
        return nil
    }

    @objc(legacyFileActionWithCurrentMainExists:legacyMainExists:)
    public static func legacyFileAction(currentMainExists: Bool, legacyMainExists: Bool) -> MPPersistenceLegacyFileActionPRIVATE {
        if currentMainExists {
            return .removeLegacyMainAndSidecars
        }
        if !legacyMainExists {
            return .removeOrphanSidecars
        }
        return .migrateMainThenSidecars
    }

    @objc(sidecarActionWithLegacyExists:currentExists:)
    public static func sidecarAction(legacyExists: Bool, currentExists: Bool) -> MPPersistenceSidecarActionPRIVATE {
        guard legacyExists else {
            return .skip
        }
        if currentExists {
            return .removeLegacy
        }
        return .migrate
    }

    @objc(commaSeparatedIds:)
    public static func commaSeparatedIds(_ ids: NSArray) -> String {
        (ids as [AnyObject]).map { $0.description }.joined(separator: ",")
    }

    @objc(deleteSQLForTable:ids:)
    public static func deleteSQL(table: String, ids: NSArray) -> String {
        "DELETE FROM \(table) WHERE _id IN (\(commaSeparatedIds(ids)))"
    }

    @objc(sqlUpdatingMpidForTable:)
    public static func sqlUpdatingMpid(forTable table: String) -> String {
        "UPDATE \(table) SET mpid = ? WHERE mpid = 0"
    }

    @objc(remappedUserDefaultsKey:mpid:)
    public static func remappedUserDefaultsKey(_ key: String, mpid: NSNumber) -> String? {
        guard key.hasPrefix("mParticle::0") else {
            return nil
        }
        return key.replacingOccurrences(of: "mParticle::0", with: "mParticle::\(mpid)")
    }

    @objc(insertCookieSQLWithContent:domain:expiration:name:mpid:)
    public static func insertCookieSQL(content: String?, domain: String?, expiration: String?, name: String,
                                       mpid: NSNumber) -> String {
        var fields: [String] = []
        var params: [String] = []
        if let content {
            fields.append("content")
            params.append("'\(content)'")
        }
        if let domain {
            fields.append("domain")
            params.append("'\(domain)'")
        }
        if let expiration {
            fields.append("expiration")
            params.append("'\(expiration)'")
        }
        fields.append("name")
        params.append("'\(name)'")
        fields.append("mpid")
        params.append("'\(mpid)'")

        var sql = "INSERT INTO cookies (consumer_info_id"
        for field in fields {
            sql += ", \(field)"
        }
        sql += ") VALUES (?"
        for param in params {
            sql += ", \(param)"
        }
        sql += ")"
        return sql
    }

    @objc(updateCookieSQLWithContent:domain:expiration:)
    public static func updateCookieSQL(content: String?, domain: String?, expiration: String?) -> String? {
        guard content != nil || domain != nil || expiration != nil else {
            return nil
        }
        var sql = "UPDATE cookies SET "
        if let content {
            sql += "content = '\(content)'"
        }
        if let domain {
            sql += ", domain = '\(domain)'"
        }
        if let expiration {
            sql += ", expiration = '\(expiration)'"
        }
        sql += " WHERE _id = ?"
        return sql
    }
}
