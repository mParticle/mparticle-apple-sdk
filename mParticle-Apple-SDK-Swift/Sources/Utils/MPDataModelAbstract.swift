import Foundation

@objc public final class MPDataModelAbstractPRIVATE: NSObject {
    @objc(copyUUID:) public static func copyUUID(_ uuid: String?) -> String? {
        uuid.map { NSString(string: $0) as String }
    }
}
