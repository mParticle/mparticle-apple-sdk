import XCTest
import mParticle_Apple_SDK_NoLocation

@objcMembers
class MPDataPlanFilterMock: NSObject, MPDataPlanFilterProtocol {
    var isBlockedUserIdentityTypeCalled = false
    var isBlockedUserIdentityTypeUserIdentityTypeParam: MPIdentity?
    var isBlockedUserIdentityTypeReturnValue: Bool = false

    func isBlockedUserIdentityType(_ userIdentityType: MPIdentity) -> Bool {
        isBlockedUserIdentityTypeCalled = true
        isBlockedUserIdentityTypeUserIdentityTypeParam = userIdentityType
        return isBlockedUserIdentityTypeReturnValue
    }

    var isBlockedUserAttributeKeyCalled = false
    var isBlockedUserAttributeKeyUserAttributeKeyParam: String?
    var isBlockedUserAttributeKeyReturnValue: Bool = false

    func isBlockedUserAttributeKey(_ userAttributeKey: String) -> Bool {
        isBlockedUserAttributeKeyCalled = true
        isBlockedUserAttributeKeyUserAttributeKeyParam = userAttributeKey
        return isBlockedUserAttributeKeyReturnValue
    }

    var transformEventCalled = false
    var transformEventEventParam: MPEvent?
    var transformEventReturnValue: MPEvent?

    func transformEvent(for event: MPEvent) -> MPEvent? {
        transformEventCalled = true
        transformEventEventParam = event
        return transformEventReturnValue
    }

    var transformEventForScreenEventCalled = false
    var transformEventForScreenEventScreenEventParam: MPEvent?
    var transformEventForScreenEventReturnValue: MPEvent?

    func transformEvent(forScreenEvent screenEvent: MPEvent) -> MPEvent? {
        transformEventForScreenEventCalled = true
        transformEventForScreenEventScreenEventParam = screenEvent
        return transformEventForScreenEventReturnValue
    }

    var transformEventForCommerceEventCalled = false
    var transformEventForCommerceEventParam: MPCommerceEvent?
    var transformEventForCommerceEventReturnValue: MPCommerceEvent?

    func transformEvent(forCommerceEvent commerceEvent: MPCommerceEvent) -> MPCommerceEvent? {
        transformEventForCommerceEventCalled = true
        transformEventForCommerceEventParam = commerceEvent
        return transformEventForCommerceEventReturnValue
    }

    var transformEventForBaseEventCalled = false
    var transformEventForBaseEventParam: MPBaseEvent?
    var transformEventForBaseEventReturnValue: MPBaseEvent?

    func transformEvent(forBaseEvent baseEvent: MPBaseEvent) -> MPBaseEvent? {
        transformEventForBaseEventCalled = true
        transformEventForBaseEventParam = baseEvent
        return transformEventForBaseEventReturnValue
    }
}
