import Foundation

/// `Bundle` subclass whose `infoDictionary` is fully controllable from tests.
/// Used to exercise `RoktPaymentExtension`'s `CFBundleURLSchemes` validation
/// without touching the real test bundle's Info.plist.
final class MockBundle: Bundle, @unchecked Sendable {
    var mockInfo: [String: Any]?
    override var infoDictionary: [String: Any]? { mockInfo }
}

/// Builds a `MockBundle` whose `Info.plist` declares `CFBundleURLSchemes`
/// under a single `CFBundleURLTypes` entry.
func makeBundle(withSchemes schemes: [String]) -> Bundle {
    let mock = MockBundle()
    mock.mockInfo = [
        "CFBundleURLTypes": [
            ["CFBundleURLSchemes": schemes]
        ]
    ]
    return mock
}

/// Builds a `MockBundle` with no URL scheme entries in Info.plist.
func makeBundleWithoutSchemes() -> Bundle {
    let mock = MockBundle()
    mock.mockInfo = [:]
    return mock
}
