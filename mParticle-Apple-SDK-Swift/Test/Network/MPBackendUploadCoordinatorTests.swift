import Foundation
import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendUploadCoordinatorTests: XCTestCase {
    func testGroupsUsersSessionsAndPlansBeforeApplyingCountLimit() throws {
        let fixture = MPUploadCoordinatorFixture()
        let messages = (1...5).map { fixture.message(id: Int64($0)) }
        fixture.persistence.messages = [
            NSNumber(value: 1): [NSNumber(value: -1): ["0": [NSNumber(value: 0): Array(messages.prefix(3))]]],
            NSNumber(value: 2): [NSNumber(value: 7): ["plan": [
                NSNumber(value: 1): [messages[3]],
                NSNumber(value: 2): [messages[4]]
            ]]]
        ]
        fixture.coordinator.prepareBatches(forUpload: fixture.settings)
        XCTAssertEqual(fixture.persistence.transactions.count, 3)
        XCTAssertEqual(fixture.persistence.transactions.flatMap(\.uploads).count, 4)
        XCTAssertEqual(Set(fixture.persistence.transactions.flatMap { $0.messages.map(\.messageId) }), [1, 2, 3, 4, 5])
        XCTAssertEqual(
            fixture.groups.filter { $0.mpid == 2 }.map(\.dataPlanVersion).compactMap { $0 }.sorted { $0.intValue < $1.intValue },
            [1, 2]
        )
        XCTAssertTrue(fixture.groups.contains { $0.sessionId == nil && $0.dataPlanId == nil })
        XCTAssertEqual(fixture.clears, 3)
        XCTAssertEqual(fixture.persistence.cleanupCount, 1)
        XCTAssertEqual(fixture.persistence.separateSaves, 0)
        XCTAssertEqual(fixture.persistence.separateDeletes, 0)
        XCTAssertTrue(fixture.persistence.transactions.flatMap(\.uploads).allSatisfy { $0.uploadSettings === fixture.settings })
    }

    func testRejectedAndOversizedMessagesStayInSourceTransaction() {
        let fixture = MPUploadCoordinatorFixture()
        fixture.builder.transform = { _ in nil }
        let messages = [fixture.message(id: 1), fixture.message(id: 2, bytes: 2000)]
        fixture.setMessages(messages)
        fixture.coordinator.prepareBatches(forUpload: fixture.settings)
        XCTAssertEqual(fixture.persistence.transactions.first?.messages.map(\.messageId), [1, 2])
        XCTAssertEqual(fixture.persistence.transactions.first?.uploads.count, 0)
        XCTAssertEqual(fixture.clears, 1)
    }

    func testFailedTransactionRetriesOriginalMessagesWithoutCommittedDuplicate() {
        let fixture = MPUploadCoordinatorFixture()
        fixture.setMessages([fixture.message(id: 1)])
        fixture.persistence.failTransaction = true
        fixture.coordinator.prepareBatches(forUpload: fixture.settings)
        XCTAssertTrue(fixture.persistence.uploads.isEmpty)
        XCTAssertNotNil(fixture.persistence.messages)
        // The retained messages are rebatched on the next pass, so their pending user-attribute
        // deletions must still be present; clearing them here would drop `uad` from the retry.
        XCTAssertEqual(fixture.clears, 0)
        fixture.persistence.failTransaction = false
        fixture.coordinator.prepareBatches(forUpload: fixture.settings)
        fixture.coordinator.prepareBatches(forUpload: fixture.settings)
        XCTAssertEqual(fixture.persistence.uploads.count, 1)
        XCTAssertEqual(fixture.persistence.transactions.count, 2)
        XCTAssertEqual(fixture.clears, 1)
    }

    func testLivePersistenceAndInactiveSessionCleanup() {
        let fixture = MPUploadCoordinatorFixture()
        let first = fixture.persistence
        fixture.coordinator.prepareBatches(forUpload: fixture.settings)
        let replacement = MPUploadPersistenceMock()
        fixture.persistence = replacement
        fixture.coordinator.prepareBatches(forUpload: fixture.settings)
        XCTAssertEqual(first.cleanupCount, 1)
        XCTAssertEqual(replacement.cleanupCount, 1)
        XCTAssertEqual(fixture.clears, 0)
    }

    func testMultipleBatchesShareContextAndGenerateFreshHeaders() {
        let fixture = MPUploadCoordinatorFixture()
        fixture.builder.context.messageID = { UUID().uuidString }
        var timestampCalls = 0
        fixture.builder.context.timestamp = {
            timestampCalls += 1
            return NSNumber(value: timestampCalls)
        }
        fixture.setMessages((1...5).map { fixture.message(id: Int64($0)) })

        fixture.coordinator.prepareBatches(forUpload: fixture.settings)

        XCTAssertEqual(fixture.contextCreations, 1)
        XCTAssertEqual(fixture.persistence.uploads.count, 3)
        XCTAssertEqual(Set(fixture.persistence.uploads.map(\.uuid)).count, 3)
        XCTAssertEqual(timestampCalls, 3)

        fixture.setMessages([fixture.message(id: 6)])
        fixture.coordinator.prepareBatches(forUpload: fixture.settings)
        XCTAssertEqual(fixture.contextCreations, 2)
    }

    func testExplicitSettingsAreUsedBeforeWorkspaceSwitch() {
        let fixture = MPUploadCoordinatorFixture()
        let previousSettings = NSObject()
        fixture.setMessages([fixture.message(id: 1)])
        fixture.coordinator.prepareBatches(forUpload: previousSettings)
        fixture.setMessages([fixture.message(id: 2)])
        fixture.coordinator.prepareBatches(forUpload: fixture.settings)
        XCTAssertTrue(fixture.persistence.uploads.first?.uploadSettings === previousSettings)
        XCTAssertTrue(fixture.persistence.uploads.last?.uploadSettings === fixture.settings)
    }

    func testBatchByteAndCrashLimits() {
        let fixture = MPUploadCoordinatorFixture()
        let limits = MPUploadBatchLimits(
            maxMessages: 10,
            maxBatchBytes: 20,
            maxMessageBytes: 15,
            crashBatchBytes: 80,
            crashMessageBytes: 60
        )
        let messages = [
            fixture.message(id: 1, bytes: 12),
            fixture.message(id: 2, bytes: 12),
            fixture.message(id: 3, bytes: 30),
            fixture.message(id: 4, bytes: 50, type: "x"),
            fixture.message(id: 5, bytes: 90, type: "x")
        ]
        let batches = fixture.coordinator.batchMessages(messages, limits: limits)
        XCTAssertEqual(batches.flatMap { $0.map(\.messageId) }, [1, 2, 4])
        XCTAssertEqual(batches.first?.map(\.messageId), [1])
    }
}

