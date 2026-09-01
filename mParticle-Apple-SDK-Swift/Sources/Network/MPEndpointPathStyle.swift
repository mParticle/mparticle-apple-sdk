import Foundation

@objc public final class MPEndpointPathStyle: NSObject {
    @objc public let usesOverrideFormat: Bool
    @objc public let versionSegment: String
    @objc public let warnsSubdirectoryOverrideIgnored: Bool

    private init(usesOverrideFormat: Bool, versionSegment: String, warnsSubdirectoryOverrideIgnored: Bool) {
        self.usesOverrideFormat = usesOverrideFormat
        self.versionSegment = versionSegment
        self.warnsSubdirectoryOverrideIgnored = warnsSubdirectoryOverrideIgnored
        super.init()
    }

    @objc(styleWithDefaultVersion:cdnVersion:usesCustomHost:overridesSubdirectory:)
    public static func style(
        defaultVersion: String,
        cdnVersion: String,
        usesCustomHost: Bool,
        overridesSubdirectory: Bool
    ) -> MPEndpointPathStyle {
        MPEndpointPathStyle(
            usesOverrideFormat: !usesCustomHost && overridesSubdirectory,
            versionSegment: usesCustomHost ? cdnVersion : defaultVersion,
            warnsSubdirectoryOverrideIgnored: usesCustomHost && overridesSubdirectory
        )
    }
}
