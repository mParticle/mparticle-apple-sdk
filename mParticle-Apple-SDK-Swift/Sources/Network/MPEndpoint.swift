import Foundation

/// Internal endpoint identifiers shared with the Objective-C networking layer.
///
/// Raw values are persisted as part of identity-cache keys and must remain stable.
@objc public enum MPEndpoint: Int {
    case identityLogin = 0
    case identityLogout = 1
    case identityIdentify = 2
    case identityModify = 3
    case events = 4
    case config = 5
    case alias = 6
}
