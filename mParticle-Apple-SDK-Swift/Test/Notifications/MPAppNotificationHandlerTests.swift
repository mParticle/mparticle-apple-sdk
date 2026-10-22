import UIKit
import XCTest
@testable import mParticle_Apple_SDK_Swift
#if os(iOS)
import UserNotifications
#endif

private final class RecordingNotificationController: MPNotificationControllerProtocol {
    private let record: (String) -> Void
    private(set) var tokens: [Data?] = []

    init(record: @escaping (String) -> Void) {
        self.record = record
    }

    #if os(iOS)
    func deviceToken() -> Data? {
        nil
    }

    func setDeviceToken(_ devToken: Data?) {
        tokens.append(devToken)
        record("setDeviceToken")
    }
    #endif
}

/// Records each side effect with the thread it ran on, in order.
private final class FakeAppNotificationHost: NSObject, MPAppNotificationHost {
    struct Forward {
        let selector: String
        let parameters: [Any?]
        let messageType: MPMessageTypeSwift
        let userInfo: [AnyHashable: Any]?
    }

    var isOptedOut = false
    var isInAppExtension = false
    var tracksNotifications = true
    var kitRespondsToSelector = true

    private(set) var events: [String] = []
    private(set) var forwards: [Forward] = []
    private(set) var launchInfos: [MPLaunchInfo] = []
    private(set) var respondsQueries: [String] = []
    private(set) var loggedNotifications: [(userInfo: [AnyHashable: Any], actionIdentifier: String?)] = []
    private(set) var forwardedNotificationCenterObjects: [AnyObject] = []
    private(set) lazy var controller = RecordingNotificationController { [unowned self] in record($0) }

    let logger = MPLog(logLevel: .none)

    private func record(_ event: String) {
        events.append("\(event) on \(Thread.isMainThread ? "main" : "caller")")
    }

    func optOut() -> Bool {
        isOptedOut
    }

    func setLaunchInfo(_ launchInfo: MPLaunchInfo) {
        launchInfos.append(launchInfo)
        record("setLaunchInfo")
    }

    func forwardSDKCall(
        _ selector: Selector,
        parameters: MPForwardQueueParameters,
        messageType: MPMessageTypeSwift,
        userInfo: [AnyHashable: Any]?
    ) {
        let values = (0..<Int(parameters.count)).map { parameters[$0] }
        forwards.append(Forward(selector: NSStringFromSelector(selector), parameters: values,
                                messageType: messageType, userInfo: userInfo))
        record("forward \(NSStringFromSelector(selector))")
    }

    func registeredKitResponds(to selector: Selector) -> Bool {
        respondsQueries.append(NSStringFromSelector(selector))
        record("registeredKitResponds")
        return kitRespondsToSelector
    }

    #if os(iOS)
    func isAppExtension() -> Bool {
        isInAppExtension
    }

    func trackNotifications() -> Bool {
        tracksNotifications
    }

    func notificationController() -> MPNotificationControllerProtocol {
        controller
    }

    func logNotificationReceived(userInfo: [AnyHashable: Any]) {
        loggedNotifications.append((userInfo, nil))
        record("logReceived")
    }

    func logNotificationOpened(userInfo: [AnyHashable: Any], actionIdentifier: String?) {
        loggedNotifications.append((userInfo, actionIdentifier))
        record("logOpened")
    }

    func forwardUserNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) {
        forwardedNotificationCenterObjects = [center, notification]
        record("forwardWillPresent")
    }

    func forwardUserNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) {
        forwardedNotificationCenterObjects = [center, response]
        record("forwardDidReceive")
    }
    #endif
}

#if os(iOS)
/// UNNotification and UNNotificationResponse have no public initializer, so these decode from an
/// empty archive and supply their contents by override.
private final class FakeNotification: UNNotification {
    private var fakeRequest: UNNotificationRequest?

    override var request: UNNotificationRequest {
        fakeRequest ?? super.request
    }

