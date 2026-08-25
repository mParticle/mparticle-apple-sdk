import Foundation

@objc public final class MPUploadSettingsPRIVATE: NSObject {
    @objc(resolvedHostWithCustomHost:host:) public static func resolvedHost(customHost: String?, host: String?) -> String? {
        customHost ?? host
    }
}
