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

    // MARK: - Thread Safety Tests

    func testDateFormatterThreadSafety() {
        // This stress test verifies that MPDateFormatter doesn't crash when
        // called concurrently from multiple threads. DateFormatter is NOT
        // thread-safe, so without synchronization this test would likely crash.
        // Race conditions are non-deterministic, so this test increases the
        // likelihood of catching issues but cannot guarantee detection.

        let expectation = self.expectation(description: "Thread safety stress test")

        let group = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: "com.mparticle.test.dateformatter", attributes: .concurrent)

        let iterations = 100
        var encounteredError = false
        let errorLock = NSLock()

        let rfc3339Strings = [
            "2024-01-15T10:30:00+0000",
            "2023-06-20T15:45:30-0500",
            "1955-11-05T01:15:00-0800"
        ]

        let rfc1123Strings = [
            "Mon, 15 Jan 2024 10:30:00 GMT",
            "Tue, 20 Jun 2023 15:45:30 GMT",
            "Sat, 05 Nov 1955 09:15:00 GMT"
        ]

        // Multiple threads parsing RFC3339 dates
        for _ in 0..<3 {
            group.enter()
            concurrentQueue.async {
                for j in 0..<iterations {
                    errorLock.lock()
                    let hasError = encounteredError
                    errorLock.unlock()
                    if hasError { break }

                    let dateString = rfc3339Strings[j % rfc3339Strings.count]
                    let date = MPDateFormatter.date(fromStringRFC3339: dateString)
                    _ = date // Use the result to prevent optimization
                }
                group.leave()
            }
        }

        // Multiple threads parsing RFC1123 dates
        for _ in 0..<3 {
            group.enter()
            concurrentQueue.async {
                for j in 0..<iterations {
                    errorLock.lock()
                    let hasError = encounteredError
                    errorLock.unlock()
                    if hasError { break }

                    let dateString = rfc1123Strings[j % rfc1123Strings.count]
                    let date = MPDateFormatter.date(fromStringRFC1123: dateString)
                    _ = date
                }
                group.leave()
            }
        }

        // Multiple threads formatting dates to strings
        for _ in 0..<2 {
            group.enter()
            concurrentQueue.async {
                for j in 0..<iterations {
                    errorLock.lock()
                    let hasError = encounteredError
                    errorLock.unlock()
                    if hasError { break }

                    let date = Date(timeIntervalSince1970: Double(j * 86400))
                    let rfc3339 = MPDateFormatter.string(fromDateRFC3339: date)
                    let rfc1123 = MPDateFormatter.string(fromDateRFC1123: date)
                    _ = rfc3339
                    _ = rfc1123
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            XCTAssertFalse(encounteredError, "Thread safety test should complete without errors")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 30, handler: nil)
    }
}
