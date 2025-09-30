import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

class MPKitContainerMock: MPKitContainerProtocol {
    var attributionInfo: NSMutableDictionary = .init()

    var kitsInitialized: Bool = false

    var forwardCommerceEventCallCalled = false
    var forwardCommerceEventCallCommerceEventParam: MPCommerceEvent?

    func forwardCommerceEventCall(_ commerceEvent: MPCommerceEvent) {
        forwardCommerceEventCallCalled = true
        forwardCommerceEventCallCommerceEventParam = commerceEvent
    }

    var forwardSDKCallCalled = false
    var forwardSDKCallSelectorParam: Selector?
    var forwardSDKCallKitHandlerParam: ((any MPKitProtocol, [AnyHashable: Any], MPKitConfiguration) -> Void)?
    var forwardSDKCallExpectation: XCTestExpectation?

    var forwardSDKCallEventParam: MPBaseEvent?
    var forwardSDKCallParametersParam: MPForwardQueueParameters?
    var forwardSDKCallMessageTypeParam: MPMessageType?
    var forwardSDKCallUserInfoParam: [AnyHashable: Any]?

    func forwardSDKCall(_ selector: Selector,
                        event: MPBaseEvent?,
                        parameters: MPForwardQueueParameters?,
                        messageType: MPMessageType,
                        userInfo: [AnyHashable: Any]? = nil)
    {
        forwardSDKCallCalled = true
        forwardSDKCallSelectorParam = selector
        forwardSDKCallEventParam = event
        forwardSDKCallParametersParam = parameters
        forwardSDKCallMessageTypeParam = messageType
        forwardSDKCallUserInfoParam = userInfo
        forwardSDKCallExpectation?.fulfill()
    }

    var forwardSDKCallBatchParam: [AnyHashable: Any]?

    func forwardSDKCall(_ selector: Selector,
                        batch: [AnyHashable: Any],
                        kitHandler: @escaping (any MPKitProtocol, [AnyHashable: Any], MPKitConfiguration) -> Void)
    {
        forwardSDKCallCalled = true
        forwardSDKCallSelectorParam = selector
        forwardSDKCallBatchParam = batch
        forwardSDKCallKitHandlerParam = kitHandler
        forwardSDKCallExpectation?.fulfill()
    }

    var forwardSDKCallUserAttributes: [AnyHashable: Any]?

    func forwardSDKCall(_ selector: Selector,
                        userAttributes: [AnyHashable: Any] = [:],
                        kitHandler: @escaping (any MPKitProtocol, [AnyHashable: Any]?, MPKitConfiguration) -> Void)
    {
        forwardSDKCallCalled = true
        forwardSDKCallSelectorParam = selector
        forwardSDKCallUserAttributes = userAttributes
        forwardSDKCallKitHandlerParam = kitHandler
        forwardSDKCallExpectation?.fulfill()
    }

    var configureKitsCalled = false
    var configureKitsKitsConfigurationParam: [[AnyHashable: Any]]?

    func configureKits(_ kitsConfiguration: [[AnyHashable: Any]]?) {
        configureKitsCalled = true
        configureKitsKitsConfigurationParam = kitsConfiguration
    }

    var removeKitsFromRegistryInvalidForWorkspaceSwitchCalled = false

    func removeKitsFromRegistryInvalidForWorkspaceSwitch() {
        removeKitsFromRegistryInvalidForWorkspaceSwitchCalled = true
    }

    var flushSerializedKitsCalled = false

    func flushSerializedKits() {
        flushSerializedKitsCalled = true
    }

    var removeAllSideloadedKitsCalled = false

    func removeAllSideloadedKits() {
        removeAllSideloadedKitsCalled = true
    }

    var hasKitBatchingKitsCalled = false
    var hasKitBatchingKitsReturnValue: Bool = false

    func hasKitBatchingKits() -> Bool {
        hasKitBatchingKitsCalled = true
        return hasKitBatchingKitsReturnValue
    }
}
