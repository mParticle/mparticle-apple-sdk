import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPUploadGroupingTests: XCTestCase {
    private func message(id: Int64, type: String = "e") -> MPMessagePRIVATE {
        MPMessagePRIVATE(
            sessionId: nil,
            messageId: id,
            uuid: "uuid-\(id)",
            messageType: type,
            messageData: Data(#"{"dt":"\#(type)"}"#.utf8),
            timestamp: 1,
            uploadStatus: 1,
            userId: 1,
            dataPlanId: nil,
            dataPlanVersion: nil
        )
    }

    private func stored(
        mpid: NSNumber = 1,
        sessionId: NSNumber,
        dataPlanId: String,
        dataPlanVersion: NSNumber,
        messages: [Any]
    ) -> [AnyHashable: Any] {
        [mpid: [sessionId: [dataPlanId: [dataPlanVersion: messages]]]]
    }

    // MARK: - Sentinel decoding

    func testSentinelsBecomeNil() throws {
        let groups = MPUploadGrouping.groups(fromStoredMessages: stored(
            sessionId: -1,
            dataPlanId: "0",
            dataPlanVersion: 0,
            messages: [message(id: 1)]
        ))

        let group = try XCTUnwrap(groups.first)
        XCTAssertEqual(groups.count, 1)
        XCTAssertNil(group.sessionId)
        XCTAssertNil(group.dataPlanId)
        XCTAssertNil(group.dataPlanVersion)
        XCTAssertEqual(group.mpid, 1)
    }

    func testNonSentinelValuesArePreserved() throws {
        let groups = MPUploadGrouping.groups(fromStoredMessages: stored(
            mpid: 42,
            sessionId: 7,
            dataPlanId: "plan",
            dataPlanVersion: 3,
            messages: [message(id: 1)]
        ))

        let group = try XCTUnwrap(groups.first)
        XCTAssertEqual(group.mpid, 42)
        XCTAssertEqual(group.sessionId, 7)
        XCTAssertEqual(group.dataPlanId, "plan")
        XCTAssertEqual(group.dataPlanVersion, 3)
        XCTAssertEqual(group.messages.map(\.messageId), [1])
    }

    // MARK: - Flattening

    func testEveryInnermostBucketBecomesItsOwnGroup() {
        let storedMessages: [AnyHashable: Any] = [
            NSNumber(value: 1): [
                NSNumber(value: -1): ["0": [NSNumber(value: 0): [message(id: 1)]]],
                NSNumber(value: 5): ["0": [NSNumber(value: 0): [message(id: 2)]]]
            ],
            NSNumber(value: 2): [
                NSNumber(value: 9): [
                    "planA": [NSNumber(value: 1): [message(id: 3)]],
                    "planB": [NSNumber(value: 2): [message(id: 4)]]
                ]
            ]
        ]

        let groups = MPUploadGrouping.groups(fromStoredMessages: storedMessages)

        XCTAssertEqual(groups.count, 4)
        XCTAssertEqual(Set(groups.flatMap { $0.messages.map(\.messageId) }), [1, 2, 3, 4])
        XCTAssertEqual(groups.filter { $0.mpid == 2 }.count, 2)
    }

    func testEmptyBucketsStillProduceAGroup() throws {
        // The caller runs its save/delete per group, so a bucket with no messages must survive —
        // that is what the original nested enumeration did.
        let groups = MPUploadGrouping.groups(fromStoredMessages: stored(
            sessionId: 1,
            dataPlanId: "0",
            dataPlanVersion: 0,
            messages: []
        ))

        XCTAssertEqual(groups.count, 1)
        XCTAssertTrue(try XCTUnwrap(groups.first).messages.isEmpty)
    }

    // MARK: - Degenerate input

    func testNilAndEmptyProduceNoGroups() {
        XCTAssertTrue(MPUploadGrouping.groups(fromStoredMessages: nil).isEmpty)
        XCTAssertTrue(MPUploadGrouping.groups(fromStoredMessages: [:]).isEmpty)
    }

    func testMalformedNestingIsSkippedRatherThanCrashing() {
        let storedMessages: [AnyHashable: Any] = [
            NSNumber(value: 1): "not-a-dictionary",
            NSNumber(value: 2): [NSNumber(value: 1): [NSNumber(value: 9): "not-a-dictionary"]],
            NSNumber(value: 3): [NSNumber(value: 1): ["0": [NSNumber(value: 0): [message(id: 7)]]]]
        ]

        let groups = MPUploadGrouping.groups(fromStoredMessages: storedMessages)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.mpid, 3)
    }

    func testNonMessageEntriesAreDropped() throws {
        let groups = MPUploadGrouping.groups(fromStoredMessages: stored(
            sessionId: 1,
            dataPlanId: "0",
            dataPlanVersion: 0,
            messages: [message(id: 1), NSNull(), message(id: 2)]
        ))

        XCTAssertEqual(try XCTUnwrap(groups.first).messages.map(\.messageId), [1, 2])
    }
}

