import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendSessionAttributeWriterTests: XCTestCase {
    private var fixture = MPBackendSessionFixture()
    private var host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
    private var writer: MPBackendSessionAttributeWriter!
    private var session: MPSessionPRIVATE!

    override func setUp() {
        super.setUp()
        fixture = MPBackendSessionFixture()
        host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
        session = fixture.session()
        writer = MPBackendSessionAttributeWriter(dependencies: fixture.dependencies, host: host)
    }

    private var updates: Int { fixture.persistence.calls.filter { $0 == "updateSession" }.count }

    func testSettingAnAttributeStoresItUnderTheExistingKeyAndSavesTheSession() {
        XCTAssertEqual(writer.setAttribute(session, key: "Plan", value: "basic"), .success)
        XCTAssertEqual(writer.setAttribute(session, key: "plan", value: "premium"), .success)

        XCTAssertEqual(session.attributesDictionary as? [String: String], ["Plan": "premium"])
        XCTAssertEqual(updates, 2)
    }

    func testSettingTheStoredValueAgainIsRejected() {
        _ = writer.setAttribute(session, key: "Plan", value: "basic")

        XCTAssertEqual(writer.setAttribute(session, key: "Plan", value: "basic"), .invalidDataType)
        XCTAssertEqual(updates, 1)
    }

    func testUnusableKeysAndValuesAreRejectedWithoutSaving() {
        XCTAssertEqual(writer.setAttribute(nil, key: "Plan", value: "basic"), .missingParam)
        XCTAssertEqual(writer.setAttribute(session, key: NSNumber(value: 1), value: "basic"), .invalidDataType)
        XCTAssertEqual(writer.setAttribute(session, key: NSNull(), value: "basic"), .invalidDataType)
        XCTAssertEqual(writer.setAttribute(session, key: "Plan", value: ["a"]), .invalidDataType)
        XCTAssertEqual(writer.setAttribute(session, key: "Plan", value: nil), .invalidDataType)
        host.valueLengthLimit = 3
        XCTAssertEqual(writer.setAttribute(session, key: "Plan", value: "premium"), .invalidDataType)

        XCTAssertEqual(session.attributesDictionary.count, 0)
        XCTAssertEqual(updates, 0)
    }

    func testIncrementingAnAbsentAttributeSetsIt() {
        XCTAssertEqual(writer.incrementAttribute(session, key: "Visits", byValue: NSNumber(value: 2)), 2)

        XCTAssertEqual(session.attributesDictionary["Visits"] as? NSNumber, 2)
        XCTAssertEqual(updates, 1)
    }

    func testIncrementingAStoredNumberSavesTheSessionOnTheMessageQueue() {
        _ = writer.setAttribute(session, key: "Visits", value: NSNumber(value: 2))

        XCTAssertEqual(writer.incrementAttribute(session, key: "visits", byValue: NSNumber(value: 3)), 5)
        XCTAssertEqual(session.attributesDictionary["Visits"] as? NSNumber, 5)
        XCTAssertEqual(updates, 1, "the increment is saved asynchronously")

        fixture.drainMessageQueue()
        XCTAssertEqual(updates, 2)
    }

    func testIncrementingReturnsNilForAnythingButTwoNumbers() {
        _ = writer.setAttribute(session, key: "Plan", value: "basic")
        _ = writer.setAttribute(session, key: "Visits", value: NSNumber(value: 2))

        XCTAssertNil(writer.incrementAttribute(nil, key: "Visits", byValue: NSNumber(value: 1)))
        XCTAssertNil(writer.incrementAttribute(session, key: NSNumber(value: 1), byValue: NSNumber(value: 1)))
        XCTAssertNil(writer.incrementAttribute(session, key: "Plan", byValue: NSNumber(value: 1)))
        XCTAssertNil(writer.incrementAttribute(session, key: "Visits", byValue: "1"))
        XCTAssertNil(writer.incrementAttribute(session, key: "Absent", byValue: "1"))

        XCTAssertEqual(session.attributesDictionary["Visits"] as? NSNumber, 2)
        fixture.drainMessageQueue()
        XCTAssertEqual(updates, 2)
    }
}
