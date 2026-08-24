import Foundation

@objc public final class MPSettingsProviderPRIVATE: NSObject {
    @objc public var configSettings: NSMutableDictionary?

    @objc(loadConfigSettingsFromBundle:resourceName:)
    public func loadConfigSettings(from bundle: Bundle, resourceName: String) -> NSMutableDictionary? {
        if let configSettings {
            return configSettings
        }

        guard let path = bundle.path(forResource: resourceName, ofType: "plist") else {
            return nil
        }

        configSettings = NSMutableDictionary(contentsOfFile: path)
        return configSettings
    }
}
