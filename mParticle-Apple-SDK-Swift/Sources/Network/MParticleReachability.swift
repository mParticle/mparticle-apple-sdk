import Foundation
import SystemConfiguration

@objc public enum MParticleNetworkStatus: Int {
    case notReachable = 0
    case reachableViaWiFi
    case reachableViaWAN
}

private func mParticleReachabilityCallback(
    _: SCNetworkReachability,
    _: SCNetworkReachabilityFlags,
    _: UnsafeMutableRawPointer?
) {
    NotificationCenter.default.post(
        name: Notification.Name(MParticleReachability.reachabilityChangedNotification),
        object: nil
    )
}

@objc(MParticleReachability)
public final class MParticleReachability: NSObject {
    @objc public static let reachabilityChangedNotification = "MParticleReachabilityChangedNotification"

    private let reachabilityRef: SCNetworkReachability?
    private let isLocalWiFi: Bool

    private init(reachabilityRef: SCNetworkReachability?, isLocalWiFi: Bool) {
        self.reachabilityRef = reachabilityRef
        self.isLocalWiFi = isLocalWiFi
        super.init()
    }

    deinit {
        stopNotifier()
    }

    @objc(reachabilityWithHostName:)
    public static func reachability(withHostName hostName: String) -> MParticleReachability? {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, hostName) else {
            return nil
        }
        return MParticleReachability(reachabilityRef: reachability, isLocalWiFi: false)
    }

    @objc(reachabilityWithAddress:)
    public static func reachability(withAddress hostAddress: UnsafePointer<sockaddr_in>) -> MParticleReachability? {
        reachability(withAddress: hostAddress, isLocalWiFi: false)
    }

    @objc(reachabilityForInternetConnection)
    public static func reachabilityForInternetConnection() -> MParticleReachability? {
        var address = zeroAddress()
        return withUnsafePointer(to: &address) { reachability(withAddress: $0) }
    }

    @objc(reachabilityForLocalWiFi)
    public static func reachabilityForLocalWiFi() -> MParticleReachability? {
        var address = zeroAddress()
        address.sin_addr.s_addr = IN_LINKLOCALNETNUM.bigEndian
        return withUnsafePointer(to: &address) { reachability(withAddress: $0, isLocalWiFi: true) }
    }

    private static func zeroAddress() -> sockaddr_in {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        return address
    }

    private static func reachability(
        withAddress hostAddress: UnsafePointer<sockaddr_in>,
        isLocalWiFi: Bool
    ) -> MParticleReachability? {
        hostAddress.withMemoryRebound(to: sockaddr.self, capacity: 1) { address in
            guard let reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, address) else {
                return nil
            }
            return MParticleReachability(reachabilityRef: reachability, isLocalWiFi: isLocalWiFi)
        }
    }

    @objc public func startNotifier() -> Bool {
        guard let reachabilityRef else { return false }
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: nil,
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        guard SCNetworkReachabilitySetCallback(reachabilityRef, mParticleReachabilityCallback, &context) else {
            return false
        }
        return SCNetworkReachabilityScheduleWithRunLoop(
            reachabilityRef,
            CFRunLoopGetCurrent(),
            CFRunLoopMode.defaultMode.rawValue
        )
    }

    @objc public func stopNotifier() {
        guard let reachabilityRef else { return }
        SCNetworkReachabilityUnscheduleFromRunLoop(
            reachabilityRef,
            CFRunLoopGetCurrent(),
            CFRunLoopMode.defaultMode.rawValue
        )
    }

    @objc public func currentReachabilityStatus() -> MParticleNetworkStatus {
        guard let reachabilityRef else { return .notReachable }
        var flags = SCNetworkReachabilityFlags()
        guard SCNetworkReachabilityGetFlags(reachabilityRef, &flags) else {
            return .notReachable
        }
        if isLocalWiFi {
            return Self.localWiFiStatus(for: flags)
        }
        return Self.networkStatus(for: flags)
    }

    @objc public func connectionRequired() -> Bool {
        guard let reachabilityRef else { return false }
        var flags = SCNetworkReachabilityFlags()
        guard SCNetworkReachabilityGetFlags(reachabilityRef, &flags) else {
            return false
        }
        return flags.contains(.connectionRequired)
    }

    static func localWiFiStatus(for flags: SCNetworkReachabilityFlags) -> MParticleNetworkStatus {
        if flags.contains(.reachable), flags.contains(.isDirect) {
            return .reachableViaWiFi
        }
        return .notReachable
    }

    static func networkStatus(for flags: SCNetworkReachabilityFlags) -> MParticleNetworkStatus {
        guard flags.contains(.reachable) else {
            return .notReachable
        }

        var status = MParticleNetworkStatus.notReachable
        if !flags.contains(.connectionRequired) {
            status = .reachableViaWiFi
        }

        if flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic),
           !flags.contains(.interventionRequired) {
            status = .reachableViaWiFi
        }

        #if os(iOS)
            if flags.contains(.isWWAN) {
                status = .reachableViaWAN
            }
        #endif

        return status
    }
}
