import Foundation
import SQLite3

protocol MPSessionPersisting {
    func saveSession(_ session: MPSessionPRIVATE) throws
    func updateSession(_ session: MPSessionPRIVATE) throws
    func fetchSessions() throws -> [MPSessionPRIVATE]
    func deleteSession(_ session: MPSessionPRIVATE) throws
}

protocol MPMessagePersisting {
    func saveMessage(_ message: MPMessagePRIVATE) throws
    func deleteMessages(_ messages: [MPMessagePRIVATE]) throws
    func fetchMessagesForUploading() throws -> MPPersistedMessageGroups
}

typealias MPPersistedMessageGroups =
    [NSNumber: [NSNumber: [String: [NSNumber: [MPMessagePRIVATE]]]]]

extension MPPersistenceStorePRIVATE: MPSessionPersisting, MPMessagePersisting {
    func saveSession(_ session: MPSessionPRIVATE) throws {
        let statement = try requireConnection().prepare(
            "INSERT INTO sessions "
                + "(uuid, start_time, end_time, background_time, attributes_data, session_number, "
                + "number_interruptions, event_count, suspend_time, length, mpid, session_user_ids, "
                + "app_info, device_info) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        )
        try statement.bind(session.uuid, at: 1)
        try statement.bind(session.startTime, at: 2)
        try statement.bind(session.endTime, at: 3)
        try statement.bind(session.backgroundTime, at: 4)
        try statement.bind(jsonData(session.attributesDictionary), at: 5)
        try statement.bind(Int64(0), at: 6)
        try statement.bind(Int32(session.numberOfInterruptions), at: 7)
        try statement.bind(Int32(session.eventCounter), at: 8)
        try statement.bind(session.suspendTime, at: 9)
        try statement.bind(session.length, at: 10)
        try statement.bind(session.userId.int64Value, at: 11)
        try statement.bind(session.sessionUserIds, at: 12)
        try statement.bind(jsonData(session.appInfo), at: 13)
        try statement.bind(jsonData(session.deviceInfo), at: 14)
        guard try statement.step() == .done else {
            return
        }
        session.sessionId = sqlite3_last_insert_rowid(try requireConnection().handle)
    }

    func updateSession(_ session: MPSessionPRIVATE) throws {
        let statement = try requireConnection().prepare(
            "UPDATE sessions SET end_time = ?, attributes_data = ?, background_time = ?, "
                + "number_interruptions = ?, event_count = ?, suspend_time = ?, length = ?, mpid = ?, "
                + "session_user_ids = ? WHERE _id = ?"
        )
        try statement.bind(session.endTime, at: 1)
        try statement.bind(jsonData(session.attributesDictionary), at: 2)
        try statement.bind(session.backgroundTime, at: 3)
        try statement.bind(Int32(session.numberOfInterruptions), at: 4)
        try statement.bind(Int32(session.eventCounter), at: 5)
        try statement.bind(session.suspendTime, at: 6)
        try statement.bind(session.length, at: 7)
        try statement.bind(session.userId.int64Value, at: 8)
        try statement.bind(session.sessionUserIds, at: 9)
        try statement.bind(session.sessionId, at: 10)
        _ = try statement.step()
    }

    func fetchSessions() throws -> [MPSessionPRIVATE] {
        let statement = try requireConnection().prepare(
            "SELECT _id, uuid, background_time, start_time, end_time, attributes_data, session_number, "
                + "number_interruptions, event_count, suspend_time, length, mpid, session_user_ids, "
                + "app_info, device_info FROM sessions ORDER BY _id"
        )
        var sessions: [MPSessionPRIVATE] = []
        while try statement.step() == .row {
            if let session = session(from: statement, includesApplicationInfo: true) {
                sessions.append(session)
            }
        }
        return sessions
    }

    func fetchPossibleSessionsFromCrash() throws -> [MPSessionPRIVATE] {
        let statement = try requireConnection().prepare(
            "SELECT _id, uuid, background_time, start_time, end_time, attributes_data, session_number, "
                + "number_interruptions, event_count, suspend_time, length, mpid, session_user_ids, "
                + "app_info, device_info FROM sessions WHERE mpid = ? AND _id IN "
                + "((SELECT MAX(_id) FROM sessions WHERE mpid = ?), "
                + "(SELECT (MAX(_id) - 1) FROM sessions WHERE mpid = ?)) ORDER BY session_number"
        )
        let mpid = currentMpid().int64Value
        try statement.bind(mpid, at: 1)
        try statement.bind(mpid, at: 2)
        try statement.bind(mpid, at: 3)
        var sessions: [MPSessionPRIVATE] = []
        while try statement.step() == .row {
            if let session = session(from: statement, includesApplicationInfo: true) {
                sessions.append(session)
            }
        }
        return sessions
    }

    func archiveSession(_ session: MPSessionPRIVATE) throws -> MPSessionPRIVATE? {
        if let previous = try fetchPreviousSession() {
            if previous.sessionId == session.sessionId, previous.uuid == session.uuid {
                return nil
            }
            try deletePreviousSession()
        }
        let statement = try requireConnection().prepare(
            "INSERT INTO previous_session "
                + "(session_id, uuid, start_time, end_time, background_time, attributes_data, "
                + "session_number, number_interruptions, event_count, suspend_time, length, mpid, "
                + "session_user_ids) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        )
        try statement.bind(session.sessionId, at: 1)
        try statement.bind(session.uuid, at: 2)
        try statement.bind(session.startTime, at: 3)
        try statement.bind(session.endTime, at: 4)
        try statement.bind(session.backgroundTime, at: 5)
        try statement.bind(jsonData(session.attributesDictionary), at: 6)
        try statement.bind(Int64(0), at: 7)
        try statement.bind(Int32(session.numberOfInterruptions), at: 8)
        try statement.bind(Int32(session.eventCounter), at: 9)
        try statement.bind(session.suspendTime, at: 10)
        try statement.bind(session.length, at: 11)
        try statement.bind(session.userId.int64Value, at: 12)
        try statement.bind(session.sessionUserIds, at: 13)
        _ = try statement.step()
        return session
    }

    func fetchPreviousSession() throws -> MPSessionPRIVATE? {
        let statement = try requireConnection().prepare(
            "SELECT session_id, uuid, background_time, start_time, end_time, attributes_data, "
                + "session_number, number_interruptions, event_count, suspend_time, length, mpid, "
                + "session_user_ids FROM previous_session WHERE mpid = ?"
        )
        try statement.bind(currentMpid().int64Value, at: 1)
        guard try statement.step() == .row else {
            return nil
        }
        return session(from: statement, includesApplicationInfo: false)
    }

    func deletePreviousSession() throws {
        try requireConnection().execute("DELETE FROM previous_session")
    }

    func deleteSession(_ session: MPSessionPRIVATE) throws {
        let connection = try requireConnection()
        try connection.transaction {
            let messages = try connection.prepare("DELETE FROM messages WHERE session_id = ?")
            try messages.bind(session.sessionId, at: 1)
            _ = try messages.step()
            let sessions = try connection.prepare("DELETE FROM sessions WHERE _id = ?")
            try sessions.bind(session.sessionId, at: 1)
            _ = try sessions.step()
        }
    }

    func deleteAllSessions(except session: MPSessionPRIVATE?) throws {
        guard let session else {
            try requireConnection().execute("DELETE FROM sessions")
            return
        }
        let statement = try requireConnection().prepare("DELETE FROM sessions WHERE _id != ?")
        try statement.bind(session.sessionId, at: 1)
        _ = try statement.step()
    }

    func appAndDeviceInfo(forSessionId sessionId: NSNumber) throws -> [String: NSDictionary] {
        let statement = try requireConnection().prepare(
            "SELECT app_info, device_info FROM sessions WHERE _id = ?"
        )
        try statement.bind(sessionId.int64Value, at: 1)
        guard try statement.step() == .row else {
            return [:]
        }
        var result: [String: NSDictionary] = [:]
        if let appInfo = statement.jsonDictionary(at: 0) {
            result["ai"] = appInfo as NSDictionary
        }
        if let deviceInfo = statement.jsonDictionary(at: 1) {
            result["di"] = deviceInfo as NSDictionary
        }
        return result
    }

    func saveMessage(_ message: MPMessagePRIVATE) throws {
        guard message.shouldUploadEvent,
              let messageType = message.messageType,
              let uuid = message.uuid,
              let messageData = message.messageData,
              messageData.count <= MPPersistenceSchemaPRIVATE.maxBytesPerEvent(for: messageType)
        else {
            return
        }
        let statement = try requireConnection().prepare(
            "INSERT INTO messages "
                + "(message_type, session_id, uuid, timestamp, message_data, upload_status, "
                + "data_plan_id, data_plan_version, mpid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        )
        try statement.bind(messageType, at: 1)
        try bind(message.sessionId, to: statement, at: 2)
        try statement.bind(uuid, at: 3)
        try statement.bind(message.timestamp, at: 4)
        try statement.bind(messageData, at: 5)
        try statement.bind(Int32(message.uploadStatus), at: 6)
        if let dataPlanId = message.dataPlanId, dataPlanId != "0" {
            try statement.bind(dataPlanId, at: 7)
            if let version = message.dataPlanVersion, version.intValue != 0 {
                try statement.bind(version.int64Value, at: 8)
            } else {
                try statement.bindNull(at: 8)
            }
        } else {
            try statement.bindNull(at: 7)
            try statement.bindNull(at: 8)
        }
        try statement.bind(message.userId.int64Value, at: 9)
        _ = try statement.step()
        message.messageId = sqlite3_last_insert_rowid(try requireConnection().handle)
    }

    func deleteMessages(_ messages: [MPMessagePRIVATE]) throws {
        guard !messages.isEmpty else {
            return
        }
        let ids = messages.map(\.messageId).map(String.init).joined(separator: ",")
        try requireConnection().execute("DELETE FROM messages WHERE _id IN (\(ids))")
    }

    func deleteNetworkPerformanceMessages() throws {
        let statement = try requireConnection().prepare(
            "DELETE FROM messages WHERE message_type = ?"
        )
        try statement.bind("npe", at: 1)
        _ = try statement.step()
    }

    func fetchMessagesForUploading() throws -> MPPersistedMessageGroups {
        let statement = try requireConnection().prepare(
            "SELECT _id, uuid, message_type, message_data, timestamp, upload_status, mpid, "
                + "session_id, data_plan_id, data_plan_version FROM messages WHERE mpid != 0 "
                + "AND (upload_status = 0 OR upload_status = 1) ORDER BY timestamp, _id"
        )
        var groups: MPPersistedMessageGroups = [:]
        while try statement.step() == .row {
            guard let message = message(from: statement, sessionIdColumn: 7) else {
                continue
            }
            let sessionId = message.sessionId ?? 0
            let dataPlanId = message.dataPlanId ?? "0"
            let dataPlanVersion = message.dataPlanVersion ?? 0
            var sessions = groups[message.userId] ?? [:]
            var dataPlans = sessions[sessionId] ?? [:]
            var versions = dataPlans[dataPlanId] ?? [:]
            versions[dataPlanVersion, default: []].append(message)
            dataPlans[dataPlanId] = versions
            sessions[sessionId] = dataPlans
            groups[message.userId] = sessions
        }
        return groups
    }

    func fetchSessionEndMessage(in session: MPSessionPRIVATE) throws -> MPMessagePRIVATE? {
        let statement = try requireConnection().prepare(
            "SELECT _id, uuid, message_type, message_data, timestamp, upload_status, mpid, "
                + "data_plan_id, data_plan_version FROM messages WHERE session_id = ? AND message_type = ?"
        )
        try statement.bind(session.sessionId, at: 1)
        try statement.bind("se", at: 2)
        guard try statement.step() == .row else {
            return nil
        }
        return message(from: statement, fixedSessionId: NSNumber(value: session.sessionId))
    }

    func fetchUploadedMessages(in session: MPSessionPRIVATE) throws -> [MPMessagePRIVATE] {
        let statement = try requireConnection().prepare(
            "SELECT _id, uuid, message_type, message_data, timestamp, upload_status, mpid, "
                + "data_plan_id, data_plan_version FROM messages WHERE session_id = ? "
                + "AND upload_status = 2 AND mpid = ? ORDER BY timestamp"
        )
        try statement.bind(session.sessionId, at: 1)
        try statement.bind(currentMpid().int64Value, at: 2)
        var messages: [MPMessagePRIVATE] = []
        while try statement.step() == .row {
            if let message = message(from: statement, fixedSessionId: NSNumber(value: session.sessionId)) {
                messages.append(message)
            }
        }
        return messages
    }

    func saveBreadcrumb(_ message: MPMessagePRIVATE) throws {
        guard let uuid = message.uuid, let data = message.messageData else {
            return
        }
        let connection = try requireConnection()
        let insert = try connection.prepare(
            "INSERT INTO breadcrumbs "
                + "(session_uuid, uuid, timestamp, breadcrumb_data, session_number, mpid) "
                + "VALUES (?, ?, ?, ?, ?, ?)"
        )
        try insert.bind("", at: 1)
        try insert.bind(uuid, at: 2)
        try insert.bind(message.timestamp, at: 3)
        try insert.bind(data, at: 4)
        try insert.bind(Int64(0), at: 5)
        try insert.bind(currentMpid().int64Value, at: 6)
        _ = try insert.step()

        let prune = try connection.prepare(
            "DELETE FROM breadcrumbs WHERE mpid = ? AND _id NOT IN "
                + "(SELECT _id FROM breadcrumbs WHERE mpid = ? ORDER BY _id DESC LIMIT ?)"
        )
        try prune.bind(currentMpid().int64Value, at: 1)
        try prune.bind(currentMpid().int64Value, at: 2)
        try prune.bind(Int32(MPPersistenceSchemaPRIVATE.maxBreadcrumbs), at: 3)
        _ = try prune.step()
    }

    func fetchBreadcrumbs() throws -> [MPBreadcrumbPRIVATE] {
        let statement = try requireConnection().prepare(
            "SELECT _id, session_uuid, uuid, breadcrumb_data, timestamp "
                + "FROM breadcrumbs WHERE mpid = ? ORDER BY _id"
        )
        try statement.bind(currentMpid().int64Value, at: 1)
        var breadcrumbs: [MPBreadcrumbPRIVATE] = []
        while try statement.step() == .row {
            breadcrumbs.append(MPBreadcrumbPRIVATE(
                sessionUUID: statement.string(at: 1),
                breadcrumbId: statement.int64(at: 0),
                uuid: statement.string(at: 2),
                breadcrumbData: statement.data(at: 3),
                timestamp: statement.double(at: 4)
            ))
        }
        return breadcrumbs
    }

    private func session(
        from statement: MPSQLiteStatement,
        includesApplicationInfo: Bool
    ) -> MPSessionPRIVATE? {
        guard let uuid = statement.string(at: 1) else {
            return nil
        }
        let session = MPSessionPRIVATE(
            sessionId: statement.int64(at: 0),
            uuid: uuid,
            backgroundTime: statement.double(at: 2),
            startTime: statement.double(at: 3),
            endTime: statement.double(at: 4),
            attributes: statement.jsonDictionary(at: 5).map(NSMutableDictionary.init(dictionary:)),
            numberOfInterruptions: UInt32(statement.int(at: 7)),
            eventCounter: UInt32(statement.int(at: 8)),
            suspendTime: statement.double(at: 9),
            userId: NSNumber(value: statement.int64(at: 11)),
            sessionUserIds: statement.string(at: 12) ?? "",
            applicationInfo: includesApplicationInfo ? statement.jsonDictionary(at: 13) as NSDictionary? : nil,
            deviceInfo: includesApplicationInfo ? statement.jsonDictionary(at: 14) as NSDictionary? : nil
        )
        session.length = statement.double(at: 10)
        return session
    }

    private func message(
        from statement: MPSQLiteStatement,
        sessionIdColumn: Int32? = nil,
        fixedSessionId: NSNumber? = nil
    ) -> MPMessagePRIVATE? {
        guard let uuid = statement.string(at: 1),
              let messageType = statement.string(at: 2),
              let messageData = statement.data(at: 3)
        else {
            return nil
        }
        let sessionId: NSNumber?
        if let fixedSessionId {
            sessionId = fixedSessionId
        } else if let sessionIdColumn, !statement.isNull(at: sessionIdColumn) {
            sessionId = NSNumber(value: statement.int64(at: sessionIdColumn))
        } else {
            sessionId = nil
        }
        let dataPlanVersionIndex: Int32 = sessionIdColumn == nil ? 8 : 9
        return MPMessagePRIVATE(
            sessionId: sessionId,
            messageId: statement.int64(at: 0),
            uuid: uuid,
            messageType: messageType,
            messageData: messageData,
            timestamp: statement.double(at: 4),
            uploadStatus: Int(statement.int(at: 5)),
            userId: NSNumber(value: statement.int64(at: 6)),
            dataPlanId: statement.string(at: sessionIdColumn == nil ? 7 : 8),
            dataPlanVersion: statement.isNull(at: dataPlanVersionIndex)
                ? nil
                : NSNumber(value: statement.int64(at: dataPlanVersionIndex))
        )
    }

    private func bind(_ number: NSNumber?, to statement: MPSQLiteStatement, at index: Int32) throws {
        if let number {
            try statement.bind(number.int64Value, at: index)
        } else {
            try statement.bindNull(at: index)
        }
    }

    private func jsonData(_ object: Any?) -> Data? {
        guard let object, JSONSerialization.isValidJSONObject(object) else {
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: object)
    }
}
