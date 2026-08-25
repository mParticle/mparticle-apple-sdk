import Foundation

/// Swift-backed storage for `MPIdentityApiRequest`.
///
/// Holds the request's identity map and the null/empty assignment rules that
/// previously lived in `MPIdentityApiRequest.m`. The public ObjC
/// `MPIdentityApiRequest` class stays the type identity and forwards to this
/// helper — the public wrapper is kept permanently (two-stage wrapper model).
@objc public final class MPIdentityApiRequestStoragePRIVATE: NSObject {

    /// Identity-type number → value, where a value is a `String` or `NSNull`
    /// (an explicitly cleared identity). Exposed so the ObjC contract test can
    /// inspect the raw map directly, matching the pre-migration behaviour.
    @objc public let mutableIdentities = NSMutableDictionary()

    /// Store an identity value. `nil`/`NSNull` clears the slot to `NSNull`; a
    /// non-empty string is stored; an empty string is ignored — the exact
    /// `MPIsNull` semantics of the previous ObjC implementation.
    @objc(setIdentity:identityType:)
    public func setIdentity(_ identityString: Any?, identityType: Int) {
        let key = NSNumber(value: identityType)
        if identityString == nil || identityString is NSNull {
            mutableIdentities[key] = NSNull()
        } else if let value = identityString as? String, !value.isEmpty {
            mutableIdentities[key] = value
        }
    }

    /// Immutable snapshot of the identity map (never an `NSMutableDictionary`).
    @objc public var identities: NSDictionary {
        return (mutableIdentities.copy() as? NSDictionary) ?? NSDictionary()
    }

    @objc public var email: String? {
        get { stringIdentity(.email) }
        set { setIdentity(newValue, identityType: MPIdentitySwift.email.rawValue) }
    }

    @objc public var customerId: String? {
        get { stringIdentity(.customerId) }
        set { setIdentity(newValue, identityType: MPIdentitySwift.customerId.rawValue) }
    }

    @objc public var emailSha256: String? {
        get { stringIdentity(.other) }
        set { setIdentity(newValue, identityType: MPIdentitySwift.other.rawValue) }
    }

    @objc public var mobileSha256: String? {
        get { stringIdentity(.other2) }
        set { setIdentity(newValue, identityType: MPIdentitySwift.other2.rawValue) }
    }

    private func stringIdentity(_ type: MPIdentitySwift) -> String? {
        return mutableIdentities[NSNumber(value: type.rawValue)] as? String
    }
}