final class MPUploadCoordinatorFixture {
    let builder = MPUploadTestFixture()
    var persistence = MPUploadPersistenceMock()
    var settings = NSObject()
    var network = MPBackendUploadNetworkMock()
    var kitsDelayed = false
    var webDelayed = false
    var kitChecks = 0
    var webChecks = 0
    var scheduled: [() -> Void] = []
    var delays: [TimeInterval] = []
    var clears = 0
    var contextCreations = 0
    var groups: [MPUploadMessageGroup] = []
    lazy var coordinator = MPBackendUploadCoordinator(
        persistence: { [unowned self] in persistence },
        stateMachine: { [unowned self] in builder.state },
        makeContext: { [unowned self] in
            contextCreations += 1
            return builder.context
        },
        makeBuilder: { [unowned self] group, messages, settings, context in
            XCTAssertTrue(context === builder.context)
            groups.append(group)
            return builder.builder(
                sessionId: group.sessionId,
                messages: messages,
                planId: group.dataPlanId,
                planVersion: group.dataPlanVersion,
                settings: settings
            )
        },
        clearDeletedAttributes: { [unowned self] in clears += 1 },
        limits: MPUploadBatchLimits(
            maxMessages: 2,
            maxBatchBytes: 1000,
            maxMessageBytes: 500,
            crashBatchBytes: 1500,
            crashMessageBytes: 1000
        ),
        dependencies: MPBackendUploadDependencies(
            network: { [unowned self] in network },
            shouldDelayForKits: { [unowned self] in kitChecks += 1; return kitsDelayed },
            shouldDelayForWebView: { [unowned self] in webChecks += 1; return webDelayed },
            schedule: { [unowned self] delay, action in delays.append(delay); scheduled.append(action) },
            logger: { nil }
        ),
        currentSettings: { [unowned self] in settings }
    )

