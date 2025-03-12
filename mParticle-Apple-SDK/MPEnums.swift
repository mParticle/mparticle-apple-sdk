import Foundation

// MARK: - Message Type String Constants
public let kMPMessageTypeStringUnknown = "unknown"
public let kMPMessageTypeStringSessionStart = "ss"
public let kMPMessageTypeStringSessionEnd = "se"
public let kMPMessageTypeStringScreenView = "v"
public let kMPMessageTypeStringEvent = "e"
public let kMPMessageTypeStringCrashReport = "cr"
public let kMPMessageTypeStringOptOut = "o"
public let kMPMessageTypeStringFirstRun = "fr"
public let kMPMessageTypeStringPreAttribution = "pa"
public let kMPMessageTypeStringPushRegistration = "pr"
public let kMPMessageTypeStringAppStateTransition = "ast"
public let kMPMessageTypeStringPushNotification = "pn"
public let kMPMessageTypeStringNetworkPerformance = "np"
public let kMPMessageTypeStringBreadcrumb = "bc"
public let kMPMessageTypeStringProfile = "pro"
public let kMPMessageTypeStringPushNotificationInteraction = "pni"
public let kMPMessageTypeStringCommerceEvent = "cm"
public let kMPMessageTypeStringUserAttributeChange = "uac"
public let kMPMessageTypeStringUserIdentityChange = "uic"
public let kMPMessageTypeStringMedia = "media"

// MARK: - Message Type Enum
/// Message Types
@objc public enum MPMessageType: UInt {
    /// Message type unknown - RESERVED, DO NOT USE
    case unknown = 0
    /// Message type code for a session start
    case sessionStart = 1
    /// Message type code for a session end
    case sessionEnd = 2
    /// Message type code for a screen view
    case screenView = 3
    /// Message type code for an event
    case event = 4
    /// Message type code for a crash report
    case crashReport = 5
    /// Message type code for opt out
    case optOut = 6
    /// Message type code for the first time the app is run
    case firstRun = 7
    /// Message type code for attributions
    case preAttribution = 8
    /// Message type code for when an app successfully registers to receive push notifications
    case pushRegistration = 9
    /// Message type code for when an app transitions to/from background
    case appStateTransition = 10
    /// Message type code for when an app receives a push notification
    case pushNotification = 11
    /// Message type code for logging a network performance measurement
    case networkPerformance = 12
    /// Message type code for leaving a breadcrumb
    case breadcrumb = 13
    /// Message type code for profile - RESERVED, DO NOT USE
    case profile = 14
    /// Message type code for when a user interacts with a received push notification
    case pushNotificationInteraction = 15
    /// Message type code for a commerce event
    case commerceEvent = 16
    /// Message type code for a user attribute change
    case userAttributeChange = 17
    /// Message type code for a user identity change
    case userIdentityChange = 18
    /// Message type code for a media event
    case media = 20
}

// MARK: - Identity Enum
/// MP Identities
@objc public enum MPIdentity: UInt {
    /// User identity other
    case other = 0
    /// User identity customer id. This is an id issued by your own system
    case customerId = 1
    /// User identity Facebook
    case facebook = 2
    /// User identity Twitter
    case twitter = 3
    /// User identity Google
    case google = 4
    /// User identity Microsoft
    case microsoft = 5
    /// User identity Yahoo!
    case yahoo = 6
    /// User identity Email
    case email = 7
    /// User identity Alias
    case alias = 8
    /// User identity Facebook Custom Audience Third Party Id, or User App Id
    case facebookCustomAudienceId = 9
    /// User identity other 2
    case other2 = 10
    /// User identity other 3
    case other3 = 11
    /// User identity other 4
    case other4 = 12
    /// User identity other 5
    case other5 = 13
    /// User identity other 6
    case other6 = 14
    /// User identity other 7
    case other7 = 15
    /// User identity other 8
    case other8 = 16
    /// User identity other 9
    case other9 = 17
    /// User identity other 10
    case other10 = 18
    /// User identity mobile number
    case mobileNumber = 19
    /// User identity phone number 2
    case phoneNumber2 = 20
    /// User identity phone number 3
    case phoneNumber3 = 21
    /// Device identity advertiser ID (IDFA)
    /// When setting this, you must also provide the App Tracking Transparency status of the device
    /// - SeeAlso: setATTStatus:withTimestamp:
    case iosAdvertiserId = 22
    /// Device identity vendor
    case iosVendorId = 23
    /// Device identity Push Token
    case pushToken = 24
    /// Device identity Application Stamp
    case deviceApplicationStamp = 25
}

