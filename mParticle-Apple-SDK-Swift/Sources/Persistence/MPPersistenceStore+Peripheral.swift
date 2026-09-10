import Foundation
import SQLite3

struct MPPersistedCookie: Equatable {
    let id: Int64
    let consumerInfoId: Int64
    let content: String?
    let domain: String?
    let expiration: String?
    let name: String
    let mpid: Int64
}

struct MPPersistedConsumerInfo: Equatable {
    let id: Int64
    let mpid: Int64
    let uniqueIdentifier: String?
    let cookies: [MPPersistedCookie]
}

extension MPPersistenceStorePRIVATE {
    func saveForwardRecord(_ record: MPForwardRecordPRIVATE) throws {
        guard let data = record.dataRepresentation() else {
            return
        }
        let statement = try requireConnection().prepare(
            "INSERT INTO forwarding_records (forwarding_data, mpid) VALUES (?, ?)"
        )
        try statement.bind(data, at: 1)
        try statement.bind(record.mpid.int64Value, at: 2)
        _ = try statement.step()
        record.forwardRecordId = UInt64(sqlite3_last_insert_rowid(try requireConnection().handle))
    }

    func fetchForwardRecords() throws -> [MPForwardRecordPRIVATE] {
        let statement = try requireConnection().prepare(
            "SELECT _id, forwarding_data, mpid FROM forwarding_records ORDER BY _id"
        )
        var records: [MPForwardRecordPRIVATE] = []
        while try statement.step() == .row {
            guard let data = statement.data(at: 1),
                  let record = MPForwardRecordPRIVATE(
                      recordId: statement.int64(at: 0),
                      data: data,
                      mpid: NSNumber(value: statement.int64(at: 2))
                  )
            else {
                continue
            }
            records.append(record)
        }
        return records
    }

    func deleteForwardRecords(ids: [NSNumber]) throws {
        guard !ids.isEmpty else {
            return
        }
        let values = ids.map(\.int64Value).map(String.init).joined(separator: ",")
        try requireConnection().execute(
            "DELETE FROM forwarding_records WHERE _id IN (\(values))"
        )
    }

    func saveIntegrationAttributes(_ attributes: MPIntegrationAttributesPRIVATE) throws {
        try deleteIntegrationAttributes(for: attributes.integrationId)
        guard JSONSerialization.isValidJSONObject(attributes.attributes),
              let data = try? JSONSerialization.data(withJSONObject: attributes.attributes)
        else {
            return
        }
        let statement = try requireConnection().prepare(
            "INSERT INTO integration_attributes (kit_code, attributes_data) VALUES (?, ?)"
        )
        try statement.bind(attributes.integrationId.int32Value, at: 1)
        try statement.bind(data, at: 2)
        _ = try statement.step()
    }

    func fetchIntegrationAttributes() throws -> [MPIntegrationAttributesPRIVATE] {
        let statement = try requireConnection().prepare(
            "SELECT kit_code, attributes_data FROM integration_attributes"
        )
        var attributes: [MPIntegrationAttributesPRIVATE] = []
        while try statement.step() == .row {
            guard let data = statement.data(at: 1),
                  let value = MPIntegrationAttributesPRIVATE(
                      integrationId: NSNumber(value: statement.int(at: 0)),
                      attributesData: data
                  )
            else {
                continue
            }
            attributes.append(value)
        }
        return attributes
    }

    func fetchIntegrationAttributes(for integrationId: NSNumber) throws -> NSDictionary? {
        let statement = try requireConnection().prepare(
            "SELECT attributes_data FROM integration_attributes WHERE kit_code = ?"
        )
        try statement.bind(integrationId.int32Value, at: 1)
        guard try statement.step() == .row,
              let data = statement.data(at: 0),
              let value = MPIntegrationAttributesPRIVATE(
                  integrationId: integrationId,
                  attributesData: data
              )
        else {
            return nil
        }
        return value.attributes
    }

    func deleteIntegrationAttributes(for integrationId: NSNumber) throws {
        let statement = try requireConnection().prepare(
            "DELETE FROM integration_attributes WHERE kit_code = ?"
        )
        try statement.bind(integrationId.int32Value, at: 1)
        _ = try statement.step()
    }

    func deleteAllIntegrationAttributes() throws {
        try requireConnection().execute("DELETE FROM integration_attributes")
    }

    func saveConsumerInfo(
        mpid: NSNumber,
        uniqueIdentifier: String?,
        cookies: [MPPersistedCookie]
    ) throws -> Int64 {
        try saveConsumerInfoWithCookieIds(
            mpid: mpid,
            uniqueIdentifier: uniqueIdentifier,
            cookies: cookies
        ).consumerInfoId
    }

