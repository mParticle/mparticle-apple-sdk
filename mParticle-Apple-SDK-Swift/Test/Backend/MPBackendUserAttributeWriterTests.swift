import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendUserAttributeWriterTests: MPBackendWorkflowTestCase {
    private var fixture = MPBackendSessionFixture()

    override func setUp() {
        super.setUp()
        fixture = MPBackendSessionFixture()
        _ = fixture.session()
    }

    private var writer: MPBackendUserAttributeWriter { fixture.userAttributes }

    private func stored() -> [String: Any] {
        writer.userAttributes(forUserId: fixture.userID) as? [String: Any] ?? [:]
    }

    private func loggedChanges() -> [[String: Any]] {
        fixture.persistence.savedMessages.compactMap {
            $0.dictionaryRepresentation() as? [String: Any]
        }
    }

    func testSettingAnAttributeStoresItAndLogsTheChange() throws {
        try onMessageQueue { [self] in
            let outcome = writer.setUserAttribute("Height", value: "183", timestamp: Date(timeIntervalSince1970: 100))
            XCTAssertEqual(outcome.status, .success)
            XCTAssertEqual(outcome.key as? String, "Height")
        }

        XCTAssertEqual(stored()["Height"] as? String, "183")
        let message = try XCTUnwrap(loggedChanges().last)
        XCTAssertEqual(message["dt"] as? String, "uac")
        XCTAssertEqual(fixture.validated.map(\.key), ["Height"])
    }

    func testTheStoredKeyWinsOverADifferentlyCasedRequest() throws {
        try onMessageQueue { [self] in
            _ = writer.setUserAttribute("Height", value: "183", timestamp: nil)
            _ = writer.setUserAttribute("height", value: "190", timestamp: nil)
        }

        // One entry, under the key that was stored first.
        XCTAssertEqual(stored().count, 1)
        XCTAssertEqual(stored()["Height"] as? String, "190")
    }

    func testATagRoundTripsThroughTheNullSentinel() throws {
        try onMessageQueue { [self] in
            XCTAssertEqual(writer.setUserTag("Premium", timestamp: nil).status, .success)
        }

        XCTAssertTrue(stored()["Premium"] is NSNull)
    }

    func testRemovingAPresentAttributeDeletesItAndRecordsTheDeletion() throws {
        try onMessageQueue { [self] in
            _ = writer.setUserAttribute("Height", value: "183", timestamp: nil)
            fixture.validationResult = .nilValue
            XCTAssertEqual(writer.removeUserAttribute("Height", timestamp: nil).status, .success)
        }

        XCTAssertNil(stored()["Height"])
        XCTAssertEqual(writer.deletedUserAttributes?.count, 1)
        XCTAssertTrue(try XCTUnwrap(writer.deletedUserAttributes).contains("Height"))

        writer.clearDeletedUserAttributes()
        XCTAssertNil(writer.deletedUserAttributes)
    }

    func testRemovingAnAbsentAttributeIsRejected() throws {
        fixture.validationResult = .nilValue

        try onMessageQueue { [self] in
            XCTAssertEqual(writer.removeUserAttribute("Nothing", timestamp: nil).status, .invalidDataType)
        }

        XCTAssertNil(writer.deletedUserAttributes)
        XCTAssertTrue(stored().isEmpty)
    }

    func testAFailedValidationRejectsWithoutWritingOrLogging() throws {
        fixture.validationResult = .keyTooLong

        try onMessageQueue { [self] in
            let outcome = writer.setUserAttribute("Height", value: "183", timestamp: nil)
            XCTAssertEqual(outcome.status, .invalidDataType)
        }

        XCTAssertTrue(stored().isEmpty)
        XCTAssertTrue(loggedChanges().isEmpty)
    }

    func testOptOutShortCircuitsBeforeReadingOrValidating() throws {
        fixture.optOutValue = true

        try onMessageQueue { [self] in
            let outcome = writer.setUserAttribute("Height", value: "183", timestamp: nil)
            XCTAssertEqual(outcome.status, .optOut)
            XCTAssertEqual(outcome.value as? String, "183")
        }

        XCTAssertTrue(stored().isEmpty)
        XCTAssertTrue(fixture.validated.isEmpty)
    }

    func testAnUnusableKeyReportsAMissingParameter() throws {
        try onMessageQueue { [self] in
            XCTAssertEqual(writer.setUserAttribute(nil, value: "183", timestamp: nil).status, .missingParam)
            // Objective-C callers can hand an NSNull through an NSString parameter.
            XCTAssertEqual(writer.setUserAttribute(NSNull(), value: "183", timestamp: nil).status, .missingParam)
            XCTAssertEqual(writer.setUserAttribute(NSNumber(value: 7), value: "183", timestamp: nil).status, .missingParam)
            XCTAssertEqual(writer.setUserTag(nil, timestamp: nil).status, .missingParam)
            XCTAssertEqual(writer.removeUserAttribute(nil, timestamp: nil).status, .missingParam)
            XCTAssertEqual(writer.setUserAttribute(nil, values: ["a"], timestamp: nil).status, .missingParam)
        }

        XCTAssertTrue(stored().isEmpty)
        XCTAssertTrue(fixture.validated.isEmpty)
    }

    func testAnUnacceptableScalarOrListIsRejectedBeforeTheChangeIsBuilt() throws {
        try onMessageQueue { [self] in
            XCTAssertEqual(writer.setUserAttribute("Height", value: "", timestamp: nil).status, .invalidDataType)
            XCTAssertEqual(writer.setUserAttribute("Height", value: Date(), timestamp: nil).status, .invalidDataType)
            XCTAssertEqual(writer.setUserAttribute("Sizes", values: [], timestamp: nil).status, .invalidDataType)
            XCTAssertEqual(writer.setUserAttribute("Sizes", values: nil, timestamp: nil).status, .invalidDataType)
        }

        XCTAssertTrue(fixture.validated.isEmpty)
    }

    func testAValueListIsStoredAsAnArray() throws {
        try onMessageQueue { [self] in
            XCTAssertEqual(writer.setUserAttribute("Sizes", values: ["S", "M"], timestamp: nil).status, .success)
        }

        XCTAssertEqual(stored()["Sizes"] as? [String], ["S", "M"])
    }

    func testIncrementAddsToTheStoredNumberAndReturnsTheTotal() throws {
        try onMessageQueue { [self] in
            _ = writer.setUserAttribute("Push ups", value: NSNumber(value: 10), timestamp: nil)
            let total = writer.incrementUserAttribute("Push ups", byValue: NSNumber(value: 5))
            XCTAssertEqual(total, NSNumber(value: 15))
        }

        XCTAssertEqual(stored()["Push ups"] as? NSNumber, NSNumber(value: 15))
    }

    func testIncrementStartsFromZeroForAnAbsentAttribute() throws {
        try onMessageQueue { [self] in
            XCTAssertEqual(writer.incrementUserAttribute("Push ups", byValue: NSNumber(value: 5)), NSNumber(value: 5))
        }

        XCTAssertEqual(stored()["Push ups"] as? NSNumber, NSNumber(value: 5))
    }

    func testIncrementRefusesANonNumericAttribute() throws {
        try onMessageQueue { [self] in
            _ = writer.setUserAttribute("Height", value: "183cm", timestamp: nil)
            XCTAssertNil(writer.incrementUserAttribute("Height", byValue: NSNumber(value: 5)))
        }

        XCTAssertEqual(stored()["Height"] as? String, "183cm")
    }

    func testIncrementRefusesATagBecauseNullIsNotANumber() throws {
        try onMessageQueue { [self] in
            _ = writer.setUserTag("Premium", timestamp: nil)
            XCTAssertNil(writer.incrementUserAttribute("Premium", byValue: NSNumber(value: 5)))
        }

        XCTAssertTrue(stored()["Premium"] is NSNull)
    }

    func testClearRemovesEveryStoredAttribute() throws {
        try onMessageQueue { [self] in
            _ = writer.setUserAttribute("Height", value: "183", timestamp: nil)
            writer.clearUserAttributes()
        }

        XCTAssertTrue(stored().isEmpty)
    }

    func testAValueListWithANonStringEntryReachesTheValidatorInsteadOfTrapping() throws {
        // The Objective-C signature's NSArray<NSString *> is not enforced; the validator is what
        // rejects a bad entry, so it has to be reached rather than tripped over at the bridge.
        fixture.validationResult = .invalidArrayEntry
        let mixed: [Any] = ["S", NSNumber(value: 7)]

        try onMessageQueue { [self] in
            let outcome = writer.setUserAttribute("Sizes", values: mixed, timestamp: nil)
            XCTAssertEqual(outcome.status, .invalidDataType)
            XCTAssertEqual((outcome.value as? [Any])?.count, 2)
        }

        XCTAssertEqual(fixture.validated.map(\.key), ["Sizes"])
        XCTAssertTrue(stored().isEmpty)
    }

    func testIncrementMatchesTheStoredKeyIgnoringCase() throws {
        try onMessageQueue { [self] in
            _ = writer.setUserAttribute("Push ups", value: NSNumber(value: 10), timestamp: nil)
            XCTAssertEqual(writer.incrementUserAttribute("PUSH UPS", byValue: NSNumber(value: 5)), NSNumber(value: 15))
        }

        XCTAssertEqual(stored().count, 1)
        XCTAssertEqual(stored()["Push ups"] as? NSNumber, NSNumber(value: 15))
    }

    func testIncrementStampsTheChangeMessageWithItsOwnClock() throws {
        fixture.attributeDependencies.now = { Date(timeIntervalSince1970: 500) }

        try onMessageQueue { [self] in
            _ = writer.incrementUserAttribute("Push ups", byValue: NSNumber(value: 5))
        }

        let change = try XCTUnwrap(fixture.persistence.savedMessages.last)
        XCTAssertEqual(change.messageType, "uac")
        XCTAssertEqual(change.timestamp, 500)
    }

    func testIncrementRefusesAnUnusableKeyOrValueWithoutWriting() throws {
        try onMessageQueue { [self] in
            XCTAssertNil(writer.incrementUserAttribute(NSNull(), byValue: NSNumber(value: 5)))
            XCTAssertNil(writer.incrementUserAttribute(nil, byValue: NSNumber(value: 5)))
            XCTAssertNil(writer.incrementUserAttribute("Push ups", byValue: "5"))
            XCTAssertNil(writer.incrementUserAttribute("Push ups", byValue: NSNull()))
        }

        XCTAssertTrue(stored().isEmpty)
        XCTAssertTrue(fixture.persistence.savedMessages.isEmpty)
    }

    func testTheNullSentinelComesFromTheInjectedValueNotAMirroredConstant() throws {
        // Set before the dependency bag is first built, so the writer is constructed with it.
        fixture.nullSentinel = "<absent>"

        try onMessageQueue { [self] in
            XCTAssertEqual(writer.setUserTag("Premium", timestamp: nil).status, .success)
        }

        let raw = fixture.defaults.mpObject(forKey: "ua", userId: fixture.userID) as? [String: Any]
        XCTAssertEqual(raw?["Premium"] as? String, "<absent>")
        XCTAssertTrue(stored()["Premium"] is NSNull)
    }
}