// MARK: - Notification Constants
/// Posted immediately after a new session has begun.
///
/// You can register to receive this notification using NSNotificationCenter. This notification contains a userInfo dictionary, you can
/// access the respective session id by using the mParticleSessionId constant.
public let mParticleSessionDidBeginNotification = "mParticleSessionDidBeginNotification"

/// Posted right before the current session ends.
///
/// You can register to receive this notification using NSNotificationCenter. This notification contains a userInfo dictionary, you can
/// access the respective session id by using the mParticleSessionId constant.
public let mParticleSessionDidEndNotification = "mParticleSessionDidEndNotification"

/// This constant is used as key for the userInfo dictionary in the
/// mParticleSessionDidBeginNotification and mParticleSessionDidEndNotification notifications. The value
/// of this key is the id of the session.
public let mParticleSessionId = "mParticleSessionId"

/// This constant is used as key for the userInfo dictionary in the
/// mParticleSessionDidBeginNotification and mParticleSessionDidEndNotification notifications. The value
/// of this key is the UUID of the session.
public let mParticleSessionUUID = "mParticleSessionUUID"

/// Posted immediately after the SDK becomes initialized.
///
/// You can register to receive this notification using NSNotificationCenter. This notification is broadcast when the mParticle SDK successfully
/// finishes its initialization.
public let mParticleDidFinishInitializing = "mParticleDidFinishInitializing"

// MARK: - User Attribute Constants
/// Set of constants that can be used to specify certain attributes of a user.
///
/// There are many 3rd party services that support, for example, specifying a gender of a user.
/// The mParticle platform will look for these constants within the user attributes that
/// you have set for a given user, and forward any attributes to the services that support them.
/// - SeeAlso: setUserAttribute:value:
public let mParticleUserAttributeMobileNumber = "$Mobile"
public let mParticleUserAttributeGender = "$Gender"
public let mParticleUserAttributeAge = "$Age"
public let mParticleUserAttributeCountry = "$Country"
public let mParticleUserAttributeZip = "$Zip"
public let mParticleUserAttributeCity = "$City"
public let mParticleUserAttributeState = "$State"
public let mParticleUserAttributeAddress = "$Address"
public let mParticleUserAttributeFirstName = "$FirstName"
public let mParticleUserAttributeLastName = "$LastName"

// MARK: - Kit Notification Constants
/// Posted immediately after a kit becomes available to be used.
///
/// If your app is calling a kit methods directly, you can register to receive this notification
/// when a kit becomes available for use. The notification contains a userInfo dictionary where you can extract
/// the associated kit instance with the mParticleKitInstanceKey constant.
/// - SeeAlso: MPKitInstance
/// - SeeAlso: mParticleKitInstanceKey
public let mParticleKitDidBecomeActiveNotification = "mParticleKitDidBecomeActiveNotification"
public let mParticleEmbeddedSDKDidBecomeActiveNotification = "mParticleEmbeddedSDKDidBecomeActiveNotification"

/// Posted immediately after a kit becomes unavailable to be used.
///
/// If your app is calling kit methods directly, you can register to receive this notification
/// when a kit becomes unavailable for use. You may receive this notification if a kit gets disabled
/// in the mParticle Services Hub. The notification contains a userInfo dictionary where you can extract
/// the associated kit instance with the mParticleKitInstanceKey constant.
/// - SeeAlso: MPKitInstance
/// - SeeAlso: mParticleKitInstanceKey
public let mParticleKitDidBecomeInactiveNotification = "mParticleKitDidBecomeInactiveNotification"
public let mParticleEmbeddedSDKDidBecomeInactiveNotification = "mParticleEmbeddedSDKDidBecomeInactiveNotification"

