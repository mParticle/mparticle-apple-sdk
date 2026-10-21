import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendMessageLoggerTests: XCTestCase {
    private var host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
    private var owner: MPBackendFakeOwner!
    private var state = MPBackendSessionState()
    private var assembly: MPBackendAssembly!

    override func setUp() {
        super.setUp()
        host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
        owner = MPBackendFakeOwner(host: host)
        state = MPBackendSessionState()
        state.session = MPSessionPRIVATE(startTime: 100, userId: 1)
        assembly = MPBackendAssembly(state: state, host: host, owner: owner)
    }

    override func tearDown() {
        _ = DeviceTokenStore.shared.adopt(persistedToken: nil)
        assembly.lifecycleCoordinator.endUploadTimer()
        super.tearDown()
    }

    private var logger: MPBackendMessageLogger { assembly.messageLogger }

    private func drainMessageQueue() {
        host.queue.sync {}
    }

    private struct SavedMessage {
        let type: String?
        let body: [String: Any]
        let updateSession: Bool
    }

    private func saved() -> [SavedMessage] {
        owner.savedMessages.map { message, updateSession in
            let body = message.messageData.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
            return SavedMessage(type: message.messageType, body: body ?? [:], updateSession: updateSession)
        }
    }

    private func tokenNotification(_ userInfo: [AnyHashable: Any]) -> Notification {
        Notification(name: Notification.Name("MPRemoteNotificationDeviceTokenNotification"), object: nil, userInfo: userInfo)
    }

    func testOptingOutStoresTheChoiceAndSavesTheOptOutMessage() {
        for optOut in [true, false] {
            let reported = expectation(description: "opt-out reported")
            logger.setOptOut(optOut) { reportedOptOut, status in
                XCTAssertEqual(reportedOptOut, optOut)
                XCTAssertEqual(status, .success)
                reported.fulfill()
            }
            wait(for: [reported], timeout: 5)
            XCTAssertEqual(host.machine.optOut, optOut)
        }

        XCTAssertEqual(saved().map(\.type), ["o", "o"])
        XCTAssertEqual(saved().map { $0.body["s"] as? String }, ["true", "false"])
        XCTAssertEqual(saved().map(\.updateSession), [true, true])
    }

    func testANetworkPerformanceMeasurementIsSavedAndReported() {
        let measurement = MPNetworkPerformance(
            urlRequest: URLRequest(url: URL(string: "https://example.com/path")!), networkMeasurementMode: .exclude
        )
        var reported: (MPNetworkPerformance, MPExecStatus)?

        logger.logNetworkPerformance(measurement) { reported = ($0, $1) }

        XCTAssertTrue(reported?.0 === measurement)
        XCTAssertEqual(reported?.1, .success)
        XCTAssertEqual(saved().map(\.type), ["npe"])
        XCTAssertEqual(saved().first?.updateSession, true)
    }

    func testANewDeviceTokenSavesAnEnabledPushRegistration() {
        host.machine.deviceTokenType = "development"

        logger.handleDeviceTokenNotification(tokenNotification(["MPRemoteNotificationDeviceTokenKey": Data([0xAB, 0xCD])]))
        drainMessageQueue()

        XCTAssertEqual(saved().map(\.type), ["pr"])
        let body = saved().first?.body ?? [:]
        XCTAssertEqual(body["r"] as? String, "true")
        XCTAssertEqual(body["to"] as? String, "abcd")
        XCTAssertEqual(body["tot"] as? String, "development")
        XCTAssertEqual(saved().first?.updateSession, true)
    }

    func testAClearedDeviceTokenSavesTheOldTokenAsDisabled() {
        host.machine.deviceTokenType = ""

        logger.handleDeviceTokenNotification(tokenNotification(["MPRemoteNotificationOldDeviceTokenKey": Data([0x01, 0x02])]))
        drainMessageQueue()

        let body = saved().first?.body ?? [:]
        XCTAssertEqual(body["r"] as? String, "false")
        XCTAssertEqual(body["to"] as? String, "0102")
        XCTAssertNil(body["tot"])
    }

    func testAnUnchangedOrMissingDeviceTokenSavesNothing() {
        let token = Data([0xAB])
        logger.handleDeviceTokenNotification(tokenNotification([
            "MPRemoteNotificationDeviceTokenKey": token, "MPRemoteNotificationOldDeviceTokenKey": token
        ]))
        logger.handleDeviceTokenNotification(tokenNotification([:]))
        drainMessageQueue()

        XCTAssertTrue(saved().isEmpty)
    }

    func testAUserNotificationIsSavedWithTheStoredDeviceToken() {
        host.defaults["to"] = Data([0x0A, 0x0B])
        let notification = MParticleUserNotificationPRIVATE(
            dictionary: ["aps": ["alert": "Hello"]], state: "foreground", behavior: 2, mode: 1
        )
        notification.actionTitle = "Open"
        notification.actionIdentifier = "open"

        logger.logUserNotification(notification)
        drainMessageQueue()

        XCTAssertEqual(saved().map(\.type), ["pm"])
        let body = saved().first?.body ?? [:]
        XCTAssertEqual(body["as"] as? String, "foreground")
        XCTAssertEqual(body["n"] as? String, "apn")
        XCTAssertEqual(body["t"] as? String, notification.type)
        XCTAssertEqual(body["to"] as? String, "0a0b")
        XCTAssertEqual(body["an"] as? String, "Open")
        XCTAssertEqual(body["aid"] as? String, "open")
        XCTAssertEqual(body["bhv"] as? Int, 2)
        XCTAssertEqual(body["pay"] as? String, notification.redactedUserNotificationString)
        XCTAssertEqual(saved().first?.updateSession, true)
    }

    func testAUserNotificationWithoutASessionOrOptionalFieldsSavesOnlyTheRequiredKeys() {
        state.session = nil
        let notification = MParticleUserNotificationPRIVATE(dictionary: nil, state: "background", behavior: 0, mode: 1)

        logger.logUserNotification(notification)
        drainMessageQueue()

        let body = saved().first?.body ?? [:]
        XCTAssertEqual(body["as"] as? String, "background")
        for key in ["to", "an", "aid", "bhv", "pay"] {
            XCTAssertNil(body[key], key)
        }
        XCTAssertEqual(saved().first?.updateSession, false)
    }

    func testFetchingAudiencesHandsTheNetworkResultToTheCompletionHandler() {
        let network = MPBackendUploadNetworkMock()
        network.audiences = ["first"]
        owner.network = network
        var received: [Any]?
        var completions = 0

        logger.fetchAudiences { audiences, error in
            received = audiences
            XCTAssertNil(error)
            completions += 1
        }

        XCTAssertEqual(network.audienceRequests, 1)
        XCTAssertEqual(completions, 1)
        XCTAssertEqual(received as? [String], ["first"])
    }

    func testAFailedAudienceRequestPassesItsErrorThrough() {
        let network = MPBackendUploadNetworkMock()
        let failure = NSError(domain: "test", code: 7)
        network.audienceSuccess = false
        network.audienceError = failure
        owner.network = network
        var receivedError: Error?

        logger.fetchAudiences { audiences, error in
            XCTAssertNil(audiences)
            receivedError = error
        }

        XCTAssertEqual((receivedError as NSError?)?.code, 7)
    }

    func testQueuedWorkKeepsTheControllerUntilTheMessageIsSaved() {
        var transient: MPBackendFakeOwner? = MPBackendFakeOwner(host: host)
        weak var released = transient
        var savedTypes: [String?] = []
        transient?.onSave = { savedTypes.append($0.messageType) }
        let transientAssembly = MPBackendAssembly(state: state, host: host, owner: transient!)
        let queueBlocked = DispatchSemaphore(value: 0)
        host.queue.async { queueBlocked.wait() }

        transientAssembly.messageLogger.handleDeviceTokenNotification(
            tokenNotification(["MPRemoteNotificationDeviceTokenKey": Data([0xAB])])
        )
        transient = nil
        XCTAssertNotNil(released, "queued work holds the controller until it runs")
        queueBlocked.signal()
        drainMessageQueue()

        XCTAssertEqual(savedTypes, ["pr"])
        XCTAssertNil(released)
        transientAssembly.lifecycleCoordinator.endUploadTimer()
    }
}
