import Foundation

@objc public final class MPSettingsProviderPRIVATE: NSObject {
    private let defaultBundle: Bundle?
    private let defaultResourceName: String?
    private var loadedSettings: NSMutableDictionary?

    @objc override public convenience init() {
        self.init(bundle: nil, resourceName: nil)
    }

    /// Creates a provider that loads from `bundle`/`resourceName` on first access to `configSettings`.
    @objc public init(bundle: Bundle?, resourceName: String?) {
        defaultBundle = bundle
        defaultResourceName = resourceName
        super.init()
    }

    /// Settings read from the configured plist on first access. Setting this to `nil` clears the
    /// cache, so the next read reloads from the plist.
    @objc public var configSettings: NSMutableDictionary? {
        get {
            guard let defaultBundle, let defaultResourceName else {
                return loadedSettings
            }
            return loadConfigSettings(from: defaultBundle, resourceName: defaultResourceName)
        }
        set {
            loadedSettings = newValue
        }
    }

    @discardableResult
    @objc(loadConfigSettingsFromBundle:resourceName:)
    public func loadConfigSettings(from bundle: Bundle, resourceName: String) -> NSMutableDictionary? {
        if let loadedSettings {
            return loadedSettings
        }

        guard let path = bundle.path(forResource: resourceName, ofType: "plist") else {
            return nil
        }

        loadedSettings = NSMutableDictionary(contentsOfFile: path)
        return loadedSettings
    }
}