/// Constant used to extract the respective kit instance number from userInfo dictionary in a kit notification.
/// - SeeAlso: mParticleKitDidBecomeActiveNotification
/// - SeeAlso: mParticleKitDidBecomeInactiveNotification
public let mParticleKitInstanceKey = "mParticleKitInstanceKey"
public let mParticleEmbeddedSDKInstanceKey = "mParticleEmbeddedSDKInstanceKey"

// MARK: - Identity Constants
/// Posted immediately after the user's MPID changes (or in other terms when a different user becomes active).
public let mParticleIdentityStateChangeListenerNotification = "mParticleIdentityStateChangeListenerNotification"

/// Key to retrieve now-active user from identity state change notification's userInfo dictionary
public let mParticleUserKey = "mParticleUserKey"

/// Key to retrieve previously-active user (if applicable) from identity state change notification's userInfo dictionary
public let mParticlePreviousUserKey = "mParticlePreviousUserKey"

public let mParticleIdentityErrorDomain = "mParticle Identity Error Domain"
public let mParticleIdentityErrorKey = "mParticle Identity Error"

// MARK: - Gender Constants
/// Constants used to express gender.
public let mParticleGenderMale = "M"
public let mParticleGenderFemale = "F"
public let mParticleGenderNotAvailable = "NA"

// MARK: - Kit API Error Constants
/// Kit API error domain and key
public let MPKitAPIErrorDomain = "com.mparticle.kitapi"
public let MPKitAPIErrorKey = "mParticle Kit API Error"

// MARK: - MPEnum Class Conversion
@objcMembers public class MPEnum: NSObject {
    public class func isUserIdentity(_ identity: MPIdentity) -> Bool {
        return identity.rawValue <= MPIdentity.phoneNumber3.rawValue
    }
    
    public class func messageType(from messageTypeString: String?) -> MPMessageType {
        guard let messageTypeString = messageTypeString else { return .unknown }
        
        switch messageTypeString {
        case kMPMessageTypeStringSessionStart:
            return .sessionStart
        case kMPMessageTypeStringSessionEnd:
            return .sessionEnd
        case kMPMessageTypeStringScreenView:
            return .screenView
        case kMPMessageTypeStringEvent:
            return .event
        case kMPMessageTypeStringCrashReport:
            return .crashReport
        case kMPMessageTypeStringOptOut:
            return .optOut
        case kMPMessageTypeStringFirstRun:
            return .firstRun
        case kMPMessageTypeStringPreAttribution:
            return .preAttribution
        case kMPMessageTypeStringPushRegistration:
            return .pushRegistration
        case kMPMessageTypeStringNetworkPerformance:
            return .networkPerformance
        case kMPMessageTypeStringBreadcrumb:
            return .breadcrumb
        case kMPMessageTypeStringProfile:
            return .profile
        case kMPMessageTypeStringPushNotification:
            return .pushNotification
        case kMPMessageTypeStringPushNotificationInteraction:
            return .pushNotificationInteraction
        case kMPMessageTypeStringCommerceEvent:
            return .commerceEvent
        case kMPMessageTypeStringUserAttributeChange:
            return .userAttributeChange
        case kMPMessageTypeStringUserIdentityChange:
            return .userIdentityChange
        case kMPMessageTypeStringMedia:
            return .media
        default:
            return .unknown
        }
    }
    
    public class func messageTypeSize() -> UInt {
        return 20
    }
}

// MARK: - Environment Enum
/// Running Environment
@objc public enum MPEnvironment: UInt {
    /// Tells the SDK to auto detect the current run environment (initial value)
    case autoDetect = 0
    /// The SDK is running in development mode (Debug/Development or AdHoc)
    case development
    /// The SDK is running in production mode (App Store)
    case production
}

