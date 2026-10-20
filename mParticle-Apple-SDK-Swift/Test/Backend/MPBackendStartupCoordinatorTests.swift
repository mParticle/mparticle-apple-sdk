import UIKit
import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendStartupCoordinatorTests: XCTestCase {
    private var host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
    private var owner: MPBackendFakeOwner!
    private var assembly: MPBackendAssembly!
    private var state = MPBackendSessionState()
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

    private var startup: MPBackendStartupCoordinator { assembly.startupCoordinator }

    private func drainMessageQueue() {
        for _ in 0..<4 { host.queue.sync {} }
    }

    private func savedTypes() -> [String] {
        persistence.savedMessages.compactMap(\.messageType)
    }

    private func start(apiKey: String = "key", firstRun: Bool = false, completed: (() -> Void)? = nil) {
        startup.start(
            apiKey: apiKey, secret: "secret", networkOptions: nil, firstRun: firstRun,
            installationType: .knownSameVersion, startKitsAsync: false, completionHandler: { completed?() }
        )
        drainMessageQueue()
    }

    func testStartRecordsTheKeysAndStartsKits() {
        var completions = 0
        start(completed: { completions += 1 })

        XCTAssertEqual(host.machine.apiKey, "key")
        XCTAssertEqual(host.machine.secret, "secret")
        XCTAssertEqual(host.machine.installationType, MPInstallationTypeSwift.knownSameVersion.rawValue)
        XCTAssertTrue(host.calls.contains("initializeKits"))
        XCTAssertTrue(host.calls.contains("openPersistence"))
        XCTAssertEqual(host.storedUploadSettings.map(\.apiKey), ["key"])
        XCTAssertEqual(completions, 1)
    }

    func testStartWhileOptedOutStartsNoKitsAndNoSession() {
        host.isOptedOut = true

        start()

        XCTAssertFalse(host.calls.contains("initializeKits"))
        XCTAssertNil(state.session)
    }

    func testStartBeginsASessionWhenTheAppAllowsIt() {
        start()

        XCTAssertNotNil(state.session)
        XCTAssertTrue(savedTypes().contains("ss"))
    }

    func testAWorkspaceSwitchBatchesUnderTheLastSettings() {
        let last = NSObject()
        host.lastUploadSettingsValue = last
        host.uploadSettingsApiKeys[ObjectIdentifier(last)] = "old"

        start(apiKey: "new")

        XCTAssertEqual(owner.preparedUploadSettings.count, 1)
        XCTAssertTrue(owner.preparedUploadSettings.first.flatMap { $0 } === last)
        XCTAssertTrue(host.calls.contains("deleteCachedConfiguration"))
        XCTAssertTrue(host.calls.contains("restoreCachedConfiguration"))
    }

    func testTheSameWorkspaceDoesNotBatch() {
        let last = NSObject()
        host.lastUploadSettingsValue = last
        host.uploadSettingsApiKeys[ObjectIdentifier(last)] = "key"

        start(apiKey: "key")

        XCTAssertTrue(owner.preparedUploadSettings.isEmpty)
        XCTAssertFalse(host.calls.contains("deleteCachedConfiguration"))
        XCTAssertTrue(host.calls.contains("restoreCachedConfiguration"))
    }

    func testAFirstStartWithNoStoredSettingsStillBatches() {
        start()

        XCTAssertEqual(owner.preparedUploadSettings.count, 1)
        XCTAssertNil(owner.preparedUploadSettings.first.flatMap { $0 })
    }

    func testAFirstRunWritesTheFirstRunMessageAndStartsUploading() {
        start(firstRun: true)

        XCTAssertTrue(savedTypes().contains("fr"))
        XCTAssertTrue(savedTypes().contains("ast"))
        XCTAssertEqual(owner.calls.filter { $0 == "upload" }.count, 1)
    }

    func testTheLaunchIsRecordedOnceWhenAttributionAndTheTimeoutBothFinish() {
        host.collectsSearchAdsAttribution = true
        startup.attributionTimeout = 0.05

        start()
        let timeoutPassed = expectation(description: "the attribution timeout has fired")
        host.queue.asyncAfter(deadline: .now() + 0.2) { timeoutPassed.fulfill() }
        wait(for: [timeoutPassed], timeout: 2)
        drainMessageQueue()

        XCTAssertEqual(savedTypes().filter { $0 == "ast" }.count, 1)
        XCTAssertEqual(owner.calls.filter { $0 == "upload" }.count, 1)
    }

    func testAReleasedControllerSkipsTheDeferredStart() {
        // No temporary session: its begin broadcast holds the controller until the main queue runs.
        host.beginsSessions = false
        var completions = 0
        host.queue.suspend()
        startup.start(
            apiKey: "key", secret: "secret", networkOptions: nil, firstRun: true,
            installationType: .knownSameVersion, startKitsAsync: false, completionHandler: { completions += 1 }
        )
        owner = nil
        host.queue.resume()
        drainMessageQueue()

        XCTAssertEqual(completions, 0)
        XCTAssertFalse(host.calls.contains("openPersistence"))
    }

    func testAnInstallIsForwardedAndStartsASession() throws {
        host.machine.installationType = MPInstallationTypeSwift.knownInstall.rawValue

        startup.processDidFinishLaunching(nil)
        drainMessageQueue()

        XCTAssertEqual(owner.delegate.calls, ["forwardLogInstall"])
        XCTAssertNotNil(state.session)
        let launch = try XCTUnwrap(persistence.savedMessages.first { $0.messageType == "ast" })
        let info = try XCTUnwrap(launch.dictionaryRepresentation() as? [String: Any])
        XCTAssertEqual(info["ifr"] as? Bool, true)
        XCTAssertEqual(info["t"] as? String, "app_init")
        XCTAssertTrue(host.calls.contains("updateStoredVersionAndBuildNumbers"))
    }

    func testAnUpgradeIsForwarded() {
        host.machine.installationType = MPInstallationTypeSwift.knownUpgrade.rawValue

        startup.processDidFinishLaunching(nil)
        drainMessageQueue()

        XCTAssertEqual(owner.delegate.calls, ["forwardLogUpdate"])
    }

    func testTheURLTheAppWasOpenedFromIsRecorded() throws {
        let url = try XCTUnwrap(URL(string: "https://www.example.com/landing"))
        let activity = NSUserActivity(activityType: "test")
        activity.webpageURL = url
        let notification = Notification(
            name: UIApplication.didFinishLaunchingNotification, object: nil,
            userInfo: [UIApplication.LaunchOptionsKey
            .userActivityDictionary: ["UIApplicationLaunchOptionsUserActivityKey": activity]]
        )
        startup.didFinishLaunchingNotification = notification

        startup.processDidFinishLaunching(startup.didFinishLaunchingNotification)

        XCTAssertEqual(host.machine.launchInfo?.url, url)
        XCTAssertNil(startup.didFinishLaunchingNotification)
    }
}
