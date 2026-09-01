import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPAttributeValueFilterTests: XCTestCase {
    private let hasher = MPIHasher(logger: MPLog(logLevel: .none))
    private lazy var filter = MPAttributeValueFilter(hasher: hasher)

    private lazy var keyHash = hasher.hashUserAttributeKey("color")
    private lazy var valueHash = hasher.hashUserAttributeValue("blue")

    func testFilteringInactiveAlwaysIncludes() {
        XCTAssertTrue(filter.shouldIncludeEvent(withAttributes: ["color": "red"],
                                                filteringActive: false,
                                                hashedAttribute: keyHash,
                                                hashedValue: valueHash,
                                                shouldIncludeMatches: true))
    }

    func testMatchWithIncludeMatches() {
        XCTAssertTrue(filter.shouldIncludeEvent(withAttributes: ["color": "blue"],
                                                filteringActive: true,
                                                hashedAttribute: keyHash,
                                                hashedValue: valueHash,
                                                shouldIncludeMatches: true))
    }

    func testMatchWithExcludeMatches() {
        XCTAssertFalse(filter.shouldIncludeEvent(withAttributes: ["color": "blue"],
                                                 filteringActive: true,
                                                 hashedAttribute: keyHash,
                                                 hashedValue: valueHash,
                                                 shouldIncludeMatches: false))
    }

    func testValueMismatchIsNotAMatch() {
        XCTAssertFalse(filter.shouldIncludeEvent(withAttributes: ["color": "red"],
                                                 filteringActive: true,
                                                 hashedAttribute: keyHash,
                                                 hashedValue: valueHash,
                                                 shouldIncludeMatches: true))
    }

    func testNoMatchingKeyIsNotAMatch() {
        XCTAssertFalse(filter.shouldIncludeEvent(withAttributes: ["size": "blue"],
                                                 filteringActive: true,
                                                 hashedAttribute: keyHash,
                                                 hashedValue: valueHash,
                                                 shouldIncludeMatches: true))
    }

    func testNonStringValueIsNotAMatch() {
        XCTAssertFalse(filter.shouldIncludeEvent(withAttributes: ["color": 42],
                                                 filteringActive: true,
                                                 hashedAttribute: keyHash,
                                                 hashedValue: valueHash,
                                                 shouldIncludeMatches: true))
    }

    func testNilAttributes() {
        XCTAssertFalse(filter.shouldIncludeEvent(withAttributes: nil,
                                                 filteringActive: true,
                                                 hashedAttribute: keyHash,
                                                 hashedValue: valueHash,
                                                 shouldIncludeMatches: true))
        XCTAssertTrue(filter.shouldIncludeEvent(withAttributes: nil,
                                                filteringActive: true,
                                                hashedAttribute: keyHash,
                                                hashedValue: valueHash,
                                                shouldIncludeMatches: false))
    }
}