// MARK: - Event Type Enum
/// Event Types
@objc public enum MPEventType: UInt {
    /// Use for navigation related events
    case navigation = 1
    /// Use for location related events
    case location = 2
    /// Use for search related events
    case search = 3
    /// Use for transaction related events
    case transaction = 4
    /// Use for user content related events
    case userContent = 5
    /// Use for user preference related events
    case userPreference = 6
    /// Use for social related events
    case social = 7
    /// Use for other types of events not contained in this enum
    case other = 8
    /// Internal. Used when an event is related to or sourced from the Media SDK
    case media = 9
    /// Internal. Used when a product is added to the cart
    case addToCart = 10
    /// Internal. Used when a product is removed from the cart
    case removeFromCart = 11
    /// Internal. Used when the cart goes to checkout
    case checkout = 12
    /// Internal. Used when the cart goes to checkout with options
    case checkoutOption = 13
    /// Internal. Used when a product is clicked
    case click = 14
    /// Internal. Used when user views the details of a product
    case viewDetail = 15
    /// Internal. Used when a product is purchased
    case purchase = 16
    /// Internal. Used when a product refunded
    case refund = 17
    /// Internal. Used when a promotion is displayed
    case promotionView = 18
    /// Internal. Used when a promotion is clicked
    case promotionClick = 19
    /// Internal. Used when a product is added to the wishlist
    case addToWishlist = 20
    /// Internal. Used when a product is removed from the wishlist
    case removeFromWishlist = 21
    /// Internal. Used when a product is displayed in a promotion
    case impression = 22
}

// MARK: - Installation Type Enum
/// Installation Types
@objc public enum MPInstallationType: Int {
    /// mParticle auto-detects the installation type. This is the default value
    case autodetect = 0
    /// Informs mParticle this binary is a new installation
    case knownInstall
    /// Informs mParticle this binary is an upgrade
    case knownUpgrade
    /// Informs mParticle this binary is the same version. This value is for internal use only. It should not be used by developers
    case knownSameVersion
}

// MARK: - Location Authorization Request Enum
/// Location Tracking Authorization Request
@objc public enum MPLocationAuthorizationRequest: UInt {
    /// Requests authorization to always use location services
    case always = 0
    /// Requests authorization to use location services when the app is in use
    case whenInUse
}

// MARK: - Product Event Enum
/// eCommerce Product Events
@objc public enum MPProductEvent: Int {
    /// To be used when a product is viewed by a user
    case view = 0
    /// To be used when a user adds a product to a wishlist
    case addedToWishList
    /// To be used when a user removes a product from a wishlist
    case removedFromWishList
    /// To be used when a user adds a product to a cart
    case addedToCart
    /// To be used when a user removes a product from a cart
    case removedFromCart
}

// MARK: - Survey Provider Enum
/// Survey Providers
@objc public enum MPSurveyProvider: UInt {
    /// Foresee survey provider
    case foresee = 64
}

// MARK: - Kit Instance Enum
/// Kit Instance Codes
@objc public enum MPKitInstance: UInt {
    /// Kit code for Urban Airship
    case urbanAirship = 25
    /// Kit code for Appboy
    case appboy = 28
    /// Kit code for Tune
    case tune = 32
    /// Kit code for Kochava
    case kochava = 37
    /// Kit code for comScore
    case comScore = 39
    /// Kit code for Optimizely
    case optimizely = 54
    /// Kit code for Kahuna
    case kahuna = 56
    /// Kit code for Nielsen
    case nielsen = 63
    /// Kit code for Foresee
    case foresee = 64
    /// Kit code for Adjust
    case adjust = 68
    /// Kit code for Branch Metrics
    case branchMetrics = 80
    /// Kit code for Flurry
    case flurry = 83
    /// Kit code for Localytics
    case localytics = 84
    /// Kit code for Apteligent (formerly known as Crittercism)
    case apteligent = 86
    /// Kit code for Wootric
    case wootric = 90
    /// Kit code for AppsFlyer
    case appsFlyer = 92
    /// Kit code for Apptentive
    case apptentive = 97
    /// Kit code for Leanplum
    case leanplum = 98
    /// Kit code for Carnival
    case carnival = 99
    /// Kit code for Primer
    case primer = 100
    /// Kit code for Responsys
    case responsys = 102
    /// Kit code for Apptimize
    case apptimize = 105
    /// Kit code for Reveal Mobile
    case revealMobile = 112
    /// Kit code for Radar
    case radar = 117
    /// Kit code for Skyhook
    case skyhook = 121
    /// Kit code for Iterable
    case iterable = 1003
    /// Kit code for Button
    case button = 1022
    /// Kit code for Singular
    case singular = 119
    /// Kit code for Adobe
    case adobe = 124
    /// Kit code for Instabot
    case instabot = 123
    /// Kit code for Appsee
    case appsee = 126
    /// Kit code for Taplytics
    case taplytics = 129
    /// Kit code for CleverTap
    case cleverTap = 135
    /// Kit code for Pilgrim
    case pilgrim = 211
    /// Kit code for Google Analytics for Firebase
    case googleAnalyticsFirebase = 136
    /// Kit code for Google Analytics 4 for Firebase
    case googleAnalyticsFirebaseGA4 = 160
    /// Kit code for Blueshift
    case blueshift = 1144
}

