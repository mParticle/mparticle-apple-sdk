import XCTest
import mParticle_Apple_SDK
internal import mParticle_Apple_SDK_Swift

class MPPersistenceControllerMock: NSObject, MPPersistenceAdapting {
    func appAndDeviceInfo(forSessionId sessionId: NSNumber) -> [String: [AnyHashable: Any]] {
        [:]
    }

    func fetchForwardRecords() -> [MPForwardRecord]? { nil }

    var resetDatabaseForWorkspaceSwitchingCalled = false

    func resetDatabaseForWorkspaceSwitching() {
        resetDatabaseForWorkspaceSwitchingCalled = true
    }

    var resetDatabaseCalled = false

    func resetDatabase() {
        resetDatabaseCalled = true
    }

    var saveCalled = false
    var saveForwardRecordParam: MPForwardRecord?

    func save(_ forwardRecord: MPForwardRecord) {
        saveCalled = true
        saveForwardRecordParam = forwardRecord
    }

    func deleteForwardRecordsIds(_ recordIds: [NSNumber]) {}

    func fetchIntegrationAttributes() -> [MPIntegrationAttributesPRIVATE]? { nil }

    var saveIntegrationAttributesParam: MPIntegrationAttributesPRIVATE?

    func save(_ integrationAttributes: MPIntegrationAttributesPRIVATE) {
        saveCalled = true
        saveIntegrationAttributesParam = integrationAttributes
    }

    var deleteIntegrationAttributesCalled = false
    var deleteIntegrationAttributesIntegrationIdParam: NSNumber?

    func deleteIntegrationAttributes(forIntegrationId integrationId: NSNumber) {
        deleteIntegrationAttributesCalled = true
        deleteIntegrationAttributesIntegrationIdParam = integrationId
    }

    var fetchIntegrationAttributesCalled = false
    var fetchIntegrationAttributesIntegrationIdParam: NSNumber?
    var fetchIntegrationAttributesReturnValue: [AnyHashable: Any]?

    func fetchIntegrationAttributes(forId integrationId: NSNumber) -> [AnyHashable: Any]? {
        fetchIntegrationAttributesCalled = true
        fetchIntegrationAttributesIntegrationIdParam = integrationId
        return fetchIntegrationAttributesReturnValue
    }

    func deleteAllIntegrationAttributes() {}
    func fetchConsumerInfo(forUserId userId: NSNumber) -> MPConsumerInfoPRIVATE? { nil }
    func fetchCookies(forUserId userId: NSNumber) -> [MPCookiePRIVATE]? { nil }
    func save(_ consumerInfo: MPConsumerInfoPRIVATE) {}
    func update(_ consumerInfo: MPConsumerInfoPRIVATE) {}
}
