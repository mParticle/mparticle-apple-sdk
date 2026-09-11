import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPDataModelTests: XCTestCase {
    func testJSONCopyCopiesNestedContainers() {
        let nested = NSMutableDictionary(dictionary: ["inner": "value"])
        let original = NSMutableDictionary(dictionary: ["outer": nested, "count": 1])

        let copied = MPJSONCopyPRIVATE.deepCopyJSONObject(original) as? NSDictionary
        XCTAssertEqual(copied?["count"] as? Int, 1)
        XCTAssertEqual((copied?["outer"] as? NSDictionary)?["inner"] as? String, "value")

        nested["inner"] = "changed"
        XCTAssertEqual((copied?["outer"] as? NSDictionary)?["inner"] as? String, "value")
    }

    func testJSONCopyDropsNonJSONValues() {
        let original = ["ok": "yes", "bad": Date()] as NSDictionary
        let copied = MPJSONCopyPRIVATE.deepCopyJSONObject(original) as? NSDictionary
        XCTAssertEqual(copied?["ok"] as? String, "yes")
        XCTAssertNil(copied?["bad"])
    }

    func testFixInvalidKeysRemovesNonFiniteNumbers() {
        let inf = NSNumber(value: Double.infinity)
        let messageInfo: NSDictionary = [
            "ok": "keep",
            "bad": inf,
            "nested": ["child": inf, "ok": "nested"]
        ]
        let dictionary = NSMutableDictionary(dictionary: messageInfo)

        MPMessagePRIVATE.fixInvalidKeys(dictionary, messageInfo: messageInfo)

        XCTAssertEqual(dictionary["ok"] as? String, "keep")
        XCTAssertNil(dictionary["bad"])
        XCTAssertEqual((dictionary["nested"] as? NSDictionary)?["ok"] as? String, "nested")
        XCTAssertNil((dictionary["nested"] as? NSDictionary)?["child"])
    }

    func testTruncateDoesNotApplyNegativeLength() {
        guard let payload = try? JSONSerialization.data(
            withJSONObject: ["hardwareId": "IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"],
            options: []
        ) else {
            XCTFail("Expected hardwareId payload to serialize")
            return
        }
        let message = MPMessagePRIVATE(
            sessionId: 17,
            messageId: 1,
            uuid: "uuid",
            messageType: "test",
            messageData: payload,
            timestamp: 1,
            uploadStatus: 0,
            userId: 1,
            dataPlanId: nil,
            dataPlanVersion: nil
        )

        message.truncateMessageDataProperty("hardwareId", toLength: -1)
        guard let messageData = message.messageData,
              let json = try? JSONSerialization.jsonObject(with: messageData, options: []) as? NSDictionary else {
            XCTFail("Expected message data to deserialize after negative-length truncate")
            return
        }
        XCTAssertEqual((json["hardwareId"] as? String)?.count, 41)

        message.truncateMessageDataProperty("hardwareId", toLength: 5)
        guard let truncatedData = message.messageData,
              let truncated = try? JSONSerialization.jsonObject(with: truncatedData, options: []) as? NSDictionary else {
            XCTFail("Expected message data to deserialize after truncate")
            return
        }
        XCTAssertEqual((truncated["hardwareId"] as? String)?.count, 5)
    }

    func testDefaultSessionInitUsesStoredMpId() {
        let defaults = MPUserDefaults.standardUserDefaults(connector: MPUserDefaultsConnectorMock())
        let previous = defaults["mpid"]
        defaults["mpid"] = 99
        defer {
            if let previous {
                defaults["mpid"] = previous
            } else {
                defaults.setMPObject(nil, forKey: "mpid", userId: 0)
            }
        }

        let session = MPSessionPRIVATE()
        XCTAssertEqual(session.userId, 99)
        XCTAssertEqual(session.sessionUserIds, "99")
    }

    func testSessionCounterAndSuspend() {
        let session = MPSessionPRIVATE(
            sessionId: 0,
            uuid: "uuid",
            backgroundTime: 0,
            startTime: 1,
            endTime: 1,
            attributes: nil,
            numberOfInterruptions: 0,
            eventCounter: 0,
            suspendTime: 0,
            userId: 1,
            sessionUserIds: "1",
            applicationInfo: nil,
            deviceInfo: nil
        )
        XCTAssertFalse(session.persisted)
        session.incrementCounter()
        XCTAssertEqual(session.eventCounter, 1)
        session.suspendSession()
        XCTAssertEqual(session.numberOfInterruptions, 1)
        XCTAssertGreaterThan(session.suspendTime, 0)
    }

    func testCookieExpiredWithoutExpiration() {
        let cookie = MPCookiePRIVATE(name: "uid", configuration: ["c": "g=abc"])
        XCTAssertNotNil(cookie)
        XCTAssertTrue(cookie?.expired ?? false)
    }

    func testCookieNotExpiredWithUnparseableDate() {
        let cookie = MPCookiePRIVATE(name: "uid", configuration: ["e": "not-a-date"])
        XCTAssertNotNil(cookie)
        XCTAssertFalse(cookie?.expired ?? true)
    }

    func testIntegrationAttributesRejectsEmptyOrNonStringValues() {
        XCTAssertNil(MPIntegrationAttributesPRIVATE(integrationId: 42, attributes: [:]))
        XCTAssertNil(MPIntegrationAttributesPRIVATE(integrationId: 42, attributes: ["a": 1]))
        let valid = MPIntegrationAttributesPRIVATE(integrationId: 42, attributes: ["a": "b"])
        XCTAssertEqual(valid?.dictionaryRepresentation() as? [String: [String: String]], ["42": ["a": "b"]])
    }

    func testUploadSerializationUsesJSONCopy() {
        let dictionary: NSDictionary = ["id": "upload-id", "ct": 1]
        guard let data = MPUploadPRIVATE.serializedUpload(from: dictionary) else {
            XCTFail("Expected upload dictionary to serialize")
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary else {
            XCTFail("Expected serialized upload to deserialize")
            return
        }
        XCTAssertEqual(json["id"] as? String, "upload-id")
    }

    func testForwardRecordNilDictionaryIsNotEqual() {
        let left = MPForwardRecordPRIVATE(recordId: 1, dataDictionary: nil, mpid: 7)
        let right = MPForwardRecordPRIVATE(recordId: 1, dataDictionary: nil, mpid: 7)
        XCTAssertFalse(left.isEqual(toRecord: right))
        XCTAssertNil(left.dataRepresentation())
    }

    func testUploadInitAcceptsNilUUID() {
        let upload = MPUploadPRIVATE(
            sessionId: nil,
            uploadId: 0,
            uuid: nil,
            uploadData: Data(),
            timestamp: 1,
            uploadType: 0,
            dataPlanId: nil,
            dataPlanVersion: nil,
            uploadSettings: NSObject()
        )
        XCTAssertNil(upload.uuid)
    }

    func testNilMessagePayloadStaysNil() {
        let message = MPMessagePRIVATE(
            sessionId: nil,
            messageId: 1,
            uuid: nil,
            messageType: "e",
            messageData: nil,
            timestamp: 1,
            uploadStatus: 0,
            userId: 1,
            dataPlanId: nil,
            dataPlanVersion: nil
        )
        XCTAssertNil(message.uuid)
        XCTAssertNil(message.messageData)
        XCTAssertNil(message.serializedString())
        XCTAssertNil(message.dictionaryRepresentation())

        let other = MPMessagePRIVATE(
            sessionId: nil,
            messageId: 1,
            uuid: nil,
            messageType: "e",
            messageData: nil,
            timestamp: 1,
            uploadStatus: 0,
            userId: 1,
            dataPlanId: nil,
            dataPlanVersion: nil
        )
        XCTAssertFalse(message.isEqual(toMessage: other))
    }

    func testNilBreadcrumbPayloadStaysNil() {
        let breadcrumb = MPBreadcrumbPRIVATE(
            sessionUUID: nil,
            breadcrumbId: 1,
            uuid: nil,
            breadcrumbData: nil,
            timestamp: 1
        )
        XCTAssertNil(breadcrumb.uuid)
        XCTAssertNil(breadcrumb.sessionUUID)
        XCTAssertNil(breadcrumb.breadcrumbData)
        XCTAssertNil(breadcrumb.content)
        XCTAssertNil(breadcrumb.serializedString())

        let other = MPBreadcrumbPRIVATE(
            sessionUUID: nil,
            breadcrumbId: 1,
            uuid: nil,
            breadcrumbData: nil,
            timestamp: 1
        )
        XCTAssertFalse(breadcrumb.isEqual(toBreadcrumb: other))
    }

    // MARK: - MPCookie as the Objective-C MPCookie

    func testCookieKeepsTheObjectiveCRuntimeName() {
        XCTAssertEqual(NSStringFromClass(MPCookiePRIVATE.self), "MPCookie")
    }

    func testCookieEqualityIsByNameAndRejectsForeignTypes() {
        let cookie = MPCookiePRIVATE(name: "uid", configuration: ["c": "g=abc"])
        let sameName = MPCookiePRIVATE(name: "uid", configuration: ["c": "different"])
        let otherName = MPCookiePRIVATE(name: "rpl", configuration: ["c": "g=abc"])

        XCTAssertEqual(cookie, sameName)
        XCTAssertNotEqual(cookie, otherName)
        XCTAssertFalse(cookie?.isEqual("a string is not a cookie") ?? true)
        XCTAssertFalse(cookie?.isEqual(NSNull()) ?? true)
        XCTAssertFalse(cookie?.isEqual(nil) ?? true)
    }

    func testCookieDictionaryRepresentationIsNilWhenNothingIsSet() {
        let cookie = MPCookiePRIVATE(name: "uid", configuration: [:])
        XCTAssertNotNil(cookie)
        XCTAssertNil(cookie?.dictionaryRepresentation())
    }

    /// Pins the ported defect rather than endorsing it: `content`, `domain` and `expiration` are
    /// encoded as strings but decoded expecting `NSDictionary`, so only the name survives.
    /// No production path archives a cookie, and equality is by name, so the loss is invisible
    /// even to `MPConsumerInfoTests`, which does archive cookies through `MPConsumerInfo` but
    /// asserts only `uniqueIdentifier`. Change this test the day the decode is repaired.
    func testCookieArchiveRoundTripKeepsOnlyTheName() throws {
        let cookie = try XCTUnwrap(MPCookiePRIVATE(name: "uid",
                                                   configuration: ["c": "g=abc", "d": "example.com",
                                                                   "e": "2035-05-26T22:43:31.505262Z"]))

        let data = try NSKeyedArchiver.archivedData(withRootObject: cookie, requiringSecureCoding: false)
        let restored = try XCTUnwrap(NSKeyedUnarchiver.unarchivedObject(ofClass: MPCookiePRIVATE.self, from: data))

        XCTAssertEqual(restored.name, "uid")
        XCTAssertEqual(restored, cookie, "equality is by name, which is why the loss below is invisible")
        XCTAssertNil(restored.content)
        XCTAssertNil(restored.domain)
        XCTAssertNil(restored.expiration)
    }
}
