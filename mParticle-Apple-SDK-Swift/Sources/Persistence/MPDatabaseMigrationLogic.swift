import Foundation

@objc public final class MPDatabaseMigrationLogicPRIVATE: NSObject {
    @objc public static var deleteRecordsOlderThanStatements: NSArray {
        [
            "DELETE FROM messages WHERE timestamp < ?",
            "DELETE FROM uploads WHERE timestamp < ?",
            "DELETE FROM sessions WHERE end_time < ?"
        ]
    }

    @objc public static let migrateSessionsSelectSQL =
        "SELECT uuid, start_time, end_time, attributes_data, session_number, background_time, "
            + "number_interruptions, event_count, suspend_time, length, mpid, session_user_ids, "
            + "app_info, device_info FROM sessions ORDER BY _id"
    @objc public static let migrateSessionsInsertSQL =
        "INSERT INTO sessions (uuid, background_time, start_time, end_time, attributes_data, "
            + "session_number, number_interruptions, event_count, suspend_time, length, mpid, "
            + "session_user_ids, app_info, device_info) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

    @objc public static let migrateMessagesSelectSQL =
        "SELECT message_type, session_id, uuid, timestamp, message_data, upload_status, "
            + "data_plan_id, data_plan_version, mpid FROM messages ORDER BY _id"
    @objc public static let migrateMessagesInsertSQL =
        "INSERT INTO messages (message_type, session_id, uuid, timestamp, message_data, "
            + "upload_status, data_plan_id, data_plan_version, mpid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"

    @objc public static let migrateUploadsSelectSQL =
        "SELECT uuid, message_data, timestamp, session_id, upload_type, data_plan_id, "
            + "data_plan_version FROM uploads ORDER BY _id"
    @objc public static let migrateUploadsInsertSQL =
        "INSERT INTO uploads (uuid, message_data, timestamp, session_id, upload_type, "
            + "data_plan_id, data_plan_version, upload_settings) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"

    @objc public static let migrateForwardingRecordsSelectSQL =
        "SELECT _id, forwarding_data, mpid FROM forwarding_records"
    @objc public static let migrateForwardingRecordsInsertSQL =
        "INSERT INTO forwarding_records (_id, forwarding_data, mpid) VALUES (?, ?, ?)"

    @objc public static let migrateConsumerInfoSelectSQL =
        "SELECT _id, mpid, unique_identifier FROM consumer_info"
    @objc public static let migrateConsumerInfoInsertSQL =
        "INSERT INTO consumer_info (_id, mpid, unique_identifier) VALUES (?, ?, ?)"

    @objc public static let migrateCookiesSelectSQL =
        "SELECT _id, consumer_info_id, content, domain, expiration, name, mpid FROM cookies"
    @objc public static let migrateCookiesInsertSQL =
        "INSERT INTO cookies (_id, consumer_info_id, content, domain, expiration, name, mpid) "
            + "VALUES (?, ?, ?, ?, ?, ?, ?)"

    @objc public static let migrateIntegrationAttributesSelectSQL =
        "SELECT _id, kit_code, attributes_data FROM integration_attributes"
    @objc public static let migrateIntegrationAttributesInsertSQL =
        "INSERT INTO integration_attributes (_id, kit_code, attributes_data) VALUES (?, ?, ?)"
}
