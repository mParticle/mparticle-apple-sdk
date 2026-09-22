import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendErrorReporterTests: MPBackendWorkflowTestCase {
    fileprivate var fixture = MPBackendSessionFixture()

    override func setUp() {
        super.setUp()
        fixture = MPBackendSessionFixture()
    }

    private func breadcrumb(_ content: String) -> MPBreadcrumbPRIVATE {
        MPBreadcrumbPRIVATE(
            sessionUUID: "session", breadcrumbId: 1, uuid: "crumb",
            breadcrumbData: Data("{\"c\":\"\(content)\"}".utf8), timestamp: 100
        )
    }

    fileprivate func savedMessageInfo() throws -> [String: Any] {
        let saved = try XCTUnwrap(fixture.persistence.savedMessages.last)
        let dictionary = try XCTUnwrap(saved.dictionaryRepresentation() as? [String: Any])
        return dictionary
    }

    func testHandledErrorFromAnExceptionCarriesItsReasonClassStackAndBreadcrumbs() throws {
        _ = fixture.session()
        fixture.persistence.breadcrumbs = [breadcrumb("earlier")] as NSArray
        let exception = NSException(
            name: NSExceptionName("MPTestFailure"), reason: "it broke", userInfo: nil
        )

        var reported: String?
        try onMessageQueue { [self] in
            reported = fixture.reporter.logError(
                message: "ignored when an exception is present", exception: exception,
                topmostContextDescription: nil, eventInfo: nil
            )
        }

        XCTAssertEqual(reported, "MPTestFailure")
        let info = try savedMessageInfo()
        XCTAssertEqual(info["m"] as? String, "it broke")
        XCTAssertEqual(info["c"] as? String, "MPTestFailure")
        XCTAssertEqual(info["eh"] as? String, "true")
        XCTAssertEqual(info["s"] as? String, "error")
        XCTAssertEqual(info["dt"] as? String, "x")
        XCTAssertEqual((info["bc"] as? [[String: Any]])?.count, 1)
        // An exception that was never raised has no symbols, so the key stays out.
        XCTAssertNil(info["st"])
        // Saved through the writer, so the session's end time moves with the error.
        XCTAssertFalse(fixture.persistence.savedSessions.isEmpty)
    }

    func testHandledErrorWithoutAnExceptionUsesTheMessageContextAndAppImage() throws {
        _ = fixture.session()
        fixture.persistence.breadcrumbs = [breadcrumb("earlier")] as NSArray
        fixture.appImage = ["bid": "com.example.app"]

        var reported: String?
        try onMessageQueue { [self] in
            reported = fixture.reporter.logError(
                message: "plain failure", exception: nil,
                topmostContextDescription: "MPViewController", eventInfo: ["k": "v"]
            )
        }

        XCTAssertEqual(reported, "plain failure")
        let info = try savedMessageInfo()
        XCTAssertEqual(info["m"] as? String, "plain failure")
        XCTAssertEqual(info["tc"] as? String, "MPViewController")
        XCTAssertEqual((info["attrs"] as? [String: Any])?["k"] as? String, "v")
        XCTAssertEqual(info["bid"] as? String, "com.example.app")
        // Breadcrumbs and the crashing class belong to the exception path only.
        XCTAssertNil(info["bc"])
        XCTAssertNil(info["c"])
    }

    func testHandledErrorOmitsAnEmptyEventInfoAndAbsentBreadcrumbs() throws {
        _ = fixture.session()
        fixture.persistence.breadcrumbs = nil

        try onMessageQueue { [self] in
            _ = fixture.reporter.logError(
                message: "plain failure", exception: nil,
                topmostContextDescription: nil, eventInfo: [:]
            )
        }

        let info = try savedMessageInfo()
        XCTAssertNil(info["attrs"])
        XCTAssertNil(info["tc"])
        XCTAssertNil(info["bc"])
    }

    func testCrashReportEncodesTheReportAndSavesWithoutTouchingTheSession() throws {
        _ = fixture.session()
        fixture.persistence.breadcrumbs = [breadcrumb("earlier")] as NSArray

        var reported: String?
        try onMessageQueue { [self] in
            reported = fixture.reporter.logCrash(
                message: "fatal", stackTrace: "frame0\nframe1", plCrashReport: "REPORT"
            )
        }

        XCTAssertEqual(reported, "fatal")
        let info = try savedMessageInfo()
        XCTAssertEqual(info["s"] as? String, "fatal")
        XCTAssertEqual(info["eh"] as? String, "false")
        XCTAssertEqual(info["m"] as? String, "fatal")
        XCTAssertEqual(info["st"] as? String, "frame0\nframe1")
        XCTAssertEqual(info["plc"] as? String, Data("REPORT".utf8).base64EncodedString())
        XCTAssertEqual((info["bc"] as? [[String: Any]])?.count, 1)
        // A crash must not move the session's end time or trigger an upload.
        XCTAssertTrue(fixture.persistence.savedSessions.isEmpty)
        XCTAssertEqual(fixture.uploads, 0)
    }

    func testCrashReportWithoutAMessageReportsTheDefaultText() throws {
        var reported: String?
        try onMessageQueue { [self] in
            reported = fixture.reporter.logCrash(
                message: nil, stackTrace: nil, plCrashReport: "REPORT"
            )
        }

        XCTAssertEqual(reported, "Crash Report")
        let info = try savedMessageInfo()
        XCTAssertNil(info["m"])
        XCTAssertNil(info["st"])
    }

    func testCrashReportTruncatesTheEncodedReportToTheByteBudget() throws {
        let report = String(repeating: "A", count: 400)
        let encodedLength = Data(report.utf8).base64EncodedString().count
        fixture.maxBytesPerEvent = 200

        try onMessageQueue { [self] in
            _ = fixture.reporter.logCrash(message: nil, stackTrace: nil, plCrashReport: report)
        }

        let truncated = try XCTUnwrap(try savedMessageInfo()["plc"] as? String)
        XCTAssertLessThan(truncated.count, encodedLength)
        XCTAssertTrue(Data(report.utf8).base64EncodedString().hasPrefix(truncated))
    }

    func testCrashReportPicksTheFirstRecoveredSessionThatIsNotTheCurrentOne() throws {
        let current = fixture.session()
        let earlier = MPSessionPRIVATE(startTime: 50, userId: 1)
        fixture.persistence.crashSessions = [current, earlier] as NSArray

        try onMessageQueue { [self] in
            _ = fixture.reporter.logCrash(message: nil, stackTrace: nil, plCrashReport: "REPORT")
        }

        XCTAssertEqual(try savedMessageInfo()["sid"] as? String, earlier.uuid)
    }
}

extension MPBackendErrorReporterTests {
    func testCrashReportTrimsTheRawReportToTheConfiguredLength() throws {
        fixture.crashMaxPLReportLength = 7

        try onMessageQueue { [self] in
            _ = fixture.reporter.logCrash(
                message: nil, stackTrace: nil, plCrashReport: "plcrash report test string"
            )
        }

        let encoded = try XCTUnwrap(try savedMessageInfo()["plc"] as? String)
        XCTAssertEqual(encoded, Data("plcrash".utf8).base64EncodedString())
    }
}