    static func make(userInfo: [AnyHashable: Any]) throws -> FakeNotification {
        let notification = try XCTUnwrap(FakeNotification(coder: emptyArchive()))
        let content = UNMutableNotificationContent()
        content.userInfo = userInfo
        notification.fakeRequest = UNNotificationRequest(identifier: "test", content: content, trigger: nil)
        return notification
    }
}

private final class FakeNotificationResponse: UNNotificationResponse {
    private var fakeNotification: UNNotification?
    private var fakeActionIdentifier = ""

    override var notification: UNNotification {
        fakeNotification ?? super.notification
    }

    override var actionIdentifier: String {
        fakeActionIdentifier
    }

    static func make(userInfo: [AnyHashable: Any], actionIdentifier: String) throws -> FakeNotificationResponse {
        let response = try XCTUnwrap(FakeNotificationResponse(coder: emptyArchive()))
        response.fakeNotification = try FakeNotification.make(userInfo: userInfo)
        response.fakeActionIdentifier = actionIdentifier
        return response
    }
}

private func emptyArchive() throws -> NSKeyedUnarchiver {
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    archiver.finishEncoding()
    return try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
}

/// UNUserNotificationCenter.current() needs a host app, which this test bundle does not have. The
/// handler only passes the center through, so an instance that was never initialised is enough; it
/// is kept for the life of the process so it is never deallocated.
private let notificationCenter = class_createInstance(UNUserNotificationCenter.self, 0) as! UNUserNotificationCenter
#endif

final class MPAppNotificationHandlerTests: XCTestCase {
    private var host: FakeAppNotificationHost!
    private var handler: MPAppNotificationHandler!

    override func setUp() {
        super.setUp()
        host = FakeAppNotificationHost()
        handler = MPAppNotificationHandler(host: host)
    }

