import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPKitActivityTests: XCTestCase {
    private let kitCode = NSNumber(value: 42)
    private let instance = NSObject()
    private var isActive = false
    private var lookedUpInstance: NSObject?
    private var lookedUpCodes: [NSNumber?] = []
    private var received: [NSObject?] = []

    private lazy var activity = MPKitActivity(
        isKitActive: { [unowned self] code in
            lookedUpCodes.append(code)
            return isActive
        },
        kitInstance: { [unowned self] code in
            lookedUpCodes.append(code)
            return lookedUpInstance
        }
    )

    private func requestInstance() {
        activity.kitInstance(kitCode) { [unowned self] in received.append($0 as? NSObject) }
    }

    private func post(_ userInfo: [AnyHashable: Any]?) {
        NotificationCenter.default.post(
            name: Notification.Name("mParticleKitDidBecomeActiveNotification"), object: nil, userInfo: userInfo
        )
    }

    private func drainMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)
    }

    func testIsKitActiveAndKitInstanceUseTheSuppliedLookups() {
        XCTAssertFalse(activity.isKitActive(kitCode))
        isActive = true
        XCTAssertTrue(activity.isKitActive(kitCode))

        lookedUpInstance = instance
        XCTAssertIdentical(activity.kitInstance(kitCode) as AnyObject, instance)
        _ = activity.kitInstance(nil)

        XCTAssertEqual(lookedUpCodes, [kitCode, kitCode, kitCode, nil])
    }

    func testHandlerRunsAtOnceWhenTheKitHasAnInstance() {
        lookedUpInstance = instance

        requestInstance()
        XCTAssertEqual(received, [instance])

        post(["mParticleKitInstanceKey": kitCode])
        drainMainQueue()
        XCTAssertEqual(received, [instance], "A handler that ran at once is not kept")
    }

    func testPendingHandlerRunsOnMainAfterTheKitBecomesActive() {
        requestInstance()
        XCTAssertEqual(received, [])

        lookedUpInstance = instance
        post(["mParticleKitInstanceKey": kitCode])
        XCTAssertEqual(received, [], "Resolved on a later main-queue turn, not inside the post")

        drainMainQueue()
        XCTAssertEqual(received, [instance])
    }

    func testOtherKitsBecomingActiveDoNotRunThePendingHandler() {
        requestInstance()
        lookedUpInstance = instance

        post(["mParticleKitInstanceKey": NSNumber(value: 7)])
        post(["mParticleKitInstanceKey": "42"])
        post(nil)
        drainMainQueue()

        XCTAssertEqual(received, [])
    }

    func testPendingHandlerRunsEveryTimeAndWithoutAnInstance() {
        // A pending handler is never removed, and a kit with no instance (class based) still runs
        // it, with nil.
        requestInstance()

        post(["mParticleKitInstanceKey": kitCode])
        post(["mParticleKitInstanceKey": NSNumber(value: 42.0)])
        drainMainQueue()

        XCTAssertEqual(received, [nil, nil])
    }
}
