/**
 @see https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/authorizationstatus
 */
@objc public enum MPATTAuthorizationStatusSwift: Int {
    case notDetermined = 0
    case restricted
    case denied
    case authorized
}
