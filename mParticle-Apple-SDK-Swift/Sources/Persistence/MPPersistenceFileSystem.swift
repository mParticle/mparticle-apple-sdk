import Foundation

@objc public final class MPPersistenceFileSystemPRIVATE: NSObject {
    private let fileManager: FileManager
    private let logger: MPLog
    private let applicationSupportDirectory: String?
    private let cachesDirectory: String?
    private let documentsDirectory: String?
    private let shouldExcludeDirectoryFromBackup: Bool

    @objc public convenience init(logger: MPLog) {
        self.init(
            fileManager: .default,
            logger: logger,
            applicationSupportDirectory: NSSearchPathForDirectoriesInDomains(
                .applicationSupportDirectory,
                .userDomainMask,
                true
            ).first,
            cachesDirectory: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first,
            documentsDirectory: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            shouldExcludeDirectoryFromBackup: true
        )
    }

    init(
        fileManager: FileManager,
        logger: MPLog,
        applicationSupportDirectory: String?,
        cachesDirectory: String?,
        documentsDirectory: String?,
        shouldExcludeDirectoryFromBackup: Bool
    ) {
        self.fileManager = fileManager
        self.logger = logger
        self.applicationSupportDirectory = applicationSupportDirectory
        self.cachesDirectory = cachesDirectory
        self.documentsDirectory = documentsDirectory
        self.shouldExcludeDirectoryFromBackup = shouldExcludeDirectoryFromBackup
        super.init()
    }

    @objc public func databaseDirectoryPath() -> String {
        let directory = MPPersistenceSchemaPRIVATE.databaseDirectory(
            applicationSupport: applicationSupportDirectory,
            cachesDirectory: cachesDirectory
        )
        guard !directory.isEmpty else { return directory }

        if !fileManager.fileExists(atPath: directory) {
            do {
                try fileManager.createDirectory(
                    atPath: directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                logger.error("Failed to create database directory: \(directory) - \(error)")
            }
        }

        #if !os(tvOS)
            if shouldExcludeDirectoryFromBackup {
                excludeDirectoryFromBackup(atPath: directory)
            }
        #endif

        return directory
    }

    @objc public func resolvedDatabasePath(databaseName: String) -> String {
        MPPersistenceSchemaPRIVATE.resolvedDatabasePath(
            preferredDirectory: databaseDirectoryPath(),
            databaseName: databaseName,
            legacyDirectory: legacyDocumentsDirectory
        )
    }

    @objc public func existingPath(forDatabaseName databaseName: String) -> String? {
        MPPersistenceSchemaPRIVATE.existingPath(
            forDatabaseName: databaseName,
            preferredDirectory: databaseDirectoryPath(),
            legacyDirectory: legacyDocumentsDirectory
        )
    }

    @objc public func versionNeedingMigration(from databaseVersions: NSArray) -> NSNumber? {
        MPPersistenceSchemaPRIVATE.versionNeedingMigration(
            from: databaseVersions,
            preferredDirectory: databaseDirectoryPath(),
            legacyDirectory: legacyDocumentsDirectory
        )
    }

    @objc public func migrateLegacyDatabaseDirectoryIfNeeded() {
        #if os(iOS)
            guard let legacyDirectory = legacyDocumentsDirectory else { return }
            let currentDirectory = databaseDirectoryPath()
            guard legacyDirectory != currentDirectory else { return }

            let suffixes = MPPersistenceSchemaPRIVATE.sidecarSuffixes as? [String] ?? []
            for version in MPPersistenceSchemaPRIVATE.databaseVersions {
                guard let version = version as? NSNumber else { continue }
                let databaseName = MPPersistenceSchemaPRIVATE.databaseName(for: version)
                let legacyDatabasePath = path(databaseName, in: legacyDirectory)
                let currentDatabasePath = path(databaseName, in: currentDirectory)
                let action = MPPersistenceSchemaPRIVATE.legacyFileAction(
                    currentMainExists: fileManager.fileExists(atPath: currentDatabasePath),
                    legacyMainExists: fileManager.fileExists(atPath: legacyDatabasePath)
                )

                switch action {
                case .removeLegacyMainAndSidecars:
                    removeItemIfExists(atPath: legacyDatabasePath)
                    suffixes.forEach { removeItemIfExists(atPath: legacyDatabasePath + $0) }
                case .removeOrphanSidecars:
                    suffixes.forEach { removeItemIfExists(atPath: legacyDatabasePath + $0) }
                case .migrateMainThenSidecars:
                    guard moveOrCopyItem(fromPath: legacyDatabasePath, toPath: currentDatabasePath) else {
                        logger.error(
                            "Failed to migrate database from Documents to Application Support: \(legacyDatabasePath)"
                        )
                        continue
                    }
                    migrateSidecars(
                        suffixes,
                        fromDatabasePath: legacyDatabasePath,
                        toDatabasePath: currentDatabasePath
                    )
                case .none:
                    continue
                @unknown default:
                    continue
                }
            }
        #endif
    }

    @objc public func removeLegacySessionNumberFileIfNeeded() {
        #if os(iOS)
            guard let documentsDirectory = legacyDocumentsDirectory else { return }
            let sessionNumberPath = path(MPPersistenceSchemaPRIVATE.sessionNumberFileName, in: documentsDirectory)
            guard fileManager.fileExists(atPath: sessionNumberPath) else { return }
            do {
                try fileManager.removeItem(atPath: sessionNumberPath)
            } catch {
                logger.error("Failed to remove legacy SessionNumber file: \(error)")
            }
        #endif
    }

    @objc public func excludeDatabaseFromBackup(atPath path: String) {
        guard !path.isEmpty, fileManager.fileExists(atPath: path) else { return }
        do {
            var url = URL(fileURLWithPath: path)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        } catch {
            logger.error("Failed to exclude mParticle database from backup: \(error)")
        }
    }

    @discardableResult
    @objc public func removeDatabaseFileIfExists(atPath path: String) -> Bool {
        guard fileManager.fileExists(atPath: path) else { return false }
        try? fileManager.removeItem(atPath: path)
        return true
    }

    @discardableResult
    @objc public func moveOrCopyItem(fromPath sourcePath: String, toPath destinationPath: String) -> Bool {
        do {
            try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
            return true
        } catch {
            do {
                try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath)
                try? fileManager.removeItem(atPath: sourcePath)
                return true
            } catch {
                return false
            }
        }
    }

