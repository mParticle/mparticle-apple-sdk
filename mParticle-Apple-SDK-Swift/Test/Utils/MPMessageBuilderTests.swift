import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPMessageBuilderTests: XCTestCase {
    private let context = MPMessageBuilderContext(dataPlanId: nil, dataPlanVersion: nil, logger: nil)

    private func makeSession(uuid: String = "session-uuid", userId: NSNumber = 42) -> MPSessionPRIVATE {
        let session = MPSessionPRIVATE(startTime: 1000, userId: userId, uuid: uuid)
        session.sessionUserIds = "42,0,7"
        return session
    }

    // MARK: - Message type <-> wire string

    func testStringForMessageTypeFallsBackToUnknown() {
        XCTAssertEqual(MPMessageBuilderPRIVATE.string(forMessageType: 19, logger: nil), "unknown")
        XCTAssertEqual(MPMessageBuilderPRIVATE.string(forMessageType: 4, logger: nil), "e")
    }

    func testMessageTypeForStringFallsBackToUnknownRawValue() {
        XCTAssertEqual(MPMessageBuilderPRIVATE.messageType(forString: "not-a-type", logger: nil), 0)
        XCTAssertEqual(MPMessageBuilderPRIVATE.messageType(forString: "ast", logger: nil), 10)
    }

    // MARK: - Init

    func testInitReturnsNilForTheUnknownMessageType() {
        XCTAssertNil(MPMessageBuilderPRIVATE(messageType: 0, session: nil, context: context))
    }

    func testInitSeedsTheTimestampInMilliseconds() throws {
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(messageType: 4, session: nil, context: context))
        let stamped = try XCTUnwrap(builder.messageInfo["ct"] as? Double)
        XCTAssertEqual(stamped, MPMilliseconds(timestamp: builder.timestamp))
    }

    func testSessionStartTakesItsMessageIdFromTheSessionUUID() throws {
        let session = makeSession(uuid: "start-uuid")
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(messageType: 1, session: session, context: context))

        // Session start carries neither the session id nor the session start timestamp...
        XCTAssertNil(builder.messageInfo["sid"])
        XCTAssertNil(builder.messageInfo["sct"])
        // ...and reuses the session UUID as the message id.
        XCTAssertEqual(builder.build().uuid, "start-uuid")
    }

    func testNonSessionStartCarriesSessionIdentifiers() throws {
        let session = makeSession(uuid: "abc")
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(messageType: 4, session: session, context: context))

        XCTAssertEqual(builder.messageInfo["sid"] as? String, "abc")
        XCTAssertEqual(builder.messageInfo["sct"] as? Double, MPMilliseconds(timestamp: session.startTime))
        // Only session end carries the user-id list.
        XCTAssertNil(builder.messageInfo["smpids"])
    }

    func testSessionEndCarriesTheFilteredSessionUserIds() throws {
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(messageType: 2, session: makeSession(), context: context))
        XCTAssertEqual(builder.messageInfo["smpids"] as? [NSNumber], [42, 7])
    }

    func testMessageInfoIsMergedAndAttributesAreStringified() throws {
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(
            messageType: 4,
            session: nil,
            messageInfo: ["n": "event-name", "attrs": ["count": NSNumber(value: 3), "flag": NSNumber(value: true)]],
            context: context
        ))

        XCTAssertEqual(builder.messageInfo["n"] as? String, "event-name")
        let attributes = try XCTUnwrap(builder.messageInfo["attrs"] as? NSDictionary)
        XCTAssertEqual(attributes["count"] as? String, "3")
        XCTAssertEqual(attributes["flag"] as? String, "true")
    }

    func testUnsupportedAttributeValuesAreDropped() throws {
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(
            messageType: 4,
            session: nil,
            messageInfo: ["attrs": ["keep": "yes", "drop": MPMessageBuilderTests()]],
            context: context
        ))

        let attributes = try XCTUnwrap(builder.messageInfo["attrs"] as? NSDictionary)
        XCTAssertEqual(attributes["keep"] as? String, "yes")
        XCTAssertNil(attributes["drop"])
    }

    func testNonDictionaryAttributesAreLeftUntouched() throws {
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(
            messageType: 4,
            session: nil,
            messageInfo: ["attrs": "not-a-dictionary"],
            context: context
        ))
        XCTAssertEqual(builder.messageInfo["attrs"] as? String, "not-a-dictionary")
    }

    // MARK: - Mutators

    func testUpdatingTheTimestampRewritesBothTheFieldAndTheDictionary() throws {
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(messageType: 4, session: nil, context: context))
        builder.updateTimestamp(1234.5)

        XCTAssertEqual(builder.timestamp, 1234.5)
        XCTAssertEqual(builder.messageInfo["ct"] as? Double, MPMilliseconds(timestamp: 1234.5))
        XCTAssertEqual(builder.build().timestamp, 1234.5)
    }

    func testStateTransitionWritesTheLaunchFields() throws {
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(messageType: 10, session: nil, context: context))
        let launchInfo = MPLaunchInfo(
            URL: URL(string: "myapp://open?a=1")!,
            sourceApplication: "com.example.host",
            annotation: "note",
            logger: MPLog(logLevel: .none)
        )

        builder.stateTransition(true, previousSession: nil, launchInfo: launchInfo)

        XCTAssertEqual(builder.messageInfo["src"] as? String, "com.example.host")
        XCTAssertEqual(builder.messageInfo["lr"] as? String, "myapp://open?a=1")
        XCTAssertEqual(builder.messageInfo["lpr"] as? String, "note")
        XCTAssertEqual(builder.messageInfo["nsi"] as? Int, 0)
        XCTAssertEqual(builder.messageInfo["sf"] as? Bool, true)
    }

    func testStateTransitionWithoutLaunchInfoStillWritesTheCounters() throws {
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(messageType: 10, session: nil, context: context))
        builder.stateTransition(false, previousSession: nil, launchInfo: nil)

        XCTAssertNil(builder.messageInfo["src"])
        XCTAssertNil(builder.messageInfo["lr"])
        XCTAssertNil(builder.messageInfo["lpr"])
        XCTAssertEqual(builder.messageInfo["nsi"] as? Int, 0)
        XCTAssertEqual(builder.messageInfo["sf"] as? Bool, false)
    }

    // MARK: - Change payloads

    func testUserAttributeChangeFieldsAreWritten() throws {
        let change = try XCTUnwrap(MPUserAttributeChange(userAttributes: ["colour": "blue"], key: "colour", value: "red"))
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(
            messageType: 17,
            session: nil,
            userAttributeChange: change,
            context: context
        ))

        XCTAssertEqual(builder.messageInfo["d"] as? Bool, false)
        XCTAssertEqual(builder.messageInfo["n"] as? String, "colour")
        XCTAssertEqual(builder.messageInfo["ov"] as? String, "blue")
        XCTAssertEqual(builder.messageInfo["nv"] as? String, "red")
        XCTAssertEqual(builder.messageInfo["na"] as? Bool, false)
    }

    func testUserIdentityChangeFieldsAreWritten() throws {
        let change = MPUserIdentityChangePRIVATE(
            newUserIdentity: MPUserIdentityInstancePRIVATE(type: .customerId, value: "new"),
            oldUserIdentity: MPUserIdentityInstancePRIVATE(type: .customerId, value: "old"),
            timestamp: Date(),
            userIdentities: nil
        )
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(
            messageType: 18,
            session: nil,
            userIdentityChange: change,
            context: context
        ))

        XCTAssertEqual((builder.messageInfo["ni"] as? NSDictionary)?["i"] as? String, "new")
        XCTAssertEqual((builder.messageInfo["oi"] as? NSDictionary)?["i"] as? String, "old")
    }

    // MARK: - Build

    func testBuildCarriesTypeIdentifierAndDataPlan() throws {
        let dataPlanContext = MPMessageBuilderContext(
            dataPlanId: "plan",
            dataPlanVersion: NSNumber(value: 2),
            logger: nil
        )
        let session = makeSession(userId: 99)
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(messageType: 4, session: session, context: dataPlanContext))
        let message = builder.build()

        XCTAssertEqual(message.messageType, "e")
        XCTAssertEqual(message.dataPlanId, "plan")
        XCTAssertEqual(message.dataPlanVersion, NSNumber(value: 2))
        XCTAssertEqual(message.userId, NSNumber(value: 99))
        XCTAssertEqual(message.uploadStatus, 1)
        XCTAssertEqual(builder.messageInfo["dt"] as? String, "e")
        XCTAssertEqual(builder.messageInfo["id"] as? String, message.uuid)
        XCTAssertNotNil(UUID(uuidString: try XCTUnwrap(message.uuid)))
    }

    func testBuildFallsBackToTheStoredMpIdWhenTheSessionHasNoUser() throws {
        let builder = try XCTUnwrap(MPMessageBuilderPRIVATE(messageType: 4, session: nil, context: context))
        XCTAssertEqual(builder.build().userId, MPUserDefaults.storedMpId())
    }

    func testBuiltOffTheMainThreadIsMarkedAsSuch() throws {
        let built = expectation(description: "built off the main thread")
        var info: [AnyHashable: Any] = [:]

        DispatchQueue.global().async {
            if let builder = MPMessageBuilderPRIVATE(messageType: 4, session: nil, context: self.context) {
                info = builder.messageInfo
            }
            built.fulfill()
        }
        wait(for: [built], timeout: 5)

        XCTAssertEqual(info["mt"] as? Bool, false)
        XCTAssertEqual(info["vc"] as? String, "off_thread")
    }
}
