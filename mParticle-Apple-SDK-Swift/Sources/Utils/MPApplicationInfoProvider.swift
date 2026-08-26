import Foundation

@objc(MPApplicationInfoProvider) public final class MPApplicationInfoProvider: NSObject {
    private let infoDictionary: [String: Any]
    private let appStoreReceiptURL: URL?

    @objc public init(infoDictionary: [String: Any]?, appStoreReceiptURL: URL?) {
        self.infoDictionary = infoDictionary ?? [:]
        self.appStoreReceiptURL = appStoreReceiptURL
        super.init()
    }

    @objc public override convenience init() {
        self.init(infoDictionary: Bundle.main.infoDictionary,
                  appStoreReceiptURL: Bundle.main.appStoreReceiptURL)
    }

    @objc public var name: String? {
        infoDictionary["CFBundleDisplayName"] as? String
    }

    @objc public var version: String? {
        infoDictionary["CFBundleShortVersionString"] as? String
    }

    @objc public var build: String? {
        infoDictionary["CFBundleVersion"] as? String
    }

    @objc public var bundleIdentifier: String? {
        infoDictionary["CFBundleIdentifier"] as? String
    }

    @objc public var pirated: Bool {
        false
    }

    @objc public func appStoreReceipt() -> String? {
        guard let url = appStoreReceiptURL,
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return data.base64EncodedString()
    }
}
