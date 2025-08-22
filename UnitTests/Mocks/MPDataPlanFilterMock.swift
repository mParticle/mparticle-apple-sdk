import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif

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
}
