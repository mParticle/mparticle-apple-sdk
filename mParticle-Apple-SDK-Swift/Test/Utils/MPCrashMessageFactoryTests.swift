import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPCrashMessageFactoryTests: XCTestCase {
    private let context = MPMessageBuilderContext(dataPlanId: nil, dataPlanVersion: nil, logger: nil)

    private func session(startTime: TimeInterval = 1000, uuid: String) -> MPSessionPRIVATE {
        MPSessionPRIVATE(startTime: startTime, userId: NSNumber(value: 1), uuid: uuid)
    }

    private func breadcrumb(uuid: String) -> MPBreadcrumbPRIVATE {
        let payload: [String: Any] = ["dt": "bc", "ct": 1000, "id": uuid, "sid": "session", "sct": 1000]
        return MPBreadcrumbPRIVATE(
            sessionUUID: "session",
            breadcrumbId: 1,
            uuid: uuid,
            breadcrumbData: try? JSONSerialization.data(withJSONObject: payload),
            timestamp: 1000
        )
    }

    private func crashInfo(
        message: String? = "crash report",
        stackTrace: String? = "stack trace",
        plCrashReport: String? = "plcrash report",
        maxPLReportLength: NSNumber? = nil,
        breadcrumbs: [MPBreadcrumbPRIVATE]? = nil,
        possibleCrashSessions: [MPSessionPRIVATE]? = nil,
        currentSession: MPSessionPRIVATE? = nil
    ) throws -> NSDictionary {
        let message = try XCTUnwrap(MPCrashMessageFactory.crashMessage(
            message: message,
            stackTrace: stackTrace,
            plCrashReport: plCrashReport,
            maxPLReportLength: maxPLReportLength,
            breadcrumbs: breadcrumbs,
            possibleCrashSessions: possibleCrashSessions,
            currentSession: currentSession,
            context: context
        ))
        return try XCTUnwrap(payload(of: message))
    }

    private func errorInfo(
        message: String? = "error message",
        exception: NSException? = nil,
        topmostContextClassName: String? = nil,
        eventInfo: [AnyHashable: Any]? = nil,
        breadcrumbs: [MPBreadcrumbPRIVATE]? = nil,
        currentSession: MPSessionPRIVATE? = nil
    ) throws -> NSDictionary {
        let message = try XCTUnwrap(MPCrashMessageFactory.errorMessage(
            message: message,
            exception: exception,
            topmostContextClassName: topmostContextClassName,
            eventInfo: eventInfo,
            breadcrumbs: breadcrumbs,
            currentSession: currentSession,
            context: context
        ))
        return try XCTUnwrap(payload(of: message))
    }

    /// The assembled message as it will be persisted, read back off `messageData` rather than off
    /// the builder, so truncation is visible.
    private func payload(of message: MPMessagePRIVATE) -> NSDictionary? {
        guard let data = message.messageData else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary
    }

    // MARK: - Crash reports

    func testCrashReportIsFatalAndUnhandled() throws {
        let info = try crashInfo()
        XCTAssertEqual(info["s"] as? String, "fatal")
        XCTAssertEqual(info["eh"] as? String, "false")
        XCTAssertEqual(info["dt"] as? String, "x")
    }

    func testCrashReportCarriesMessageStackTraceAndBase64Report() throws {
        let info = try crashInfo()
        XCTAssertEqual(info["m"] as? String, "crash report")
        XCTAssertEqual(info["st"] as? String, "stack trace")
        XCTAssertEqual(info["plc"] as? String, Data("plcrash report".utf8).base64EncodedString())
    }

    func testCrashReportOmitsKeysForNilInputs() throws {
        let info = try crashInfo(message: nil, stackTrace: nil, plCrashReport: nil)
        XCTAssertNil(info["m"])
        XCTAssertNil(info["st"])
        XCTAssertNil(info["plc"])
        XCTAssertNil(info["bc"])
        // Severity and handled-ness are unconditional.
        XCTAssertEqual(info["s"] as? String, "fatal")
        XCTAssertEqual(info["eh"] as? String, "false")
    }

    func testCrashReportCapsTheReportAtTheSuppliedMaxLength() throws {
        let info = try crashInfo(plCrashReport: "plcrash report", maxPLReportLength: NSNumber(value: 7))
        XCTAssertEqual(info["plc"] as? String, Data("plcrash".utf8).base64EncodedString())
    }

    func testCrashReportWritesAnEmptyArrayForAnEmptyBreadcrumbTrail() throws {
        let info = try crashInfo(breadcrumbs: [])
        XCTAssertEqual((info["bc"] as? [Any])?.count, 0)
    }

    func testCrashReportOmitsBreadcrumbsWhenTheTrailIsMissing() throws {
        let info = try crashInfo(breadcrumbs: nil)
        XCTAssertNil(info["bc"])
    }

    func testCrashReportCarriesTheBreadcrumbTrail() throws {
        let info = try crashInfo(breadcrumbs: [breadcrumb(uuid: "one"), breadcrumb(uuid: "two")])
        let breadcrumbs = try XCTUnwrap(info["bc"] as? [[String: Any]])
        XCTAssertEqual(breadcrumbs.count, 2)
        XCTAssertEqual(breadcrumbs.compactMap { $0["id"] as? String }, ["one", "two"])
    }

    func testCrashReportDropsBreadcrumbsThatCannotBeRepresented() throws {
        let undecodable = MPBreadcrumbPRIVATE(
            sessionUUID: "session",
            breadcrumbId: 2,
            uuid: "bad",
            breadcrumbData: Data("not json".utf8),
            timestamp: 1000
        )
        let info = try crashInfo(breadcrumbs: [breadcrumb(uuid: "one"), undecodable])
        XCTAssertEqual((info["bc"] as? [Any])?.count, 1)
    }

    func testCrashReportIsAttributedToTheFirstSessionThatIsNotTheCurrentOne() throws {
        let current = session(uuid: "current")
        let crashed = session(startTime: 500, uuid: "crashed")
        let info = try crashInfo(possibleCrashSessions: [crashed, current], currentSession: current)
        XCTAssertEqual(info["sid"] as? String, "crashed")
    }

    func testCrashReportSkipsTheCurrentSessionWhenItLeadsTheList() throws {
        let current = session(uuid: "current")
        let crashed = session(startTime: 500, uuid: "crashed")
        let info = try crashInfo(possibleCrashSessions: [current, crashed], currentSession: current)
        XCTAssertEqual(info["sid"] as? String, "crashed")
    }

    func testCrashReportHasNoSessionWhenEveryCandidateIsTheCurrentOne() throws {
        let current = session(uuid: "current")
        let info = try crashInfo(possibleCrashSessions: [current], currentSession: current)
        XCTAssertNil(info["sid"])
    }

    func testCrashReportHasNoSessionWhenThereAreNoCandidates() throws {
        let info = try crashInfo(possibleCrashSessions: nil, currentSession: session(uuid: "current"))
        XCTAssertNil(info["sid"])
    }

    func testCrashReportTakesAnyCandidateWhenThereIsNoCurrentSession() throws {
        let crashed = session(startTime: 500, uuid: "crashed")
        let info = try crashInfo(possibleCrashSessions: [crashed], currentSession: nil)
        XCTAssertEqual(info["sid"] as? String, "crashed")
    }

    func testCrashReportLeavesAnUnderSizedReportIntact() throws {
        let report = String(repeating: "A", count: 1024)
        let info = try crashInfo(plCrashReport: report)
        XCTAssertEqual(info["plc"] as? String, Data(report.utf8).base64EncodedString())
    }

    func testCrashReportTruncatesTheReportToFitThePerEventLimit() throws {
        let limit = MPPersistenceSchemaPRIVATE.maxBytesPerEvent(for: "x")
        let report = String(repeating: "A", count: limit)
        let info = try crashInfo(plCrashReport: report)
        let encoded = try XCTUnwrap(info["plc"] as? String)
        let untruncated = Data(report.utf8).base64EncodedString()
        XCTAssertLessThan(encoded.count, untruncated.count)
        XCTAssertTrue(untruncated.hasPrefix(encoded))
    }

    // MARK: - Error reports

    func testErrorReportIsAnErrorAndHandled() throws {
        let info = try errorInfo()
        XCTAssertEqual(info["s"] as? String, "error")
        XCTAssertEqual(info["eh"] as? String, "true")
        XCTAssertEqual(info["dt"] as? String, "x")
    }

    func testErrorReportUsesTheBareMessageWhenThereIsNoException() throws {
        let info = try errorInfo(message: "something went wrong")
        XCTAssertEqual(info["m"] as? String, "something went wrong")
        XCTAssertNil(info["c"])
        XCTAssertNil(info["st"])
    }

    func testErrorReportTakesMessageAndClassFromTheException() throws {
        let exception = NSException(name: .invalidArgumentException, reason: "bad argument", userInfo: nil)
        let info = try errorInfo(message: "ignored", exception: exception)
        XCTAssertEqual(info["m"] as? String, "bad argument")
        XCTAssertEqual(info["c"] as? String, NSExceptionName.invalidArgumentException.rawValue)
    }

    func testErrorReportJoinsCallStackSymbolsWithNewlines() throws {
        let exception = NSException(name: .genericException, reason: "boom", userInfo: nil)
        let info = try errorInfo(exception: exception)
        XCTAssertEqual(info["st"] as? String, exception.callStackSymbols.joined(separator: "\n"))
    }

    func testErrorReportOmitsTheMessageWhenTheExceptionHasNoReason() throws {
        let exception = NSException(name: .genericException, reason: nil, userInfo: nil)
        let info = try errorInfo(message: "ignored", exception: exception)
        XCTAssertNil(info["m"])
    }

    func testErrorReportCarriesBreadcrumbsWithAnException() throws {
        let exception = NSException(name: .genericException, reason: "boom", userInfo: nil)
        let info = try errorInfo(exception: exception, breadcrumbs: [breadcrumb(uuid: "one")])
        XCTAssertEqual((info["bc"] as? [Any])?.count, 1)
    }

    func testErrorReportOmitsBreadcrumbsWithoutAnException() throws {
        let info = try errorInfo(exception: nil, breadcrumbs: [breadcrumb(uuid: "one")])
        XCTAssertNil(info["bc"])
    }

    func testErrorReportRecordsTheTopmostContextClassName() throws {
        let info = try errorInfo(topmostContextClassName: "UIViewController")
        XCTAssertEqual(info["tc"] as? String, "UIViewController")
    }

    func testErrorReportOmitsTheTopmostContextWhenAbsent() throws {
        let info = try errorInfo(topmostContextClassName: nil)
        XCTAssertNil(info["tc"])
    }

    func testErrorReportStoresEventInfoUnderAttributes() throws {
        let info = try errorInfo(eventInfo: ["key": "value"])
        XCTAssertEqual((info["attrs"] as? [String: Any])?["key"] as? String, "value")
    }

    func testErrorReportOmitsEmptyEventInfo() throws {
        XCTAssertNil(try errorInfo(eventInfo: [:])["attrs"])
        XCTAssertNil(try errorInfo(eventInfo: nil)["attrs"])
    }

    func testErrorReportMergesAppImageInfo() throws {
        let info = try errorInfo()
        for key in MPApplication_PRIVATE.appImageInfo().keys {
            XCTAssertNotNil(info[key], "expected app image key \(key) to be merged into the message")
        }
    }

    func testErrorReportUsesTheCurrentSession() throws {
        let info = try errorInfo(currentSession: session(uuid: "current"))
        XCTAssertEqual(info["sid"] as? String, "current")
    }
}
