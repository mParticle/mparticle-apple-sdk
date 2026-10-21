import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendAttributeValidationTests: XCTestCase {
    private var host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
    private var messages: [String] = []

    override func setUp() {
        super.setUp()
        host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
        messages = []
        let log = MPLog(logLevel: .error)
        log.customLogger = { [unowned self] in messages.append($0) }
        host.log = log
    }

    func testAValidPairPassesWithoutLogging() {
        XCTAssertEqual(MPBackendAttributeValidation.validate(key: "key", value: "value", host: host), .valid)
        XCTAssertNoThrow(try MPBackendAttributeValidation.check(key: "key", value: "value", host: host))
        XCTAssertTrue(messages.isEmpty)
    }

    func testTheLimitsComeFromTheHost() {
        host.keyLengthLimit = 3
        host.valueLengthLimit = 5

        XCTAssertEqual(MPBackendAttributeValidation.validate(key: "four", value: "v", host: host), .keyTooLong)
        XCTAssertEqual(MPBackendAttributeValidation.validate(key: "k", value: "sixsix", host: host), .valueTooLong)
        XCTAssertEqual(MPBackendAttributeValidation.validate(key: "k", value: ["abc", "def"], host: host), .arrayValueTooLong)
    }

    func testEachRejectionLogsItsReason() {
        host.keyLengthLimit = 3
        host.valueLengthLimit = 5
        _ = MPBackendAttributeValidation.validate(key: nil, value: "v", host: host)
        _ = MPBackendAttributeValidation.validate(key: "four", value: "v", host: host)
        _ = MPBackendAttributeValidation.validate(key: "k", value: Date(), host: host)
        _ = MPBackendAttributeValidation.validate(key: "k", value: "sixsix", host: host)
        _ = MPBackendAttributeValidation.validate(key: "k", value: ["abc", "def"], host: host)
        _ = MPBackendAttributeValidation.validate(key: "k", value: ["a", NSNumber(value: 10.0)], host: host)
        _ = MPBackendAttributeValidation.validate(key: "k", value: nil, host: host)

        XCTAssertEqual(messages, [
            "mParticle -> Error while setting attribute key: the key parameter cannot be nil",
            "mParticle -> Error while setting attribute key: the key parameter is longer than the maximum allowed length.",
            "mParticle -> Error while setting attribute value: must be an NSString or NSArray",
            "mParticle -> Error while setting attribute value: value is longer than the maximum allowed sixsix",
            "mParticle -> Error while setting attribute value list: combined length of list values "
                + "longer than the maximum alowed.",
            "mParticle -> Error while setting attribute value list: all user attribute entries "
                + "in the array must be of type string. Error entry: 10"
        ])
    }

    func testARejectedValueIsDescribedOnlyAtTheErrorLevel() {
        let quiet = MPBackendDescriptionRecorder()
        host.log = MPLog(logLevel: .none)
        XCTAssertEqual(MPBackendAttributeValidation.validate(key: "k", value: ["a", quiet], host: host), .invalidArrayEntry)
        XCTAssertFalse(quiet.wasDescribed)

        let logged = MPBackendDescriptionRecorder()
        host.log = MPLog(logLevel: .error)
        XCTAssertEqual(MPBackendAttributeValidation.validate(key: "k", value: ["a", logged], host: host), .invalidArrayEntry)
        XCTAssertTrue(logged.wasDescribed)
    }

    func testCheckThrowsTheCodeForEachRejection() {
        host.keyLengthLimit = 3
        host.valueLengthLimit = 3
        let cases: [(pair: (key: Any?, value: Any?), code: MPAttributeValidationErrorCode)] = [
            ((nil, "v"), .invalidKey),
            (("four", "v"), .keyTooLong),
            (("k", nil), .nilValue),
            (("k", "four"), .valueTooLong),
            (("k", ["ab", "cd"]), .valueTooLong),
            (("k", Date()), .invalidDataType),
            (("k", ["a", NSNumber(value: 1)]), .invalidDataType)
        ]
        for (pair, code) in cases {
            XCTAssertThrowsError(try MPBackendAttributeValidation.check(key: pair.key, value: pair.value, host: host)) { error in
                let error = error as NSError
                XCTAssertEqual(error.domain, "Attribute Validation")
                XCTAssertEqual(error.code, code.rawValue)
            }
        }
    }
}

/// An object that records whether its description was asked for.
private final class MPBackendDescriptionRecorder: NSObject {
    private(set) var wasDescribed = false

    override var description: String {
        wasDescribed = true
        return "recorder"
    }
}
