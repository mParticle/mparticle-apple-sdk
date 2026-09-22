import SystemConfiguration
import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MParticleReachabilityTests: XCTestCase {
    func testNotificationNameMatchesLegacyConstant() {
        XCTAssertEqual(
            MParticleReachability.reachabilityChangedNotification,
            "MParticleReachabilityChangedNotification"
        )
    }

    func testInternetAndHostFactoriesCreateReachability() {
        XCTAssertNotNil(MParticleReachability.reachabilityForInternetConnection())
        XCTAssertNotNil(MParticleReachability.reachability(withHostName: "example.com"))
        XCTAssertNotNil(MParticleReachability.reachabilityForLocalWiFi())
    }

    func testNetworkStatusNotReachableWhenReachableFlagIsClear() {
        XCTAssertEqual(MParticleReachability.networkStatus(for: []), .notReachable)
    }

    func testNetworkStatusAssumesWiFiWhenReachableWithoutConnectionRequired() {
        XCTAssertEqual(
            MParticleReachability.networkStatus(for: [.reachable]),
            .reachableViaWiFi
        )
    }

    func testNetworkStatusOnDemandWithoutInterventionIsWiFi() {
        let flags: SCNetworkReachabilityFlags = [
            .reachable,
            .connectionRequired,
            .connectionOnDemand
        ]
        XCTAssertEqual(MParticleReachability.networkStatus(for: flags), .reachableViaWiFi)
    }

    func testNetworkStatusOnDemandWithInterventionStaysNotReachable() {
        let flags: SCNetworkReachabilityFlags = [
            .reachable,
            .connectionRequired,
            .connectionOnDemand,
            .interventionRequired
        ]
        XCTAssertEqual(MParticleReachability.networkStatus(for: flags), .notReachable)
    }

    func testLocalWiFiRequiresReachableAndDirect() {
        XCTAssertEqual(MParticleReachability.localWiFiStatus(for: [.reachable]), .notReachable)
        XCTAssertEqual(
            MParticleReachability.localWiFiStatus(for: [.reachable, .isDirect]),
            .reachableViaWiFi
        )
    }

    #if os(iOS)
        func testNetworkStatusWWANOverridesWiFi() {
            XCTAssertEqual(
                MParticleReachability.networkStatus(for: [.reachable, .isWWAN]),
                .reachableViaWAN
            )
        }
    #endif

    func testStartAndStopNotifierOnInternetReachability() {
        guard let reachability = MParticleReachability.reachabilityForInternetConnection() else {
            XCTFail("Expected internet reachability")
            return
        }
        _ = reachability.startNotifier()
        reachability.stopNotifier()
    }
}
