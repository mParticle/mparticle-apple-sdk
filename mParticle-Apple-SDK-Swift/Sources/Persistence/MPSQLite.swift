import Foundation
import SQLite3

struct MPSQLiteError: Error, Equatable, CustomStringConvertible {
    let code: Int32
    let message: String
    let sql: String?

    var description: String {
        if let sql {
            return "SQLite error \(code): \(message) [\(sql)]"
        }
        return "SQLite error \(code): \(message)"
    }
}

enum MPSQLiteStep: Equatable {
    case row
    case done
}

final class MPSQLiteConnection {
    static let defaultOpenFlags = SQLITE_OPEN_CREATE
        | SQLITE_OPEN_READWRITE
        | SQLITE_OPEN_FULLMUTEX
        | SQLITE_OPEN_FILEPROTECTION_NONE

    private(set) var handle: OpaquePointer?
    private let logger: MPLog?

    init(path: String, flags: Int32 = defaultOpenFlags, logger: MPLog? = nil) throws {
        self.logger = logger

        var database: OpaquePointer?
        let result = sqlite3_open_v2(path, &database, flags, nil)
        guard result == SQLITE_OK, let database else {
            let error = Self.error(code: result, database: database, sql: nil)
            if let database {
                sqlite3_close(database)
            }
            logger?.error(error.description)
            throw error
        }
        handle = database
    }

    deinit {
        close()
    }

    @discardableResult
    func close() -> Bool {
        guard let handle else {
            return true
        }
        guard sqlite3_close(handle) == SQLITE_OK else {
            return false
        }
        self.handle = nil
        return true
    }

    func execute(_ sql: String) throws {
        guard let handle else {
            throw loggedError(code: SQLITE_MISUSE, sql: sql)
        }

        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(handle, sql, nil, nil, &errorMessage)
        guard result == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) }
            sqlite3_free(errorMessage)
            throw loggedError(code: result, sql: sql, message: message)
        }
    }

    func prepare(_ sql: String) throws -> MPSQLiteStatement {
        guard let handle else {
            throw loggedError(code: SQLITE_MISUSE, sql: sql)
        }

        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(handle, sql, -1, &statement, nil)
        guard result == SQLITE_OK, let statement else {
            throw loggedError(code: result, sql: sql)
        }
        return MPSQLiteStatement(connection: self, handle: statement, sql: sql)
    }

    func transaction<T>(_ body: () throws -> T) throws -> T {
        try execute("BEGIN TRANSACTION")
        do {
            let value = try body()
            try execute("COMMIT")
            return value
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    func integrityCheck() throws -> Bool {
        let statement = try prepare("PRAGMA integrity_check")
        guard try statement.step() == .row else {
            return false
        }
        return statement.string(at: 0) == "ok"
    }

    func releaseMemory() {
        guard let handle else {
            return
        }
        sqlite3_db_release_memory(handle)
    }

    fileprivate func loggedError(code: Int32, sql: String, message: String? = nil) -> MPSQLiteError {
        let error = Self.error(code: code, database: handle, sql: sql, message: message)
        logger?.error(error.description)
        return error
    }

    private static func error(
        code: Int32,
        database: OpaquePointer?,
        sql: String?,
        message: String? = nil
    ) -> MPSQLiteError {
        let databaseMessage = database.map { String(cString: sqlite3_errmsg($0)) }
        return MPSQLiteError(
            code: code,
            message: message ?? databaseMessage ?? "Unknown SQLite error",
            sql: sql
        )
    }
}

final class MPSQLiteStatement {
    private let connection: MPSQLiteConnection
    private var handle: OpaquePointer?
    let sql: String

    fileprivate init(connection: MPSQLiteConnection, handle: OpaquePointer, sql: String) {
        self.connection = connection
        self.handle = handle
        self.sql = sql
    }

    deinit {
        if let handle {
            sqlite3_finalize(handle)
        }
    }

    func reset() throws {
        guard let handle else {
            throw connection.loggedError(code: SQLITE_MISUSE, sql: sql)
        }
        let result = sqlite3_reset(handle)
        guard result == SQLITE_OK else {
            throw connection.loggedError(code: result, sql: sql)
        }
        sqlite3_clear_bindings(handle)
    }

    func bindNull(at index: Int32) throws {
        try checkBind(sqlite3_bind_null(requiredHandle(), index))
    }

    func bind(_ value: Int32, at index: Int32) throws {
        try checkBind(sqlite3_bind_int(requiredHandle(), index, value))
    }

    func bind(_ value: Int64, at index: Int32) throws {
        try checkBind(sqlite3_bind_int64(requiredHandle(), index, value))
    }

    func bind(_ value: Double, at index: Int32) throws {
        try checkBind(sqlite3_bind_double(requiredHandle(), index, value))
    }

    func bind(_ value: String?, at index: Int32) throws {
        guard let value else {
            try bindNull(at: index)
            return
        }
        try checkBind(sqlite3_bind_text(requiredHandle(), index, value, -1, Self.transient))
    }

    func bind(_ value: Data?, at index: Int32) throws {
        guard let value else {
            try bindNull(at: index)
            return
        }
        if value.isEmpty {
            try checkBind(sqlite3_bind_zeroblob(requiredHandle(), index, 0))
            return
        }
        let result = value.withUnsafeBytes { bytes in
            sqlite3_bind_blob(requiredHandle(), index, bytes.baseAddress, Int32(bytes.count), Self.transient)
        }
        try checkBind(result)
    }

    func step() throws -> MPSQLiteStep {
        let result = sqlite3_step(requiredHandle())
        switch result {
        case SQLITE_ROW:
            return .row
        case SQLITE_DONE:
            return .done
        default:
            throw connection.loggedError(code: result, sql: sql)
        }
    }

    func isNull(at index: Int32) -> Bool {
        sqlite3_column_type(requiredHandle(), index) == SQLITE_NULL
    }

    func int(at index: Int32) -> Int32 {
        sqlite3_column_int(requiredHandle(), index)
    }

    func int64(at index: Int32) -> Int64 {
        sqlite3_column_int64(requiredHandle(), index)
    }

    func double(at index: Int32) -> Double {
        sqlite3_column_double(requiredHandle(), index)
    }

    func string(at index: Int32) -> String? {
        guard !isNull(at: index), let text = sqlite3_column_text(requiredHandle(), index) else {
            return nil
        }
        return String(cString: text)
    }

    func data(at index: Int32) -> Data? {
        guard !isNull(at: index) else {
            return nil
        }
        let count = Int(sqlite3_column_bytes(requiredHandle(), index))
        guard count > 0 else {
            return Data()
        }
        guard let bytes = sqlite3_column_blob(requiredHandle(), index) else {
            return nil
        }
        return Data(bytes: bytes, count: count)
    }

    func jsonDictionary(at index: Int32) -> [String: Any]? {
        guard let data = data(at: index) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private func requiredHandle() -> OpaquePointer {
        guard let handle else {
            preconditionFailure("Attempted to use a finalized SQLite statement")
        }
        return handle
    }

    private func checkBind(_ result: Int32) throws {
        guard result == SQLITE_OK else {
            throw connection.loggedError(code: result, sql: sql)
        }
    }

    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
}