final class MPPreparedMessagesTests: XCTestCase {
    private func message(id: Int64, type: String, data: Data?) -> MPMessagePRIVATE {
        MPMessagePRIVATE(
            sessionId: nil,
            messageId: id,
            uuid: "uuid-\(id)",
            messageType: type,
            messageData: data,
            timestamp: 1,
            uploadStatus: 1,
            userId: 1,
            dataPlanId: nil,
            dataPlanVersion: nil
        )
    }

    func testCollectsIdsDictionariesAndDetectsOptOut() {
        let prepared = MPUploadBuilderFields.preparedMessages(from: [
            message(id: 1, type: "e", data: Data(#"{"dt":"e"}"#.utf8)),
            message(id: 2, type: "o", data: Data(#"{"dt":"o"}"#.utf8))
        ])

        XCTAssertEqual(prepared.preparedMessageIds, [1, 2])
        XCTAssertEqual(prepared.messageDictionaries.count, 2)
        XCTAssertEqual(prepared.messageDictionaries.first?["dt"] as? String, "e")
        XCTAssertTrue(prepared.containsOptOutMessage)
    }

    func testWithoutAnOptOutMessageTheFlagStaysFalse() {
        let prepared = MPUploadBuilderFields.preparedMessages(from: [
            message(id: 1, type: "e", data: Data(#"{"dt":"e"}"#.utf8))
        ])
        XCTAssertFalse(prepared.containsOptOutMessage)
    }

    func testNSNullPlaceholdersAreSkipped() {
        let prepared = MPUploadBuilderFields.preparedMessages(from: [
            NSNull(),
            message(id: 3, type: "e", data: Data(#"{"dt":"e"}"#.utf8))
        ])

        XCTAssertEqual(prepared.preparedMessageIds, [3])
        XCTAssertEqual(prepared.messageDictionaries.count, 1)
    }

    func testAMessageThatDoesNotSerializeStillContributesItsId() {
        let prepared = MPUploadBuilderFields.preparedMessages(from: [
            message(id: 4, type: "e", data: nil),
            message(id: 5, type: "e", data: Data(#"{"dt":"e"}"#.utf8))
        ])

        // Both ids are recorded so the messages are deleted after upload, but only the serializable
        // one contributes a dictionary — the two arrays are deliberately not parallel.
        XCTAssertEqual(prepared.preparedMessageIds, [4, 5])
        XCTAssertEqual(prepared.messageDictionaries.count, 1)
    }

    func testEmptyInput() {
        let prepared = MPUploadBuilderFields.preparedMessages(from: [])
        XCTAssertTrue(prepared.preparedMessageIds.isEmpty)
        XCTAssertTrue(prepared.messageDictionaries.isEmpty)
        XCTAssertFalse(prepared.containsOptOutMessage)
    }
}
