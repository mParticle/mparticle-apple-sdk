//
//  MPConstants.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 12/3/24.
//
// NOTE: This will temporarily duplicate values from MPIConstants.h to prevent
//       the need to make all our internal constants public during porting
//

// NOTE: I kept the same naming here for clarity, but we should rename these
//       after we remove them from the MPIConstants.h file

let kMParticleSDKVersion = "8.41.1"

enum PushNotifications {
    static let kMPDeviceTokenKey = "to"
    static let kMPPushStatusKey = "r"
    static let kMPPushMessageTypeKey = "t"
    static let kMPPushMessageReceived = "received"
    static let kMPPushMessageAction = "action"
    static let kMPPushMessageSent = "sent"
    static let kMPPushMessageProviderKey = "n"
    static let kMPPushMessageProviderValue = "apn"
    static let kMPPushMessagePayloadKey = "pay"
    static let kMPPushNotificationStateKey = "as"
    static let kMPPushNotificationStateNotRunning = "not_running"
    static let kMPPushNotificationStateBackground = "background"
    static let kMPPushNotificationStateForeground = "foreground"
    static let kMPPushNotificationActionIdentifierKey = "aid"
    static let kMPPushNotificationBehaviorKey = "bhv"
    static let kMPPushNotificationActionTitleKey = "an"
    static let kMPPushNotificationCategoryIdentifierKey = "acid"
}
