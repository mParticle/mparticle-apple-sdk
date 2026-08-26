import XCTest
import mParticle_Apple_SDK_Swift

class MPApplicationInfoProviderTests: XCTestCase {
    private func provider(info: [String: Any]? = nil, receiptURL: URL? = nil) -> MPApplicationInfoProvider {
        MPApplicationInfoProvider(infoDictionary: info, appStoreReceiptURL: receiptURL)
    }

    func testBundleMetadataAccessors() {
        let info: [String: Any] = [
            "CFBundleDisplayName": "My App",
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "42",
            "CFBundleIdentifier": "com.example.myapp"
        ]
        let p = provider(info: info)
        XCTAssertEqual(p.name, "My App")
        XCTAssertEqual(p.version, "1.2.3")
        XCTAssertEqual(p.build, "42")
        XCTAssertEqual(p.bundleIdentifier, "com.example.myapp")
    }

    func testMissingKeysReturnNil() {
        let p = provider(info: [:])
        XCTAssertNil(p.name)
        XCTAssertNil(p.version)
        XCTAssertNil(p.build)
        XCTAssertNil(p.bundleIdentifier)
    }

    func testNilInfoDictionaryReturnsNil() {
        XCTAssertNil(provider(info: nil).name)
    }

    func testPiratedAlwaysFalse() {
        XCTAssertFalse(provider().pirated)
    }

    func testAppStoreReceiptReadsAndBase64EncodesData() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("receipt-\(UUID().uuidString).bin")
        let bytes = Data([0x01, 0x02, 0x03, 0x04])
        try bytes.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertEqual(provider(receiptURL: url).appStoreReceipt(), bytes.base64EncodedString())
    }

    func testAppStoreReceiptNilWhenNoURL() {
        XCTAssertNil(provider(receiptURL: nil).appStoreReceipt())
    }

    func testAppStoreReceiptNilWhenFileMissing() {
        let missing = URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString).bin")
        XCTAssertNil(provider(receiptURL: missing).appStoreReceipt())
    }

    func testDefaultInitDoesNotCrash() {
        // The test host bundle has no App Store receipt; this just exercises the main-bundle path.
        _ = MPApplicationInfoProvider().appStoreReceipt()
    }
}
