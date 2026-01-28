/// User Identities
/// The identities in this enum are limited to end-user forms of identity. A new enum, MPIdentity, has been provided to cover all valid forms of identity supported by the mParticle Identity API (user identities and device identities)
@objc public enum MPUserIdentitySwift: UInt {
    case other = 0
    case customerId = 1
    case facebook = 2
    case twitter = 3
    case google = 4
    case microsoft = 5
    case yahoo = 6
    case email = 7
    case alias = 8
    case facebookCustomAudienceId = 9
    case other2 = 10
    case other3 = 11
    case other4 = 12
    case other5 = 13
    case other6 = 14
    case other7 = 15
    case other8 = 16
    case other9 = 17
    case other10 = 18
    case mobileNumber = 19
    case phoneNumber2 = 20
    case phoneNumber3 = 21
}
