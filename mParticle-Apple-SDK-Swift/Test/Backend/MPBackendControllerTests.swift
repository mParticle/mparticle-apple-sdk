import UIKit
import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendControllerTests: XCTestCase {
    private var host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
    private let persistence = MPBackendRecordingPersistence()
    private let delegate = MPBackendFakeDelegate()
    private let network = MPBackendUploadNetworkMock()
    /// The SDK controllers here observe this center, not the default one: a post there would also reach
    /// the state machines that other tests' fake hosts keep alive.
    private let center = NotificationCenter()

    override func setUp() {
        super.setUp()
        host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
        host.isDevelopment = true
        host.networkCommunicationValue = network
    }

    override func tearDown() {
        MPStateMachinePRIVATE.setRunningInBackground(false)
        super.tearDown()
    }

    /// What `-initWithDelegate:persistence:` builds, with the fake host and `center` in place of the SDK's.
    private func makeSDKController() -> MPBackendController_PRIVATE {
        MPBackendController_PRIVATE(host: host, delegate: delegate, persistence: persistence, notificationCenter: center)
    }

    /// Each pass runs the work the previous pass's blocks queued.
    private func drainMessageQueue() {
        for _ in 0..<4 {
            host.queue.sync {}
        }
    }

    private func post(_ name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        center.post(name: name, object: nil, userInfo: userInfo)
    }

    func testThePlainInitialiserHasNoDelegatePersistenceNetworkLayerOrSessionTimeout() {
        let controller = MPBackendController_PRIVATE(host: host)

        XCTAssertNil(controller.backendDelegate())
        XCTAssertNil(controller.persistence())
        XCTAssertNil(controller.uploadNetworking())
        XCTAssertEqual(controller.sessionTimeout, 0)
        XCTAssertEqual(controller.uploadInterval, 60)
        XCTAssertFalse(host.calls.contains("makeNetworkCommunication"))
    }

    func testTheSDKInitialiserTakesItsPersistenceTheHostsNetworkLayerAndTheDefaults() throws {
        let before = Date().timeIntervalSince1970
        let controller = makeSDKController()

        XCTAssertTrue(controller.persistence() === persistence)
        XCTAssertTrue(controller.uploadNetworking() === network)
        XCTAssertTrue(controller.backendDelegate() === delegate)
        XCTAssertEqual(host.calls.filter { $0 == "makeNetworkCommunication" }.count, 1)
        XCTAssertEqual(controller.sessionTimeout, 60)
        XCTAssertGreaterThanOrEqual(controller.sessionState.nextCleanUpTime, before)
        XCTAssertEqual(try XCTUnwrap(controller.backgroundCheckQueue).maxConcurrentOperationCount, 1)
    }

    func testTheSDKInitialiserObservesTheAppLifecycle() {
        let controller = makeSDKController()

        post(UIApplication.didFinishLaunchingNotification, userInfo: ["launch": "marker"])
        XCTAssertEqual(controller.startupCoordinator.didFinishLaunchingNotification?.userInfo?["launch"] as? String, "marker")

        post(UIApplication.didEnterBackgroundNotification)
        XCTAssertTrue(MPStateMachinePRIVATE.runningInBackground())
        drainMessageQueue()
        XCTAssertGreaterThan(controller.timeAppWentToBackgroundInCurrentSession, 0)

        post(UIApplication.willEnterForegroundNotification)
        XCTAssertFalse(MPStateMachinePRIVATE.runningInBackground())

        post(UIApplication.didBecomeActiveNotification)
        XCTAssertNotNil(controller.assembly.lifecycleCoordinator.uploadTimer)
        controller.endUploadTimer()
        drainMessageQueue()
    }

    #if os(iOS)
        func testTheSDKInitialiserObservesDeviceTokenChanges() {
            let controller = makeSDKController()

            post(
                Notifications.kMPRemoteNotificationDeviceTokenNotification,
                userInfo: ["MPRemoteNotificationDeviceTokenKey": Data([0xAB, 0xCD])]
            )
            drainMessageQueue()

            XCTAssertEqual(persistence.savedMessages.compactMap(\.messageType), ["pr"])
            XCTAssertTrue(controller.persistence() === persistence)
        }
    #endif

    func testTheInitialiserTheCategoryCallsObservesTheDefaultCenter() {
        let controller = MPBackendController_PRIVATE(host: host, delegate: delegate, persistence: persistence)

        // Only did-finish-launching, which no state machine observes, so nothing else reacts.
        NotificationCenter.default.post(
            name: UIApplication.didFinishLaunchingNotification, object: nil, userInfo: ["launch": "default"]
        )

        XCTAssertEqual(controller.startupCoordinator.didFinishLaunchingNotification?.userInfo?["launch"] as? String, "default")
    }

    func testThePlainInitialiserDoesNotObserveTheAppLifecycle() {
        let controller = MPBackendController_PRIVATE(host: host)

        // The default center, which the SDK's controller observes. State machines observe the background
        // notifications there, so only these two are posted.
        NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        XCTAssertNil(controller.startupCoordinator.didFinishLaunchingNotification)
        XCTAssertNil(controller.assembly.lifecycleCoordinator.uploadTimer)
    }

    func testAReleasedControllerIsFreedAndEndsItsUploadTimer() {
        weak var released: MPBackendController_PRIVATE?
        var lifecycle: MPBackendLifecycleCoordinator?
        autoreleasepool {
            let controller = makeSDKController()
            controller.beginUploadTimer()
            lifecycle = controller.assembly.lifecycleCoordinator
            XCTAssertNotNil(lifecycle?.uploadTimer)
            released = controller
        }

        XCTAssertNil(released)
        XCTAssertNil(lifecycle?.uploadTimer)
    }
}
