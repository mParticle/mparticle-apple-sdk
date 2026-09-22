import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPConsentRecordTests: XCTestCase {
    func testDefaultValues() {
        let record = MPConsentRecordPRIVATE()

        XCTAssertFalse(record.consented)
        XCTAssertNil(record.document)
        XCTAssertNil(record.location)
        XCTAssertNil(record.hardwareId)
        XCTAssertLessThan(-record.timestamp.timeIntervalSinceNow, 0.05)
    }

    func testPropertySetters() {
        let record = MPConsentRecordPRIVATE()
        let timestamp = Date()

        record.consented = true
        record.document = "foo-document-1"
        record.timestamp = timestamp
        record.location = "foo-location-1"
        record.hardwareId = "foo-hardware-id-1"

        XCTAssertTrue(record.consented)
        XCTAssertEqual(record.document, "foo-document-1")
        XCTAssertEqual(record.timestamp, timestamp)
        XCTAssertEqual(record.location, "foo-location-1")
        XCTAssertEqual(record.hardwareId, "foo-hardware-id-1")

        record.consented = false
        XCTAssertFalse(record.consented)
    }

    func testCopyRecordIsIndependent() {
        let record = MPConsentRecordPRIVATE()
        record.consented = true
        record.document = "original"
        record.location = "original-location"
        record.hardwareId = "original-hw"

        let copy = record.copyRecord()

        XCTAssertTrue(copy.consented)
        XCTAssertEqual(copy.document, "original")
        XCTAssertEqual(copy.timestamp, record.timestamp)
        XCTAssertEqual(copy.location, "original-location")
        XCTAssertEqual(copy.hardwareId, "original-hw")
        XCTAssertFalse(copy === record)

        copy.consented = false
        copy.document = "copied"
        XCTAssertTrue(record.consented)
        XCTAssertEqual(record.document, "original")
    }
}
