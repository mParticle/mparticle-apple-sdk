import Foundation

@objc public protocol AppEnvironmentProviderProtocol {
    func isAppExtension() -> Bool
}

@objc(AppEnvironmentProvider) public final class AppEnvironmentProvider: NSObject, AppEnvironmentProviderProtocol {
    private let bundlePath: String

    @objc public init(bundlePath: String) {
        self.bundlePath = bundlePath
        super.init()
    }

    @objc public override convenience init() {
        self.init(bundlePath: Bundle.main.bundlePath)
    }

    @objc public func isAppExtension() -> Bool {
        #if os(iOS)
        return bundlePath.hasSuffix(".appex")
        #else
        return false
        #endif
    }
}
