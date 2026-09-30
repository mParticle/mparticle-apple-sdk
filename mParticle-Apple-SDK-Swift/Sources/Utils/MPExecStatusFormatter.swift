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

/// Mirrors the Objective-C `MPExecStatus`; raw values must stay in step.
///
/// The enum itself is declared in `Include/MPBackendController.h`, which the Swift module cannot
/// import, so a Swift workflow returns one of these and the `.m` casts it back at the boundary.
@objc public enum MPExecStatusSwift: Int {
    case success = 0
    case fail
    case missingParam
    case disabledRemotely
    case enabledRemotely
    case optOut
    case dataBeingFetched
    case invalidDataType
    case dataBeingUploaded
    case serverBusy
    case itemNotFound
    case disabledInSettings
    case noConnectivity
}
