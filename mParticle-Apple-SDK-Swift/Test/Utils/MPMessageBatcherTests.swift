import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPMessageBatcherTests: XCTestCase {
    // Generous ceilings so only the dimension under test forces a split.
    private let big = 1_000_000

    private func groups(_ byteLengths: [Int],
                        crash: [Bool]? = nil,
                        maxBatchMessages: Int = 100,
                        maxBatchBytes: Int = 1_000_000,
                        maxMessageBytes: Int = 1_000_000,
                        crashMaxBatchBytes: Int = 2_048_000,
                        crashMaxMessageBytes: Int = 1_024_000) -> [[Int]] {
        MPMessageBatcher.batchIndexGroups(
            byteLengths: byteLengths,
            isCrashReport: crash ?? Array(repeating: false, count: byteLengths.count),
            maxBatchMessages: maxBatchMessages,
            maxBatchBytes: maxBatchBytes,
            maxMessageBytes: maxMessageBytes,
            crashMaxBatchBytes: crashMaxBatchBytes,
            crashMaxMessageBytes: crashMaxMessageBytes
        )
    }

    func testEmptyInputProducesNoBatches() {
        XCTAssertEqual(groups([]), [])
    }

    func testEverythingFitsInOneBatch() {
        XCTAssertEqual(groups([10, 20, 30]), [[0, 1, 2]])
    }

    func testMessageCountLimitSplitsBatches() {
        XCTAssertEqual(groups([1, 1, 1, 1, 1], maxBatchMessages: 2), [[0, 1], [2, 3], [4]])
    }

    func testByteBudgetSplitsBatches() {
        // 60 + 60 > 100 forces the second message into a new batch.
        XCTAssertEqual(groups([60, 60, 30], maxBatchBytes: 100), [[0], [1, 2]])
    }

    func testOversizedMessageIsDropped() {
        // Index 1 exceeds the per-message ceiling and is skipped entirely.
        XCTAssertEqual(groups([10, 500, 20], maxMessageBytes: 100), [[0, 2]])
    }

    func testCrashReportUsesLargerCrashCeilings() {
        // 700_000 bytes exceeds the normal per-message ceiling but fits the crash one.
        let result = groups([700_000], crash: [true], maxMessageBytes: 100_000)
        XCTAssertEqual(result, [[0]])
    }

    func testCrashReportExceedingCrashCeilingIsDropped() {
        let result = groups([2_000_000], crash: [true])
        XCTAssertEqual(result, [])
    }

    func testMixedCrashAndNormalRespectPerMessageCeilings() {
        // Normal 500 (dropped, >100), crash 700_000 (kept), normal 50 (kept).
        let result = groups([500, 700_000, 50],
                            crash: [false, true, false],
                            maxMessageBytes: 100)
        XCTAssertEqual(result, [[1, 2]])
    }
}
