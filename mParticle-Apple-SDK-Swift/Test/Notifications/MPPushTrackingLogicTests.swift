import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPPushTrackingLogicTests: XCTestCase {
    private let silentPush: [AnyHashable: Any] = ["aps": ["content-available": 1]]
    private let alertPush: [AnyHashable: Any] = ["aps": ["alert": "hello"]]

    // MARK: - hasContentAvailable

    func testSilentPushIsContentAvailable() {
        XCTAssertTrue(PushTrackingLogic.hasContentAvailable(silentPush))
    }

    func testAlertPushIsNotContentAvailable() {
        XCTAssertFalse(PushTrackingLogic.hasContentAvailable(alertPush))
    }

    func testMissingApsIsNotContentAvailable() {
        XCTAssertFalse(PushTrackingLogic.hasContentAvailable(["other": 1]))
        XCTAssertFalse(PushTrackingLogic.hasContentAvailable(nil))
        XCTAssertFalse(PushTrackingLogic.hasContentAvailable([:]))
    }

    /// The ObjC original compared against `@1` with `isEqual:`, so a boolean true also
    /// matched (NSNumber bridges both to the same value) but the string "1" did not.
    func testContentAvailableMatchesTheNumberOneNotTheString() {
        XCTAssertTrue(PushTrackingLogic.hasContentAvailable(["aps": ["content-available": true]]))
        XCTAssertFalse(PushTrackingLogic.hasContentAvailable(["aps": ["content-available": "1"]]))
        XCTAssertFalse(PushTrackingLogic.hasContentAvailable(["aps": ["content-available": 0]]))
    }

    func testMalformedApsDoesNotTrap() {
        XCTAssertFalse(PushTrackingLogic.hasContentAvailable(["aps": "not a dictionary"]))
        XCTAssertFalse(PushTrackingLogic.hasContentAvailable(["aps": NSNull()]))
    }

    // MARK: - isPreIOS10

    func testVersionComparison() {
        XCTAssertTrue(PushTrackingLogic.isPreIOS10(systemVersion: "9.3.5"))
        XCTAssertFalse(PushTrackingLogic.isPreIOS10(systemVersion: "10.0"))
        XCTAssertFalse(PushTrackingLogic.isPreIOS10(systemVersion: "18.5"))
        XCTAssertFalse(PushTrackingLogic.isPreIOS10(systemVersion: "26.3.1"))
    }

    /// `floatValue` yields 0 for an unparseable string rather than failing, and 0 < 10,
    /// so garbage reads as "pre-iOS 10". Preserved rather than tightened.
    func testUnparseableVersionReadsAsPreIOS10() {
        XCTAssertTrue(PushTrackingLogic.isPreIOS10(systemVersion: ""))
        XCTAssertTrue(PushTrackingLogic.isPreIOS10(systemVersion: "not a version"))
    }

    // MARK: - didReceiveRemoteNotification

    func testTrackingOffLogsNothing() {
        XCTAssertEqual(PushTrackingLogic.remoteNotificationAction(trackNotifications: false,
                                                                  isPreIOS10: false,
                                                                  applicationIsActive: false,
                                                                  userInfo: silentPush), .none)
    }

    func testModernOSLogsOnlySilentPushes() {
        XCTAssertEqual(PushTrackingLogic.remoteNotificationAction(trackNotifications: true,
                                                                  isPreIOS10: false,
                                                                  applicationIsActive: false,
                                                                  userInfo: silentPush), .logReceived)
        XCTAssertEqual(PushTrackingLogic.remoteNotificationAction(trackNotifications: true,
                                                                  isPreIOS10: false,
                                                                  applicationIsActive: false,
                                                                  userInfo: alertPush), .none)
    }

    func testPreIOS10ActiveSilentPushCountsAsReceived() {
        XCTAssertEqual(PushTrackingLogic.remoteNotificationAction(trackNotifications: true,
                                                                  isPreIOS10: true,
                                                                  applicationIsActive: true,
                                                                  userInfo: silentPush), .logReceived)
    }

    func testPreIOS10BackgroundedCountsAsOpened() {
        XCTAssertEqual(PushTrackingLogic.remoteNotificationAction(trackNotifications: true,
                                                                  isPreIOS10: true,
                                                                  applicationIsActive: false,
                                                                  userInfo: silentPush), .logOpened)
    }

    func testPreIOS10ActiveAlertPushCountsAsOpened() {
        XCTAssertEqual(PushTrackingLogic.remoteNotificationAction(trackNotifications: true,
                                                                  isPreIOS10: true,
                                                                  applicationIsActive: true,
                                                                  userInfo: alertPush), .logOpened)
    }

    // MARK: - willPresentNotification

    func testWillPresentLogsAlertPushes() {
        XCTAssertEqual(PushTrackingLogic.willPresentAction(trackNotifications: true,
                                                           userInfo: alertPush), .logReceived)
    }

    /// A silent push has already been logged by didReceiveRemoteNotification:, so
    /// logging it again here would double-count.
    func testWillPresentSkipsSilentPushes() {
        XCTAssertEqual(PushTrackingLogic.willPresentAction(trackNotifications: true,
                                                           userInfo: silentPush), .none)
    }

    func testWillPresentRespectsTrackingOff() {
        XCTAssertEqual(PushTrackingLogic.willPresentAction(trackNotifications: false,
                                                           userInfo: alertPush), .none)
    }

    // MARK: - didReceiveNotificationResponse

    func testResponseLogsOpened() {
        XCTAssertEqual(PushTrackingLogic.notificationResponseAction(trackNotifications: true,
                                                                    actionIdentifier: "com.example.reply",
                                                                    dismissActionIdentifier: "dismiss"), .logOpened)
    }

    func testDismissingIsNotOpening() {
        XCTAssertEqual(PushTrackingLogic.notificationResponseAction(trackNotifications: true,
                                                                    actionIdentifier: "dismiss",
                                                                    dismissActionIdentifier: "dismiss"), .none)
    }

    /// `[nil isEqual:x]` was NO, so the negated ObjC condition logged an open for a nil
    /// action identifier. Preserved.
    func testNilActionIdentifierStillLogsOpened() {
        XCTAssertEqual(PushTrackingLogic.notificationResponseAction(trackNotifications: true,
                                                                    actionIdentifier: nil,
                                                                    dismissActionIdentifier: "dismiss"), .logOpened)
    }

    func testResponseRespectsTrackingOff() {
        XCTAssertEqual(PushTrackingLogic.notificationResponseAction(trackNotifications: false,
                                                                    actionIdentifier: "com.example.reply",
                                                                    dismissActionIdentifier: "dismiss"), .none)
    }
}
