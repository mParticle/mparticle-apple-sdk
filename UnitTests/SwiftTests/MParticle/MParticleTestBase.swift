import XCTest
import mParticle_Apple_SDK

class MParticleTestBase: XCTestCase {
    var receivedMessage: String?
    var mparticle: MParticle!
    var kitContainer: MPKitContainerMock!
    var executor: ExecutorMock!
    var backendController: MPBackendControllerMock!
    var state: MPStateMachineMock!
    var notificationController: MPNotificationControllerMock!
    var appEnvironmentProvier: AppEnvironmentProviderMock!
    var appNotificationHandler: MPAppNotificationHandlerMock!
    var persistenceController: MPPersistenceControllerMock!
    var settingsProvider: SettingsProviderMock!
    var options: MParticleOptions!
    var userDefaults: MPUserDefaultsMock!
    var dataPlanFilter: MPDataPlanFilterMock!
    var kit: MPKitMock!

    let testName: String = "test"
    let keyValueDict: [String: String] = ["key": "value"]
    let responseKeyValueDict: [String: String] = ["responseKey": "responseValue"]

    let token = "abcd1234".data(using: .utf8)!
    let error = NSError(domain: "test", code: 1)
    let exception = NSException(name: NSExceptionName("Test"), reason: "Test", userInfo: nil)
    let url = URL(string: "https://example.com")!

    var event: MPEvent!
    var transformedEvent: MPEvent!
    var baseEvent: MPBaseEvent!
    var transformedBaseEvent: MPBaseEvent!
    var commerceEvent: MPCommerceEvent!
    var transformedCommerceEvent: MPCommerceEvent!

    func customLogger(_ message: String) {
        receivedMessage = message
    }

    override func setUp() {
        super.setUp()
        mparticle = MParticle.sharedInstance()
        mparticle = MParticle()
        mparticle.logLevel = .verbose
        mparticle.customLogger = customLogger

        kitContainer = MPKitContainerMock()
        mparticle.setKitContainer(kitContainer)

        executor = ExecutorMock()
        mparticle.setExecutor(executor)

        backendController = MPBackendControllerMock()
        mparticle.backendController = backendController

        state = MPStateMachineMock()
        mparticle.stateMachine = state

        notificationController = MPNotificationControllerMock()
        mparticle.notificationController = notificationController

        appEnvironmentProvier = AppEnvironmentProviderMock()
        mparticle.appEnvironmentProvider = appEnvironmentProvier

        appNotificationHandler = MPAppNotificationHandlerMock()
        mparticle.appNotificationHandler = appNotificationHandler

        persistenceController = MPPersistenceControllerMock()
        mparticle.persistenceController = persistenceController

        settingsProvider = SettingsProviderMock()
        mparticle.settingsProvider = settingsProvider

        dataPlanFilter = MPDataPlanFilterMock()
        mparticle.dataPlanFilter = dataPlanFilter

        options = MParticleOptions()

        userDefaults = MPUserDefaultsMock()

        kit = MPKitMock()

        event = MPEvent(name: testName, type: .other)!
        event.customAttributes = keyValueDict

        transformedEvent = MPEvent(name: testName, type: .addToCart)!
        event.customAttributes = keyValueDict

        baseEvent = MPBaseEvent(eventType: .other)!
        transformedBaseEvent = MPBaseEvent(eventType: .addToCart)!

        commerceEvent = MPCommerceEvent(action: .addToCart)!
        transformedCommerceEvent = MPCommerceEvent(action: .removeFromCart)!
    }

    override func tearDown() {
        super.tearDown()
        receivedMessage = nil
        mparticle.dataPlanFilter = nil
    }
}

extension MParticleTestBase {
    func assertReceivedMessage<T: MPBaseEvent>(
        _ expectedSuffix: String,
        event: T? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let message = receivedMessage else {
            XCTFail("Expected a received message but got nil", file: file, line: line)
            return
        }
        let prefix = "mParticle -> "
        let expected: String = {
            if let event = event {
                return "\(prefix)\(expectedSuffix): \(event)"
            } else {
                return "\(prefix)\(expectedSuffix)"
            }
        }()

        XCTAssertEqual(
            message.trimmingCharacters(in: .whitespacesAndNewlines),
            expected.trimmingCharacters(in: .whitespacesAndNewlines),
            file: file,
            line: line
        )
    }
}