    func saveConsumerInfoWithCookieIds(
        mpid: NSNumber,
        uniqueIdentifier: String?,
        cookies: [MPPersistedCookie]
    ) throws -> (consumerInfoId: Int64, cookieIds: [Int64]) {
        let connection = try requireConnection()
        return try connection.transaction {
            let statement = try connection.prepare(
                "INSERT INTO consumer_info (mpid, unique_identifier) VALUES (?, ?)"
            )
            try statement.bind(mpid.int64Value, at: 1)
            try statement.bind(uniqueIdentifier, at: 2)
            _ = try statement.step()
            let consumerInfoId = sqlite3_last_insert_rowid(connection.handle)
            var cookieIds: [Int64] = []
            for cookie in cookies {
                cookieIds.append(
                    try saveCookie(cookie, consumerInfoId: consumerInfoId, mpid: mpid.int64Value)
                )
            }
            return (consumerInfoId, cookieIds)
        }
    }

    func fetchConsumerInfo(for mpid: NSNumber) throws -> MPPersistedConsumerInfo? {
        let connection = try requireConnection()
        let info = try connection.prepare(
            "SELECT _id, mpid, unique_identifier FROM consumer_info WHERE mpid = ? ORDER BY _id LIMIT 1"
        )
        try info.bind(mpid.int64Value, at: 1)
        guard try info.step() == .row else {
            return nil
        }
        return MPPersistedConsumerInfo(
            id: info.int64(at: 0),
            mpid: info.int64(at: 1),
            uniqueIdentifier: info.string(at: 2),
            cookies: try fetchCookies(for: mpid)
        )
    }

    func fetchCookies(for mpid: NSNumber) throws -> [MPPersistedCookie] {
        let statement = try requireConnection().prepare(
            "SELECT _id, consumer_info_id, content, domain, expiration, name, mpid "
                + "FROM cookies WHERE mpid = ? ORDER BY _id"
        )
        try statement.bind(mpid.int64Value, at: 1)
        var cookies: [MPPersistedCookie] = []
        while try statement.step() == .row {
            cookies.append(MPPersistedCookie(
                id: statement.int64(at: 0),
                consumerInfoId: statement.int64(at: 1),
                content: statement.string(at: 2),
                domain: statement.string(at: 3),
                expiration: statement.string(at: 4),
                name: statement.string(at: 5) ?? "",
                mpid: statement.int64(at: 6)
            ))
        }
        return cookies
    }

    func deleteCookie(id: Int64) throws {
        let statement = try requireConnection().prepare("DELETE FROM cookies WHERE _id = ?")
        try statement.bind(id, at: 1)
        _ = try statement.step()
    }

    func updateCookie(_ cookie: MPPersistedCookie) throws {
        let statement = try requireConnection().prepare(
            "UPDATE cookies SET content = ?, domain = ?, expiration = ? WHERE _id = ?"
        )
        try statement.bind(cookie.content, at: 1)
        try statement.bind(cookie.domain, at: 2)
        try statement.bind(cookie.expiration, at: 3)
        try statement.bind(cookie.id, at: 4)
        _ = try statement.step()
    }

    func saveCookie(_ cookie: MPPersistedCookie) throws -> Int64 {
        try saveCookie(cookie, consumerInfoId: cookie.consumerInfoId, mpid: cookie.mpid)
    }

    func deleteConsumerInfo() throws {
        let connection = try requireConnection()
        try connection.transaction {
            try connection.execute("DELETE FROM cookies")
            try connection.execute("DELETE FROM consumer_info")
        }
    }

    func moveDatabaseContentFromMpidZero(to mpid: NSNumber) throws {
        let connection = try requireConnection()
        try connection.transaction {
            for table in MPPersistenceSchemaPRIVATE.mpidKeyedTableNames {
                guard let table = table as? String else {
                    continue
                }
                let statement = try connection.prepare(
                    MPPersistenceSchemaPRIVATE.sqlUpdatingMpid(forTable: table)
                )
                try statement.bind(mpid.int64Value, at: 1)
                _ = try statement.step()
            }
        }
    }

    private func saveCookie(
        _ cookie: MPPersistedCookie,
        consumerInfoId: Int64,
        mpid: Int64
    ) throws -> Int64 {
        let statement = try requireConnection().prepare(
            "INSERT INTO cookies "
                + "(consumer_info_id, content, domain, expiration, name, mpid) "
                + "VALUES (?, ?, ?, ?, ?, ?)"
        )
        try statement.bind(consumerInfoId, at: 1)
        try statement.bind(cookie.content, at: 2)
        try statement.bind(cookie.domain, at: 3)
        try statement.bind(cookie.expiration, at: 4)
        try statement.bind(cookie.name, at: 5)
        try statement.bind(mpid, at: 6)
        _ = try statement.step()
        return sqlite3_last_insert_rowid(try requireConnection().handle)
    }
}

final class MPPersistenceUserDefaultsMigrator {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func moveContentFromMpidZero(to mpid: NSNumber) {
        let dictionary = userDefaults.dictionaryRepresentation()
        for (key, value) in dictionary where key.hasPrefix("mParticle::0") {
            guard let newKey = MPPersistenceSchemaPRIVATE.remappedUserDefaultsKey(key, mpid: mpid) else {
                continue
            }
            if dictionary[newKey] == nil {
                userDefaults.set(value, forKey: newKey)
            }
            userDefaults.removeObject(forKey: key)
        }
    }
}