    /// Runs `body` off the main thread, then lets the main queue run what it scheduled.
    private func callFromBackground(_ body: @escaping () -> Void) {
        let called = expectation(description: "called from a background queue")
        DispatchQueue.global().async {
            body()
            called.fulfill()
        }
        wait(for: [called], timeout: 5)

        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 5)
    }

    // MARK: - Opt-out

    func testOptOutStopsEveryCallback() throws {
        host.isOptedOut = true
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        var continued = true

        callFromBackground { [handler] in
            guard let handler else { return }
            continued = handler.continue(NSUserActivity(activityType: "test")) { _ in }
            handler.open(url, options: nil)
            #if os(iOS)
            handler.didFailToRegisterForRemoteNotificationsWithError(nil)
            handler.didRegisterForRemoteNotifications(withDeviceToken: Data([1]))
            handler.handleAction(withIdentifier: "action", forRemoteNotification: [:])
            handler.handleAction(withIdentifier: "action", forRemoteNotification: [:], withResponseInfo: [:])
            handler.didReceiveRemoteNotification(["aps": ["content-available": 1]])
            #endif
        }
        #if os(iOS)
        let notification = try FakeNotification.make(userInfo: ["aps": ["alert": "hi"]])
        let response = try FakeNotificationResponse.make(userInfo: ["aps": ["alert": "hi"]],
                                                         actionIdentifier: UNNotificationDefaultActionIdentifier)
        callFromBackground { [handler] in
            handler?.userNotificationCenter(notificationCenter, willPresent: notification)
            handler?.userNotificationCenter(notificationCenter, didReceive: response)
        }
        #endif

        XCTAssertFalse(continued)
        XCTAssertEqual(host.events, [])
    }

    // MARK: - URLs and user activities

    func testOpenURLSetsTheLaunchInfoThenForwardsOnTheMainQueue() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/path"))
        let options: [String: Any] = ["UIApplicationOpenURLOptionsSourceApplicationKey": "com.example.source"]

        callFromBackground { [handler] in handler?.open(url, options: options) }

        XCTAssertEqual(host.events, ["setLaunchInfo on caller", "forward openURL:options: on main"])
        XCTAssertEqual(host.launchInfos.first?.url, url)
        XCTAssertEqual(host.launchInfos.first?.sourceApplication, "com.example.source")
        let forward = try XCTUnwrap(host.forwards.first)
        XCTAssertEqual(forward.messageType, .unknown)
        XCTAssertNil(forward.userInfo)
        XCTAssertEqual(forward.parameters.count, 2)
        XCTAssertEqual(forward.parameters[0] as? URL, url)
        XCTAssertEqual(forward.parameters[1] as? [String: String],
                       ["UIApplicationOpenURLOptionsSourceApplicationKey": "com.example.source"])
    }

    func testOpenURLForwardsMissingOptionsAsNil() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))

        callFromBackground { [handler] in handler?.open(url, options: nil) }

        let parameters = try XCTUnwrap(host.forwards.first?.parameters)
        XCTAssertEqual(parameters.count, 2)
        XCTAssertNil(parameters[1])
    }

    func testContinueUserActivityForwardsABlockAndReportsWhetherAKitCanHandleIt() throws {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://example.com/activity")
        var restorationHandlerCalled = false
        var continued = false

        callFromBackground { [handler] in
            continued = handler?.continue(activity) { _ in restorationHandlerCalled = true } ?? false
        }

        XCTAssertTrue(continued)
        XCTAssertEqual(host.events, [
            "setLaunchInfo on caller",
            "registeredKitResponds on caller",
            "forward continueUserActivity:restorationHandler: on main"
        ])
        XCTAssertEqual(host.respondsQueries, ["continueUserActivity:restorationHandler:"])
        XCTAssertEqual(host.launchInfos.first?.url, activity.webpageURL)

        let forward = try XCTUnwrap(host.forwards.first)
        XCTAssertEqual(forward.messageType, .unknown)
        XCTAssertNil(forward.userInfo)
        XCTAssertEqual(forward.parameters.count, 2)
        XCTAssertTrue(forward.parameters[0] as? NSUserActivity === activity)
        // Kits call the restoration handler as an Objective-C block.
        let restorationHandler = try XCTUnwrap(forward.parameters[1]) as AnyObject
        guard NSStringFromClass(type(of: restorationHandler)).contains("Block") else {
            return XCTFail("The restoration handler reached kits as \(type(of: restorationHandler)), not a block")
        }
        let block = unsafeBitCast(restorationHandler, to: (@convention(block) ([UIUserActivityRestoring]?) -> Void).self)
        block(nil)
        XCTAssertTrue(restorationHandlerCalled)
    }

    func testContinueUserActivityReportsWhenNoKitCanHandleIt() {
        host.kitRespondsToSelector = false
        var continued = true

        callFromBackground { [handler] in
            continued = handler?.continue(NSUserActivity(activityType: "test")) { _ in } ?? true
        }

        XCTAssertFalse(continued)
    }

    func testContinueUserActivityWithoutAWebpageURLUsesAnEmptyURL() {
        callFromBackground { [handler] in _ = handler?.continue(NSUserActivity(activityType: "test")) { _ in } }

        XCTAssertEqual(host.launchInfos.first?.url.absoluteString, "")
    }

    #if os(iOS)

    // MARK: - Remote notification registration

    func testFailedRegistrationClearsTheTokenThenForwardsTheError() throws {
        let error = NSError(domain: "test", code: 1)

        callFromBackground { [handler] in handler?.didFailToRegisterForRemoteNotificationsWithError(error) }

        XCTAssertEqual(host.events, ["setDeviceToken on caller", "forward failedToRegisterForUserNotifications: on main"])
        XCTAssertEqual(host.controller.tokens.count, 1)
        XCTAssertNil(host.controller.tokens.first ?? Data())
        let forward = try XCTUnwrap(host.forwards.first)
        XCTAssertEqual(forward.messageType, .unknown)
        XCTAssertNil(forward.userInfo)
        XCTAssertEqual(forward.parameters.count, 1)
        XCTAssertTrue(try XCTUnwrap(forward.parameters[0]) as AnyObject === error)
    }

    func testFailedRegistrationInAnAppExtensionLeavesTheToken() throws {
        host.isInAppExtension = true

        callFromBackground { [handler] in handler?.didFailToRegisterForRemoteNotificationsWithError(nil) }

        XCTAssertEqual(host.events, ["forward failedToRegisterForUserNotifications: on main"])
        let parameters = try XCTUnwrap(host.forwards.first?.parameters)
        XCTAssertEqual(parameters.count, 1)
        XCTAssertNil(parameters[0])
    }

    func testRegistrationSetsTheTokenThenForwardsAPushRegistration() throws {
        let token = Data([0x0A, 0xFF])

        callFromBackground { [handler] in handler?.didRegisterForRemoteNotifications(withDeviceToken: token) }

        XCTAssertEqual(host.events, ["setDeviceToken on caller", "forward setDeviceToken: on main"])
        XCTAssertEqual(host.controller.tokens, [token])
        let forward = try XCTUnwrap(host.forwards.first)
        XCTAssertEqual(forward.messageType, .pushRegistration)
        XCTAssertEqual(forward.userInfo as? [String: Int], ["state": 1])
        XCTAssertEqual(forward.parameters.count, 1)
        XCTAssertEqual(forward.parameters[0] as? Data, token)
    }

    /// A nil token clears the stored one and reaches kits as nil, rather than as an empty token.
    func testRegistrationWithANilTokenClearsItAndForwardsNil() throws {
        callFromBackground { [handler] in handler?.didRegisterForRemoteNotifications(withDeviceToken: nil) }

        XCTAssertEqual(host.controller.tokens.count, 1)
        XCTAssertNil(host.controller.tokens.first ?? Data())
        let parameters = try XCTUnwrap(host.forwards.first?.parameters)
        XCTAssertEqual(parameters.count, 1)
        XCTAssertNil(parameters[0])
    }

    func testRegistrationInAnAppExtensionLeavesTheToken() {
        host.isInAppExtension = true

        callFromBackground { [handler] in handler?.didRegisterForRemoteNotifications(withDeviceToken: Data([1])) }

        XCTAssertEqual(host.events, ["forward setDeviceToken: on main"])
    }

    // MARK: - Notification actions

    func testHandleActionForwardsTheIdentifierAndPayload() throws {
        callFromBackground { [handler] in handler?.handleAction(withIdentifier: "reply", forRemoteNotification: ["k": "v"]) }

        XCTAssertEqual(host.events, ["forward handleActionWithIdentifier:forRemoteNotification: on main"])
        let forward = try XCTUnwrap(host.forwards.first)
        XCTAssertEqual(forward.messageType, .unknown)
        XCTAssertNil(forward.userInfo)
        XCTAssertEqual(forward.parameters.count, 2)
        XCTAssertEqual(forward.parameters[0] as? String, "reply")
        XCTAssertEqual(forward.parameters[1] as? [String: String], ["k": "v"])
    }

    func testHandleActionWithResponseInfoForwardsAllThreeWithNilsKept() throws {
        callFromBackground { [handler] in
            handler?.handleAction(withIdentifier: nil, forRemoteNotification: nil, withResponseInfo: ["text": "hi"])
        }

        XCTAssertEqual(host.events, ["forward handleActionWithIdentifier:forRemoteNotification:withResponseInfo: on main"])
        let forward = try XCTUnwrap(host.forwards.first)
        XCTAssertEqual(forward.messageType, .unknown)
        XCTAssertEqual(forward.parameters.count, 3)
        XCTAssertNil(forward.parameters[0])
        XCTAssertNil(forward.parameters[1])
        XCTAssertEqual(forward.parameters[2] as? [String: String], ["text": "hi"])
    }

    // MARK: - Remote notifications

    func testRemoteNotificationLogsASilentPushThenForwardsIt() throws {
        let userInfo: [AnyHashable: Any] = ["aps": ["content-available": 1]]

        callFromBackground { [handler] in handler?.didReceiveRemoteNotification(userInfo) }

        XCTAssertEqual(host.events, ["logReceived on caller", "forward receivedUserNotification: on main"])
        XCTAssertNil(host.loggedNotifications.first?.actionIdentifier)
        let forward = try XCTUnwrap(host.forwards.first)
        XCTAssertEqual(forward.messageType, .pushNotification)
        XCTAssertEqual(forward.userInfo as NSDictionary?, userInfo as NSDictionary)
        XCTAssertEqual(forward.parameters.count, 1)
        XCTAssertEqual(forward.parameters[0] as? NSDictionary, userInfo as NSDictionary)
    }

    func testRemoteNotificationOnlyForwardsAnAlertPush() {
        callFromBackground { [handler] in handler?.didReceiveRemoteNotification(["aps": ["alert": "hi"]]) }

        XCTAssertEqual(host.events, ["forward receivedUserNotification: on main"])
    }

    func testRemoteNotificationIsNotLoggedWhileTrackingIsOff() {
        host.tracksNotifications = false

        callFromBackground { [handler] in handler?.didReceiveRemoteNotification(["aps": ["content-available": 1]]) }

        XCTAssertEqual(host.events, ["forward receivedUserNotification: on main"])
    }

    func testNilRemoteNotificationIsIgnored() {
        callFromBackground { [handler] in handler?.didReceiveRemoteNotification(nil) }

        XCTAssertEqual(host.events, [])
    }

    // MARK: - Notification center

    func testWillPresentLogsTheNotificationThenHandsItToKitsOnTheMainQueue() throws {
        let notification = try FakeNotification.make(userInfo: ["aps": ["alert": "hi"]])

        callFromBackground { [handler] in handler?.userNotificationCenter(notificationCenter, willPresent: notification) }

        XCTAssertEqual(host.events, ["logReceived on caller", "forwardWillPresent on main"])
        XCTAssertEqual(host.loggedNotifications.first?.userInfo as NSDictionary?, ["aps": ["alert": "hi"]] as NSDictionary)
        XCTAssertTrue(host.forwardedNotificationCenterObjects.first === notificationCenter)
        XCTAssertTrue(host.forwardedNotificationCenterObjects.last === notification)
    }

    func testWillPresentDoesNotLogASilentPush() throws {
        let notification = try FakeNotification.make(userInfo: ["aps": ["content-available": 1]])

        callFromBackground { [handler] in handler?.userNotificationCenter(notificationCenter, willPresent: notification) }

        XCTAssertEqual(host.events, ["forwardWillPresent on main"])
    }

    func testResponseLogsAnOpenWithItsActionThenHandsItToKitsOnTheMainQueue() throws {
        let response = try FakeNotificationResponse.make(userInfo: ["aps": ["alert": "hi"]], actionIdentifier: "reply")

        callFromBackground { [handler] in handler?.userNotificationCenter(notificationCenter, didReceive: response) }

        XCTAssertEqual(host.events, ["logOpened on caller", "forwardDidReceive on main"])
        XCTAssertEqual(host.loggedNotifications.first?.actionIdentifier, "reply")
        XCTAssertEqual(host.loggedNotifications.first?.userInfo as NSDictionary?, ["aps": ["alert": "hi"]] as NSDictionary)
        XCTAssertTrue(host.forwardedNotificationCenterObjects.first === notificationCenter)
        XCTAssertTrue(host.forwardedNotificationCenterObjects.last === response)
    }

    func testDismissedResponseIsNotLogged() throws {
        let response = try FakeNotificationResponse.make(userInfo: ["aps": ["alert": "hi"]],
                                                         actionIdentifier: UNNotificationDismissActionIdentifier)

        callFromBackground { [handler] in handler?.userNotificationCenter(notificationCenter, didReceive: response) }

        XCTAssertEqual(host.events, ["forwardDidReceive on main"])
    }
    #endif
}
