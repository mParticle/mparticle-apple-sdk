import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendUploadDependenciesTests: XCTestCase {
    func testNetworkProviderResolvesReplacement() {
        let first = MPBackendUploadNetworkMock()
        let second = MPBackendUploadNetworkMock()
        var network: MPBackendUploadNetworkMock? = first
        let dependencies = MPBackendUploadDependencies(
            network: { network }, shouldDelayForKits: { false }, shouldDelayForWebView: { false },
            schedule: { _, _ in }, logger: { nil }
        )
        dependencies.network()?.requestConfig(nil) { _ in }
        network = second
        dependencies.network()?.requestConfig(nil) { _ in }
        network = nil
        XCTAssertNil(dependencies.network())
        XCTAssertEqual(first.configRequests, 1)
        XCTAssertEqual(second.configRequests, 1)
    }

    func testSchedulingIsInjectedAndDoesNotExecuteInline() {
        var scheduled: (() -> Void)?
        var delay: TimeInterval?
        var called = false
        let dependencies = MPBackendUploadDependencies(
            network: { nil }, shouldDelayForKits: { false }, shouldDelayForWebView: { false },
            schedule: { delay = $0; scheduled = $1 }, logger: { nil }
        )
        dependencies.schedule(1) { called = true }
        XCTAssertEqual(delay, 1)
        XCTAssertFalse(called)
        scheduled?()
        XCTAssertTrue(called)
    }
}

final class MPBackendUploadNetworkMock: NSObject, MPBackendUploadNetworking {
    var configRequests = 0
    var configSuccess = true
    var uploaded: [[MPUploadPRIVATE]] = []

    func requestConfig(_: (NSObject & MPConnectorProtocol)?, completionHandler: @escaping (Bool) -> Void) {
        configRequests += 1
        completionHandler(configSuccess)
    }

    func upload(_ uploads: [MPUploadPRIVATE], completionHandler: @escaping () -> Void) {
        uploaded.append(uploads)
        completionHandler()
    }
}
