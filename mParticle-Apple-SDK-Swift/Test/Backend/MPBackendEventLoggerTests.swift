import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendEventLoggerTests: XCTestCase {
    private var host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
    private var owner: MPBackendFakeOwner!
    private var state = MPBackendSessionState()
    private var assembly: MPBackendAssembly!
    private let persistence = MPBackendRecordingPersistence()

    override func setUp() {
        super.setUp()
        host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
        host.persistenceValue = persistence
        owner = MPBackendFakeOwner(host: host)
        owner.persistenceValue = persistence
        state = MPBackendSessionState()
        assembly = MPBackendAssembly(state: state, host: host, owner: owner)
    }

    override func tearDown() {
        assembly.lifecycleCoordinator.endUploadTimer()
        super.tearDown()
    }

    private var logger: MPBackendEventLogger { assembly.eventLogger }

    private func body(of message: MPMessagePRIVATE) -> [String: Any] {
        message.messageData.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any] ?? [:]
    }

    func testAnEventMessageIsSavedThroughTheControllerAndCounted() throws {
        let session = MPSessionPRIVATE(startTime: 100, userId: 1)
        state.session = session
        var countWhenSaved: UInt32?
        owner.onSave = { _ in countWhenSaved = session.eventCounter }

        logger.saveEventMessage(
            ofType: MPMessageTypeSwift.event.rawValue, messageInfo: ["n": "Purchase"],
            timestamp: Date(timeIntervalSince1970: 500), shouldUploadEvent: false
        )

        let saved = try XCTUnwrap(owner.savedMessages.first)
        XCTAssertEqual(owner.savedMessages.count, 1)
        XCTAssertEqual(saved.message.messageType, "e")
        XCTAssertEqual(body(of: saved.message)["n"] as? String, "Purchase")
        XCTAssertEqual((body(of: saved.message)["ct"] as? NSNumber)?.doubleValue, 500_000)
        XCTAssertFalse(saved.message.shouldUploadEvent)
        XCTAssertTrue(saved.updateSession)
        XCTAssertEqual(countWhenSaved, 0, "the message is saved before the session counts it")
        XCTAssertEqual(session.eventCounter, 1)
    }

    func testWithoutATimestampTheMessageKeepsTheBuildTime() throws {
        state.session = MPSessionPRIVATE(startTime: 100, userId: 1)
        let before = Date().timeIntervalSince1970 * 1000

        logger.saveEventMessage(
            ofType: MPMessageTypeSwift.breadcrumb.rawValue, messageInfo: nil, timestamp: nil, shouldUploadEvent: true
        )

        let saved = try XCTUnwrap(owner.savedMessages.first)
        XCTAssertEqual(saved.message.messageType, "bc")
        XCTAssertGreaterThanOrEqual((body(of: saved.message)["ct"] as? NSNumber)?.doubleValue ?? 0, before.rounded(.down))
        XCTAssertTrue(saved.message.shouldUploadEvent)
    }

    func testAnEventWithoutASessionIsStillSaved() {
        logger.saveEventMessage(
            ofType: MPMessageTypeSwift.screenView.rawValue, messageInfo: ["n": "Home"], timestamp: nil, shouldUploadEvent: true
        )

        XCTAssertEqual(owner.savedMessages.map(\.message.messageType), ["v"])
        XCTAssertNil(state.session)
    }

    func testAnEventThatBeginsASessionBeginsAManualOneWhenTrackingIsOff() {
        host.tracksSessionsAutomatically = false

        logger.beginSession(forEventAt: Date(timeIntervalSince1970: 1000))
        host.queue.sync {}

        XCTAssertNotNil(state.session)
        XCTAssertEqual(state.session?.startTime, 1000)
    }
}
