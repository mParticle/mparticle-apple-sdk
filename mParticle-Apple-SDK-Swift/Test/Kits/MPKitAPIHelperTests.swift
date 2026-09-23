import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPKitAPIHelperTests: XCTestCase {
    private let error = NSError(domain: "test", code: 1)

    func testSuccessProducesNoFailure() {
        XCTAssertNil(MPKitAPIHelper.attributionFailure(for: nil, hasResult: true))
    }

    func testAnErrorWithAResultReportsTheAttributionError() {
        let failure = MPKitAPIHelper.attributionFailure(for: error, hasResult: true)

        XCTAssertEqual(failure?.message, "mParticle Kit Attribution Error")
        XCTAssertTrue(failure?.includesUnderlyingError ?? false)
    }

    func testNoResultAndNoErrorReportsTheMissingResult() {
        let failure = MPKitAPIHelper.attributionFailure(for: nil, hasResult: false)

        XCTAssertEqual(
            failure?.message,
            "mParticle Kit Attribution handler was called with nil info and no error"
        )
        XCTAssertFalse(failure?.includesUnderlyingError ?? true)
    }

    func testBothAnErrorAndNoResultReportsTheMissingResultButKeepsTheError() {
        // The ObjC assigned errorMessage twice, so the missing-result message
        // wins even though an underlying error is still attached.
        let failure = MPKitAPIHelper.attributionFailure(for: error, hasResult: false)

        XCTAssertEqual(
            failure?.message,
            "mParticle Kit Attribution handler was called with nil info and no error"
        )
        XCTAssertTrue(failure?.includesUnderlyingError ?? false)
    }

    func testLogMessagePrefixesTheKitName() {
        XCTAssertEqual(
            MPKitAPIHelper.logMessage(kitName: "Braze", message: "something happened"),
            "Braze Kit: something happened"
        )
    }

    func testLogMessageRendersAnUnknownKitNameAsNull() {
        // %@ rendered a nil kit name as "(null)", which an unregistered kit code
        // really does produce.
        XCTAssertEqual(
            MPKitAPIHelper.logMessage(kitName: nil, message: "msg"),
            "(null) Kit: msg"
        )
    }

    // MARK: - attributionError

    func testAttributionErrorIsNilOnSuccess() {
        XCTAssertNil(MPKitAPIHelper.attributionError(for: nil, hasResult: true, kitCode: 42))
    }

    func testAttributionErrorUsesTheKitApiDomainAndZeroCode() {
        let result = MPKitAPIHelper.attributionError(for: error, hasResult: true, kitCode: 42)

        XCTAssertEqual(result?.domain, "com.mparticle.kitapi")
        XCTAssertEqual(result?.code, 0)
        XCTAssertEqual(
            result?.userInfo["mParticle Kit API Error"] as? String,
            "mParticle Kit Attribution Error"
        )
    }

    func testAttributionErrorCarriesTheKitCodeAsTheSameNumber() {
        let kitCode = NSNumber(value: 42)
        let result = MPKitAPIHelper.attributionError(for: error, hasResult: true, kitCode: kitCode)

        XCTAssertIdentical(result?.userInfo["mParticleKitInstanceKey"] as? NSNumber, kitCode)
    }

    func testAttributionErrorOmitsTheKitCodeWhenNil() {
        let result = MPKitAPIHelper.attributionError(for: error, hasResult: true, kitCode: nil)

        XCTAssertNil(result?.userInfo["mParticleKitInstanceKey"])
        XCTAssertEqual(
            Set((result?.userInfo ?? [:]).keys),
            ["mParticle Kit API Error", NSUnderlyingErrorKey]
        )
    }

    func testAttributionErrorAttachesTheUnderlyingErrorByReference() {
        let result = MPKitAPIHelper.attributionError(for: error, hasResult: true, kitCode: 42)

        XCTAssertIdentical(result?.userInfo[NSUnderlyingErrorKey] as? NSError, error)
    }

    func testAttributionErrorWithoutAnUnderlyingErrorOmitsTheKey() {
        let result = MPKitAPIHelper.attributionError(for: nil, hasResult: false, kitCode: 42)

        XCTAssertNil(result?.userInfo[NSUnderlyingErrorKey])
        XCTAssertEqual(
            Set((result?.userInfo ?? [:]).keys),
            ["mParticle Kit API Error", "mParticleKitInstanceKey"]
        )
    }

    func testAttributionErrorKeepsTheDoubleAssignmentQuirk() {
        // An error with no result reports the missing-result message and still
        // attaches the underlying error.
        let result = MPKitAPIHelper.attributionError(for: error, hasResult: false, kitCode: 42)

        XCTAssertEqual(
            result?.userInfo["mParticle Kit API Error"] as? String,
            "mParticle Kit Attribution handler was called with nil info and no error"
        )
        XCTAssertIdentical(result?.userInfo[NSUnderlyingErrorKey] as? NSError, error)
    }

    // MARK: - emitKitLog

    private func captureKitLog(
        messageLevel: MPILogLevelSwift,
        currentLogLevel: UInt,
        message: String = "something happened",
        kitName: String? = "Braze"
    ) -> [String] {
        var captured: [String] = []
        MPKitAPIHelper.emitKitLog(
            kitName: kitName,
            message: message,
            messageLevel: messageLevel,
            currentLogLevel: currentLogLevel,
            customLogger: { captured.append($0) }
        )
        return captured
    }

    func testEmitKitLogPrefixesMParticleAndTheKitName() {
        XCTAssertEqual(
            captureKitLog(messageLevel: .debug, currentLogLevel: 4),
            ["mParticle -> Braze Kit: something happened"]
        )
    }

    func testEmitKitLogRespectsTheLevelGate() {
        XCTAssertEqual(captureKitLog(messageLevel: .error, currentLogLevel: 2).count, 1)
        XCTAssertEqual(captureKitLog(messageLevel: .warning, currentLogLevel: 2).count, 1)
        XCTAssertEqual(captureKitLog(messageLevel: .debug, currentLogLevel: 2).count, 0)
        XCTAssertEqual(captureKitLog(messageLevel: .verbose, currentLogLevel: 2).count, 0)
    }

    func testEmitKitLogIsSilentAtLevelNone() {
        for level: MPILogLevelSwift in [.error, .warning, .debug, .verbose] {
            XCTAssertEqual(captureKitLog(messageLevel: level, currentLogLevel: 0).count, 0)
        }
    }

    func testEmitKitLogHonoursAnOutOfRangeLogLevel() {
        // MPLog.from(rawValue:) clamps an unrecognised raw value to .none, which
        // would silence a level the MPILogger macro logs. This pins the raw
        // numeric comparison so a future "just reuse MPLog" change cannot
        // quietly swallow these messages.
        for level: MPILogLevelSwift in [.error, .warning, .debug, .verbose] {
            XCTAssertEqual(captureKitLog(messageLevel: level, currentLogLevel: 99).count, 1)
        }
    }

    func testEmitKitLogDoesNotReinterpretFormatSpecifiersInTheMessage() {
        XCTAssertEqual(
            captureKitLog(messageLevel: .error, currentLogLevel: 4, message: "100% done %@"),
            ["mParticle -> Braze Kit: 100% done %@"]
        )
    }

    func testEmitKitLogRendersAnUnknownKitNameAsNull() {
        XCTAssertEqual(
            captureKitLog(messageLevel: .error, currentLogLevel: 4, kitName: nil),
            ["mParticle -> (null) Kit: something happened"]
        )
    }

    func testEmitKitLogWithoutACustomLoggerDoesNotCrash() {
        MPKitAPIHelper.emitKitLog(
            kitName: "Braze",
            message: "falls through to NSLog",
            messageLevel: .error,
            currentLogLevel: 4,
            customLogger: nil
        )
    }

    // MARK: - hashString

    func testHashStringMatchesTheHasher() {
        let reference = MPIHasher(logger: MPLog(logLevel: .none))

        for input in ["good data", "bad data", "MixedCase", "ß"] {
            XCTAssertEqual(
                MPKitAPIHelper.hashString(input, logLevel: 0, customLogger: nil),
                reference.hashString(input)
            )
        }
    }

    func testHashStringOfEmptyStringIsEmpty() {
        XCTAssertEqual(MPKitAPIHelper.hashString("", logLevel: 0, customLogger: nil), "")
    }

    func testHashStringIgnoresLoggingConfiguration() {
        var captured: [String] = []
        let quiet = MPKitAPIHelper.hashString("good data", logLevel: 0, customLogger: nil)
        let verbose = MPKitAPIHelper.hashString(
            "good data",
            logLevel: 4,
            customLogger: { captured.append($0) }
        )

        XCTAssertEqual(quiet, verbose)
        // The logger only feeds an encoding-failure warning that a Swift String
        // cannot trigger, so hashing emits nothing at any level.
        XCTAssertTrue(captured.isEmpty)
    }

    func testHashStringIsConcurrencySafe() {
        // Fails loudly if the MPLog/MPIHasher assembly is ever memoized into
        // shared mutable state; kits call this from arbitrary threads, in loops.
        let reference = MPKitAPIHelper.hashString("good data", logLevel: 0, customLogger: nil)
        let results = NSMutableArray()
        let lock = NSLock()

        DispatchQueue.concurrentPerform(iterations: 200) { _ in
            let hash = MPKitAPIHelper.hashString("good data", logLevel: 4, customLogger: nil)
            lock.lock()
            results.add(hash)
            lock.unlock()
        }

        XCTAssertEqual(results.count, 200)
        XCTAssertEqual(Set(results.compactMap { $0 as? String }), [reference])
    }
}
