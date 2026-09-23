import Foundation

@objc public final class MPExecStatusFormatter: NSObject {
    private static let descriptions = [
        "Success",
        "Fail",
        "Missing Parameter",
        "Feature Disabled Remotely",
        "Feature Enabled Remotely",
        "User Opted Out of Tracking",
        "Data Already Being Fetched",
        "Invalid Data Type",
        "Data is Being Uploaded",
        "Server is Busy",
        "Item Not Found",
        "Feature is Disabled in Settings",
        "There is no network connectivity"
    ]

    @objc(descriptionForExecStatus:)
    public static func description(for execStatus: Int) -> String? {
        guard execStatus >= 0, execStatus < descriptions.count else {
            return nil
        }
        return descriptions[execStatus]
    }
}
