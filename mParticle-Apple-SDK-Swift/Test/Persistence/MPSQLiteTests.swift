import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPSQLiteTests: XCTestCase {
    func testBindsAndReadsSupportedValues() throws {
        let database = try MPSQLiteConnection(path: ":memory:")
        try database.execute(
            "CREATE TABLE values_table (int_value INTEGER, int64_value INTEGER, "
                + "double_value REAL, text_value TEXT, blob_value BLOB, null_value TEXT)"
        )

        let dictionary = ["name": "mParticle", "count": 2] as [String: Any]
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let insert = try database.prepare(
            "INSERT INTO values_table VALUES (?, ?, ?, ?, ?, ?)"
        )
        try insert.bind(Int32(7), at: 1)
        try insert.bind(Int64.max, at: 2)
        try insert.bind(3.5, at: 3)
        try insert.bind("text", at: 4)
        try insert.bind(data, at: 5)
        try insert.bindNull(at: 6)
        XCTAssertEqual(try insert.step(), .done)

        let select = try database.prepare("SELECT * FROM values_table")
        XCTAssertEqual(try select.step(), .row)
        XCTAssertEqual(select.int(at: 0), 7)
        XCTAssertEqual(select.int64(at: 1), Int64.max)
        XCTAssertEqual(select.double(at: 2), 3.5)
        XCTAssertEqual(select.string(at: 3), "text")
        XCTAssertEqual(select.data(at: 4), data)
        XCTAssertEqual(select.jsonDictionary(at: 4)?["name"] as? String, "mParticle")
        XCTAssertTrue(select.isNull(at: 5))
        XCTAssertNil(select.string(at: 5))
        XCTAssertNil(select.data(at: 5))
    }

    func testResetClearsBindingsForStatementReuse() throws {
        let database = try MPSQLiteConnection(path: ":memory:")
        try database.execute("CREATE TABLE strings (value TEXT)")
        let insert = try database.prepare("INSERT INTO strings VALUES (?)")

        try insert.bind("first", at: 1)
        XCTAssertEqual(try insert.step(), .done)
        try insert.reset()
        try insert.bind("second", at: 1)
        XCTAssertEqual(try insert.step(), .done)

        let count = try database.prepare("SELECT COUNT(*) FROM strings")
        XCTAssertEqual(try count.step(), .row)
        XCTAssertEqual(count.int(at: 0), 2)
    }

    func testEmptyBlobIsDistinctFromNull() throws {
        let database = try MPSQLiteConnection(path: ":memory:")
        try database.execute("CREATE TABLE blobs (value BLOB)")
        let insert = try database.prepare("INSERT INTO blobs VALUES (?), (?)")
        try insert.bind(Data(), at: 1)
        try insert.bind(nil as Data?, at: 2)
        XCTAssertEqual(try insert.step(), .done)

        let select = try database.prepare("SELECT value FROM blobs ORDER BY rowid")
        XCTAssertEqual(try select.step(), .row)
        XCTAssertFalse(select.isNull(at: 0))
        XCTAssertEqual(select.data(at: 0), Data())
        XCTAssertEqual(try select.step(), .row)
        XCTAssertTrue(select.isNull(at: 0))
        XCTAssertNil(select.data(at: 0))
    }

    func testCloseRetainsBusyConnectionUntilStatementsFinalize() throws {
        let database = try MPSQLiteConnection(path: ":memory:")
        var statement: MPSQLiteStatement? = try database.prepare("SELECT 1")

        XCTAssertFalse(database.close())
        XCTAssertNotNil(database.handle)

        statement = nil
        XCTAssertTrue(database.close())
        XCTAssertNil(database.handle)
    }

    func testTransactionCommitsSuccessfulWork() throws {
        let database = try MPSQLiteConnection(path: ":memory:")
        try database.execute("CREATE TABLE records (value INTEGER)")

        try database.transaction {
            try database.execute("INSERT INTO records VALUES (1)")
            try database.execute("INSERT INTO records VALUES (2)")
        }

        let count = try database.prepare("SELECT COUNT(*) FROM records")
        XCTAssertEqual(try count.step(), .row)
        XCTAssertEqual(count.int(at: 0), 2)
    }

    func testTransactionRollsBackFailedWork() throws {
        let database = try MPSQLiteConnection(path: ":memory:")
        try database.execute("CREATE TABLE records (value INTEGER UNIQUE)")

        XCTAssertThrowsError(try database.transaction {
            try database.execute("INSERT INTO records VALUES (1)")
            try database.execute("INSERT INTO records VALUES (1)")
        })

        let count = try database.prepare("SELECT COUNT(*) FROM records")
        XCTAssertEqual(try count.step(), .row)
        XCTAssertEqual(count.int(at: 0), 0)
    }

    func testIntegrityCheckAndMemoryRelease() throws {
        let database = try MPSQLiteConnection(path: ":memory:")

        XCTAssertTrue(try database.integrityCheck())
        database.releaseMemory()
    }

    func testErrorsIncludeSQLAndAreLogged() throws {
        let logger = MPLog(logLevel: .error)
        var messages: [String] = []
        logger.customLogger = { messages.append($0) }
        let database = try MPSQLiteConnection(path: ":memory:", logger: logger)

        XCTAssertThrowsError(try database.execute("NOT VALID SQL")) { error in
            let sqliteError = error as? MPSQLiteError
            XCTAssertEqual(sqliteError?.sql, "NOT VALID SQL")
            XCTAssertNotEqual(sqliteError?.code, 0)
        }
        XCTAssertTrue(messages.contains { $0.contains("NOT VALID SQL") })
    }
}