    func message(id: Int64, bytes: Int? = nil, type: String = "e") -> MPMessagePRIVATE {
        MPMessagePRIVATE(sessionId: nil, messageId: id, uuid: "message-\(id)", messageType: type,
                         messageData: bytes.map { Data(repeating: 32, count: $0) } ?? Data(#"{"dt":"e"}"#.utf8),
                         timestamp: 1, uploadStatus: 1, userId: 1, dataPlanId: nil, dataPlanVersion: nil)
    }

    func setMessages(_ messages: [MPMessagePRIVATE]) {
        persistence.messages = [NSNumber(value: 1): [NSNumber(value: -1): ["0": [NSNumber(value: 0): messages]]]]
    }
}

final class MPUploadPersistenceMock: NSObject, MPBackendPersistence {
    struct Transaction {
        let uploads: [MPUploadPRIVATE]
        let messages: [MPMessagePRIVATE]
        let optedOut: Bool
    }
    var messages: NSMutableDictionary?
    var uploads: [MPUploadPRIVATE] = []
    var transactions: [Transaction] = []
    var failTransaction = false
    var cleanupCount = 0
    var separateSaves = 0
    var separateDeletes = 0
    var networkPerformanceDeletes = 0
    var deletedUploads: [MPUploadPRIVATE] = []

    func objectiveCSaveUploads(_ uploads: [MPUploadPRIVATE], deleteMessages messages: [MPMessagePRIVATE],
                               optedOut: Bool) -> Bool {
        transactions.append(Transaction(uploads: uploads, messages: messages, optedOut: optedOut))
        guard !failTransaction else { return false }
        self.uploads.append(contentsOf: uploads)
        self.messages = nil
        return true
    }
    func objectiveCFetchMessagesForUploading() -> NSMutableDictionary? { messages }
    func objectiveCFetchUploads() -> NSArray? { uploads as NSArray }
    func objectiveCDeleteAllSessions(except _: MPSessionPRIVATE?) { cleanupCount += 1 }
    func objectiveCSaveUpload(_: MPUploadPRIVATE, optedOut _: Bool) { separateSaves += 1 }
    func objectiveCDeleteMessages(_: [MPMessagePRIVATE]) { separateDeletes += 1 }
    func objectiveCDeleteUpload(_ upload: MPUploadPRIVATE) { deletedUploads.append(upload) }
    func objectiveCDeleteNetworkPerformanceMessages() { networkPerformanceDeletes += 1 }
    func objectiveCDatabaseOpen() -> Bool { true }
    func objectiveCOpenDatabase() -> Bool { true }
    func objectiveCCloseDatabase() -> Bool { true }
    func objectiveCPurgeMemory() {}
    func objectiveCDeleteRecords(olderThan _: TimeInterval) {}
    func objectiveCSaveSession(_: MPSessionPRIVATE) {}
    func objectiveCUpdateSession(_: MPSessionPRIVATE) {}
    func objectiveCFetchSessions() -> NSMutableArray? { nil }
    func objectiveCFetchPossibleSessionsFromCrash() -> NSArray? { nil }
    func objectiveCArchiveSession(_: MPSessionPRIVATE) -> MPSessionPRIVATE? { nil }
    func objectiveCFetchPreviousSession() -> MPSessionPRIVATE? { nil }
    func objectiveCDeletePreviousSession() {}
    func objectiveCDeleteSession(_: MPSessionPRIVATE) {}
    func objectiveCAppAndDeviceInfo(forSessionId _: NSNumber) -> NSDictionary { [:] }
    func objectiveCFetchForwardRecords() -> NSArray? { nil }
    func objectiveCDeleteForwardRecords(ids _: [NSNumber]) {}
    func objectiveCFetchIntegrationAttributes() -> NSArray? { nil }
    func objectiveCSaveMessage(_: MPMessagePRIVATE) {}
    func objectiveCFetchSessionEndMessage(in _: MPSessionPRIVATE) -> MPMessagePRIVATE? { nil }
    func objectiveCFetchUploadedMessages(in _: MPSessionPRIVATE) -> NSArray? { nil }
    func objectiveCSaveBreadcrumb(_: MPMessagePRIVATE) {}
    func objectiveCFetchBreadcrumbs() -> NSArray? { nil }
    func objectiveCDeleteUpload(id _: Int64) {}
}
