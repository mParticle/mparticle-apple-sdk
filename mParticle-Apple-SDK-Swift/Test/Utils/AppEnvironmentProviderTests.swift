import XCTest
import mParticle_Apple_SDK_Swift

class AppEnvironmentProviderTests: XCTestCase {
    func testAppexBundlePath() {
        let provider = AppEnvironmentProvider(bundlePath: "/Bundle/Application/ABC/MyApp.app/PlugIns/MyExtension.appex")
        #if os(iOS)
        XCTAssertTrue(provider.isAppExtension())
        #else
        XCTAssertFalse(provider.isAppExtension())
        #endif
    }

    func testAppBundlePath() {
        let provider = AppEnvironmentProvider(bundlePath: "/Bundle/Application/ABC/MyApp.app")
        XCTAssertFalse(provider.isAppExtension())
    }

    func testEmptyBundlePath() {
        XCTAssertFalse(AppEnvironmentProvider(bundlePath: "").isAppExtension())
    }

    func testAppexSuffixOnlyMatchesAtEnd() {
        let provider = AppEnvironmentProvider(bundlePath: "/Bundle/MyExtension.appex/Contents")
        XCTAssertFalse(provider.isAppExtension())
    }

    func testDefaultInitUsesMainBundle() {
        XCTAssertFalse(AppEnvironmentProvider().isAppExtension())
    }

    func testUsableThroughProtocol() {
        let provider: AppEnvironmentProviderProtocol = AppEnvironmentProvider(bundlePath: "/Bundle/MyApp.app")
        XCTAssertFalse(provider.isAppExtension())
    }
}
