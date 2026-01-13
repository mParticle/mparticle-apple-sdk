import XCTest
import mParticle_Apple_SDK_NoLocation

class MPPersistenceControllerMock: MPPersistenceControllerProtocol {
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

    var saveIntegrationAttributesParam: MPIntegrationAttributes?

    func save(_ integrationAttributes: MPIntegrationAttributes) {
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
}
