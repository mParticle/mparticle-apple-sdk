import Foundation
import SQLite3

@objc public protocol MPUploadSettingsCoding: AnyObject {
    func archiveUploadSettings(_ settings: NSObject) -> Data?
    func unarchiveUploadSettings(_ data: Data) -> NSObject?
}

protocol MPUploadPersistingStore {
    func saveUpload(_ upload: MPUploadPRIVATE, optedOut: Bool) throws -> Bool
    func fetchUploads() throws -> [MPUploadPRIVATE]
    func deleteUpload(_ upload: MPUploadPRIVATE) throws
    func saveUploads(
        _ uploads: [MPUploadPRIVATE],
        deleting messages: [MPMessagePRIVATE],
        optedOut: Bool
    ) throws -> Bool
}

extension MPPersistenceStorePRIVATE: MPUploadPersistingStore {
    func saveUpload(_ upload: MPUploadPRIVATE, optedOut: Bool = false) throws -> Bool {
        if shouldSuppress(upload, optedOut: optedOut) {
            return true
        }
        guard let uuid = upload.uuid,
              let settingsData = encodeUploadSettings(upload.uploadSettings)
        else {
            return false
        }

        let statement = try requireConnection().prepare(
            "INSERT INTO uploads "
                + "(uuid, message_data, timestamp, session_id, upload_type, data_plan_id, "
                + "data_plan_version, upload_settings) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        )
        try statement.bind(uuid, at: 1)
        try statement.bind(upload.uploadData, at: 2)
        try statement.bind(upload.timestamp, at: 3)
        try bindUploadSessionId(upload.sessionId, to: statement, at: 4)
        try statement.bind(Int64(upload.uploadType), at: 5)
        if let dataPlanId = upload.dataPlanId, dataPlanId != "0" {
            try statement.bind(dataPlanId, at: 6)
            if let version = upload.dataPlanVersion, version.intValue != 0 {
                try statement.bind(version.int64Value, at: 7)
            } else {
                try statement.bindNull(at: 7)
            }
        } else {
            try statement.bindNull(at: 6)
            try statement.bindNull(at: 7)
        }
        try statement.bind(settingsData, at: 8)
        guard try statement.step() == .done else {
            return false
        }
        upload.uploadId = sqlite3_last_insert_rowid(try requireConnection().handle)
        return true
    }

    func fetchUploads() throws -> [MPUploadPRIVATE] {
        let statement = try requireConnection().prepare(
            "SELECT _id, uuid, message_data, timestamp, session_id, upload_type, data_plan_id, "
                + "data_plan_version, upload_settings FROM uploads ORDER BY timestamp, _id LIMIT 100"
        )
        var uploads: [MPUploadPRIVATE] = []
        while try statement.step() == .row {
            guard let uuid = statement.string(at: 1),
                  let uploadData = statement.data(at: 2),
                  let settingsData = statement.data(at: 8),
                  let settings = decodeUploadSettings(settingsData)
            else {
                continue
            }
            uploads.append(MPUploadPRIVATE(
                sessionId: statement.isNull(at: 4) ? nil : NSNumber(value: statement.int64(at: 4)),
                uploadId: statement.int64(at: 0),
                uuid: uuid,
                uploadData: uploadData,
                timestamp: statement.double(at: 3),
                uploadType: UInt(statement.int64(at: 5)),
                dataPlanId: statement.string(at: 6),
                dataPlanVersion: statement.isNull(at: 7)
                    ? nil
                    : NSNumber(value: statement.int64(at: 7)),
                uploadSettings: settings
            ))
        }
        return uploads
    }

    func deleteUpload(_ upload: MPUploadPRIVATE) throws {
        try deleteUpload(id: upload.uploadId)
    }

    func deleteUpload(id: Int64) throws {
        let statement = try requireConnection().prepare("DELETE FROM uploads WHERE _id = ?")
        try statement.bind(id, at: 1)
        _ = try statement.step()
    }

    func saveUploads(
        _ uploads: [MPUploadPRIVATE],
        deleting messages: [MPMessagePRIVATE],
        optedOut: Bool = false
    ) throws -> Bool {
        let connection = try requireConnection()
        do {
            try connection.transaction {
                for upload in uploads {
                    guard try saveUpload(upload, optedOut: optedOut) else {
                        throw MPPersistenceStoreError.uploadSettingsEncodingFailed
                    }
                }
                try deleteMessages(messages)
            }
            return true
        } catch {
            return false
        }
    }

    private func bindUploadSessionId(
        _ number: NSNumber?,
        to statement: MPSQLiteStatement,
        at index: Int32
    ) throws {
        if let number {
            try statement.bind(number.int64Value, at: index)
        } else {
            try statement.bindNull(at: index)
        }
    }
}

private enum MPPersistenceStoreError: Error {
    case uploadSettingsEncodingFailed
}