// MARK: - Log Level Enum
/// Log Levels
@objc public enum MPILogLevel: UInt {
    /// No log messages are displayed on the console
    case none = 0
    /// Only error log messages are displayed on the console
    case error
    /// Warning and error log messages are displayed on the console
    case warning
    /// Debug, warning, and error log messages are displayed on the console
    case debug
    /// Verbose, debug, warning, and error log messages are displayed on the console
    case verbose
}

// MARK: - Upload Type Enum
/// Upload Types
@objc public enum MPUploadType: UInt {
    /// Upload type for messages
    case message = 0
    /// Upload type for alias requests
    case alias = 1
}

// MARK: - Connectivity Error Code Enum
/// Connectivity Error Codes
@objc public enum MPConnectivityErrorCode: UInt {
    /// Client side error: Unknown error.
    case unknown = 0
    /// The device is not online. Please make sure you've initialized the mParticle SDK and that your device has an active network connection.
    case noConnection = 1
    /// Client side error: SSL connection failed to be established due to invalid server certificate. mParticle performs SSL pinning - you cannot use a proxy to read traffic.
    case sslCertificate = 2
}

// MARK: - Identity Error Response Code Enum
/// Identity Error Response Codes
@objc public enum MPIdentityErrorResponseCode: UInt {
    /// Client side error: Unknown error.
    case unknown = 0
    /// Client side error: There is a current Identity API request in progress. Please wait until it has completed and retry your request.
    case requestInProgress = 1
    /// Client side error: Request timed-out while attempting to call the server. Request should be retried when device connectivity has been reestablished.
    case clientSideTimeout = 2
    /// Client side error: Device has no network connection. Request should be retried when device connectivity has been reestablished.
    case clientNoConnection = 3
    /// Client side error: SSL connection failed to be established due to invalid server certificate. mParticle performs SSL pinning - you cannot use a proxy to read traffic.
    case sslError = 4
    /// Client side error: User has enabled OptOut.
    case optOut = 5
    /// HTTP Error 401: Unauthorized. Ensure that you've initialized the mParticle SDK with a valid workspace key and secret.
    case unauthorized = 401
    /// HTTP Error 429: Identity request should be retried
    case retry = 429
    /// HTTP Error 500: Identity request should be retried
    case internalServerError = 500
    /// HTTP Error 502: Identity request should be retried
    case badGateway = 502
    /// HTTP Error 504: Identity request should be retried
    case timeout = 504
}

// MARK: - Wrapper SDK Enum
/// Wrapper SDK Types
@objc public enum MPWrapperSdk: UInt {
    /// No wrapper SDK
    case none = 0
    /// Unity wrapper SDK
    case unity = 1
    /// React Native wrapper SDK
    case reactNative = 2
    /// Cordova wrapper SDK
    case cordova = 3
    /// Xamarin wrapper SDK
    case xamarin = 4
    /// Flutter wrapper SDK
    case flutter = 5
}

// MARK: - ATT Authorization Status Enum
/// App Tracking Transparency Authorization Status
/// - SeeAlso: https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/authorizationstatus
@objc public enum MPATTAuthorizationStatus: UInt {
    /// The user hasn't been asked to authorize access
    case notDetermined = 0
    /// The device is restricted
    case restricted
    /// The user denied authorization
    case denied
    /// The user authorized access
    case authorized
} 