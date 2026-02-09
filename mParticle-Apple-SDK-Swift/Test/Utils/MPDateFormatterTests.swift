import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPDateFormatterTests: XCTestCase {
    private var referenceDate: Date!

    override func setUp() {
        super.setUp()
        var components = DateComponents()
        components.year = 1955
        components.month = 11
        components.day = 5
        components.hour = 1
        components.minute = 15
        components.timeZone = TimeZone(abbreviation: "PST")
        components.calendar = Calendar(identifier: .gregorian)
        referenceDate = components.date
    }

    func testDatesFromString() {
        var date = MPDateFormatter.date(from: "1955-11-5T01:15:00-8")
        XCTAssertNotNil(date)
        XCTAssertEqual(date, referenceDate)

        date = MPDateFormatter.date(from: "Sat, 5 Nov 1955 01:15:00 -8")
        XCTAssertNotNil(date)
        XCTAssertEqual(date, referenceDate)

        date = MPDateFormatter.date(from: "Saturday, 5-Nov-55 01:15:00 -8")
        XCTAssertNotNil(date)
        XCTAssertEqual(date, referenceDate)

        date = MPDateFormatter.date(fromStringRFC3339: "1955-11-5T01:15:00-8")
        XCTAssertNotNil(date)
        XCTAssertEqual(date, referenceDate)

        date = MPDateFormatter.date(fromStringRFC1123: "Sat, 5 Nov 1955 01:15:00 -8")
        XCTAssertNotNil(date)
        XCTAssertEqual(date, referenceDate)
    }

    func testStringFromDates() {
        let rfc1123 = MPDateFormatter.string(fromDateRFC1123: referenceDate)
        XCTAssertNotNil(rfc1123)
        XCTAssertEqual(rfc1123, "Sat, 05 Nov 1955 09:15:00 GMT")

        let rfc3339 = MPDateFormatter.string(fromDateRFC3339: referenceDate)
        XCTAssertNotNil(rfc3339)
        XCTAssertEqual(rfc3339, "1955-11-05T09:15:00+0000")
    }

    func testInvalidDatesFromString() {
        XCTAssertNil(MPDateFormatter.date(from: ""))
        XCTAssertNil(MPDateFormatter.date(fromStringRFC3339: ""))
        XCTAssertNil(MPDateFormatter.date(fromStringRFC1123: ""))
        XCTAssertNil(MPDateFormatter.date(from: "2016-02-30T23:61:00-5"))
        XCTAssertNil(MPDateFormatter.date(from: "The day the flux capacitor was invented."))
    }

    func testDateAnnotationMatchesMPLaunchInfo() {
        let url = URL(string: "http://mparticle.com")!
        let sourceApp = "testApp"
        let logger = MPLog(logLevel: .debug)

        let dates: [Date] = [
            Date(timeIntervalSince1970: 0),
            Date(timeIntervalSince1970: -446709900),
            Date(timeIntervalSince1970: 1893456000),
            Date(),
            Date(timeIntervalSince1970: 1234567890),
            Date(timeIntervalSince1970: 86400)
        ]

        for date in dates {
            let expected = MPDateFormatter.string(fromDateRFC3339: date)

            let launchInfo = MPLaunchInfo(
                URL: url,
                sourceApplication: sourceApp,
                annotation: date,
                logger: logger
            )

            XCTAssertEqual(
                launchInfo.annotation, expected,
                "MPLaunchInfo annotation should match MPDateFormatter output for date \(date)"
            )
        }
    }
}
