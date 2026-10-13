import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_Iterable

final class MPKitIterableTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 1003
        let actualKitCode = MPKitIterable.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 1003")
    }

    // MARK: - Malformed server configuration

    // Server configuration is parsed JSON, so any value can arrive as a number, boolean or
    // container.
    // Nothing here calls -start: it initializes the real vendor SDK, once per process.

    private let nonStringValues: [Any] = [42, true, [Any](), [String: Any]()]

    private func kitWithConfiguration(_ configuration: [AnyHashable: Any]) -> MPKitIterable {
        let kit = MPKitIterable()
        kit.configuration = configuration
        kit.perform(Selector(("updateConfiguredSettings")))
        return kit
    }

    func testNonStringUserIdFieldLeavesMpidDisabled() {
        for value in nonStringValues {
            XCTAssertFalse(kitWithConfiguration(["userIdField": value]).mpidEnabled,
                           "userIdField of \(type(of: value)) should not enable MPID")
        }

        XCTAssertTrue(kitWithConfiguration(["userIdField": "mpid"]).mpidEnabled)
    }

    func testNonStringApiKeyIsTreatedAsUnset() {
        let selector = Selector(("configurationStringForKey:"))

        for value in nonStringValues {
            let kit = kitWithConfiguration(["apiKey": value])

            XCTAssertNil(kit.perform(selector, with: "apiKey"),
                         "apiKey of \(type(of: value)) should be ignored")
        }

        let kit = kitWithConfiguration(["apiKey": "key"])
        XCTAssertEqual(kit.perform(selector, with: "apiKey")?.takeUnretainedValue() as? String, "key")
    }
}
