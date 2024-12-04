//
//  MPConstants.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 12/3/24.
//
// NOTE: This will temporarily duplicate values from MPIConstants.h to prevent
//       the need to make all our internal constants public during porting
//

func MPMilliseconds(timestamp: Double) -> Double {
    return trunc(timestamp * 1000.0)
}

// NOTE: I kept the same naming here for clarity, but we should rename these
//       after we remove them from the MPIConstants.h file
struct MessageKeys {
    static let kMPMessagesKey = "msgs"
    static let kMPMessageIdKey = "id"
    static let kMPMessageUserIdKey = "mpid"
    static let kMPTimestampKey = "ct"
    static let kMPSessionIdKey = "sid"
    static let kMPSessionStartTimestamp = "sct"
    static let kMPEventStartTimestamp = "est"
    static let kMPEventLength = "el"
    static let kMPEventNameKey = "n"
    static let kMPEventTypeKey = "et"
    static let kMPEventLengthKey = "el"
    static let kMPAttributesKey = "attrs"
    static let kMPLocationKey = "lc"
    static let kMPUserAttributeKey = "ua"
    static let kMPUserAttributeDeletedKey = "uad"
    static let kMPEventTypePageView = "pageview"
    static let kMPUserIdentityArrayKey = "ui"
    static let kMPUserIdentityIdKey = "i"
    static let kMPUserIdentityTypeKey = "n"
    static let kMPUserIdentitySharedGroupIdentifier = "sgi"
    static let kMPAppStateTransitionType = "t"
    static let kMPEventTagsKey = "tags"
    static let kMPLeaveBreadcrumbsKey = "l"
    static let kMPOptOutKey = "oo"
    static let kMPDateUserIdentityWasFirstSet = "dfs"
    static let kMPIsFirstTimeUserIdentityHasBeenSet = "f"
    static let kMPRemoteNotificationContentIdHistoryKey = "cntid"
    static let kMPRemoteNotificationTimestampHistoryKey = "ts"
    static let kMPForwardStatsRecord = "fsr"
    static let kMPEventCustomFlags = "flags"
    static let kMPContextKey = "ctx"
    static let kMPDataPlanKey = "dpln"
    static let kMPDataPlanIdKey = "id"
    static let kMPDataPlanVersionKey = "v"
}
