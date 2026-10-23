import XCTest
@testable import mParticle_Apple_SDK_Swift

#if os(iOS)
final class MPNotificationControllerTests: XCTestCase {
    private let tokenA = Data([0x01, 0x02])
    private let tokenB = Data([0x0a, 0xff])
    /// The connector mock's mpId is 1, and kMPDeviceTokenKey is "to".
    private let tokenKey = "1:to"

    private let queue = DispatchQueue(label: "MPNotificationControllerTests")
    private var events: [String] = []
    private var defaults: RecordingUserDefaults!
    private var controller: MPNotificationControllerPRIVATE!
    private var observer: NSObjectProtocol?

    override func setUp() {
        super.setUp()
        _ = DeviceTokenStore.shared.adopt(persistedToken: nil)
        events = []
        defaults = RecordingUserDefaults { [unowned self] in events.append($0) }
        controller = MPNotificationControllerPRIVATE(
            userDefaults: { [unowned self] in defaults },
            messageQueue: { [unowned self] in queue },
            modifyDeviceID: { [unowned self] deviceIdType, value, oldValue in
                events.append("modify \(deviceIdType) \(value) \(oldValue)")
            }
        )
        observer = NotificationCenter.default.addObserver(
            forName: Notifications.kMPRemoteNotificationDeviceTokenNotification,
            object: nil,
            queue: nil
        ) { [unowned self] _ in
            events.append("post")
        }
    }

    override func tearDown() {
        observer.map(NotificationCenter.default.removeObserver)
        _ = DeviceTokenStore.shared.adopt(persistedToken: nil)
        super.tearDown()
    }

    private func drainQueue() {
        queue.sync {}
    }

    func testDeviceTokenAdoptsThePersistedToken() {
        defaults.values[tokenKey] = tokenA

        XCTAssertEqual(controller.deviceToken(), tokenA)
        XCTAssertEqual(DeviceTokenStore.shared.currentToken(), tokenA)
    }

    func testChangedTokenPostsThenModifiesTheDeviceIDThenPersistsOnTheMessageQueue() {
        _ = DeviceTokenStore.shared.adopt(persistedToken: tokenA)

        queue.suspend()
        controller.setDeviceToken(tokenB)
        XCTAssertEqual(events, [])
        queue.resume()
        drainQueue()

        XCTAssertEqual(events, ["post", "modify push_token 0aff 0102", "write \(tokenKey)", "synchronize"])
        XCTAssertEqual(defaults.values[tokenKey] as? Data, tokenB)
    }

    func testFirstTokenIsPersistedWithoutModifyingTheDeviceID() {
        controller.setDeviceToken(tokenA)
        drainQueue()

        XCTAssertEqual(events, ["post", "write \(tokenKey)", "synchronize"])
        XCTAssertEqual(defaults.values[tokenKey] as? Data, tokenA)
    }

    func testNilTokenRemovesThePersistedTokenWithoutModifyingTheDeviceID() {
        defaults.values[tokenKey] = tokenA
        _ = controller.deviceToken()

        controller.setDeviceToken(nil)
        drainQueue()

        XCTAssertEqual(events, ["post", "remove \(tokenKey)", "synchronize"])
        XCTAssertNil(defaults.values[tokenKey])
        XCTAssertNil(controller.deviceToken())
    }

    func testUnchangedTokenDoesNothing() {
        _ = DeviceTokenStore.shared.adopt(persistedToken: tokenA)

        controller.setDeviceToken(tokenA)
        drainQueue()

        XCTAssertEqual(events, [])
    }
}

private final class RecordingUserDefaults: MPUserDefaults {
    var values: [String: Any] = [:]
    private let record: (String) -> Void

    init(record: @escaping (String) -> Void) {
        self.record = record
        super.init(connector: MPUserDefaultsConnectorMock())
    }

    override func mpObject(forKey key: String, userId: NSNumber) -> Any? {
        values["\(userId):\(key)"]
    }

    override func setMPObject(_ value: Any?, forKey key: String, userId: NSNumber) {
        values["\(userId):\(key)"] = value
        record("write \(userId):\(key)")
    }

    override func removeMPObject(forKey key: String, userId: NSNumber) {
        values["\(userId):\(key)"] = nil
        record("remove \(userId):\(key)")
    }

    override func synchronize() {
        record("synchronize")
    }
}
#endif