    @objc public func removeItemIfExists(atPath path: String) {
        guard fileManager.fileExists(atPath: path) else { return }
        try? fileManager.removeItem(atPath: path)
    }

    private var legacyDocumentsDirectory: String? {
        #if os(iOS)
            return documentsDirectory
        #else
            return nil
        #endif
    }

    private func migrateSidecars(
        _ suffixes: [String],
        fromDatabasePath legacyDatabasePath: String,
        toDatabasePath currentDatabasePath: String
    ) {
        for suffix in suffixes {
            let legacyPath = legacyDatabasePath + suffix
            let currentPath = currentDatabasePath + suffix
            let action = MPPersistenceSchemaPRIVATE.sidecarAction(
                legacyExists: fileManager.fileExists(atPath: legacyPath),
                currentExists: fileManager.fileExists(atPath: currentPath)
            )

            switch action {
            case .skip:
                continue
            case .removeLegacy:
                removeItemIfExists(atPath: legacyPath)
            case .migrate:
                if !moveOrCopyItem(fromPath: legacyPath, toPath: currentPath) {
                    removeItemIfExists(atPath: legacyPath)
                }
            @unknown default:
                continue
            }
        }
    }

    private func excludeDirectoryFromBackup(atPath path: String) {
        do {
            var url = URL(fileURLWithPath: path, isDirectory: true)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        } catch {
            logger.error("Failed to exclude database directory from backup: \(error)")
        }
    }

    private func path(_ component: String, in directory: String) -> String {
        (directory as NSString).appendingPathComponent(component)
    }
}
