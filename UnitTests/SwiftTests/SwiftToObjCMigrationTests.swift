import XCTest
@testable import mParticle_Apple_SDK

/// Tests to verify Swift classes migrated to Objective-C work correctly in SDK 9.0
final class SwiftToObjCMigrationTests: XCTestCase {

    // MARK: - MPCCPAConsent Tests

    func test_MPCCPAConsent_canBeInstantiated() {
        let consent = MPCCPAConsent()
        XCTAssertNotNil(consent)
    }

    func test_MPCCPAConsent_propertiesAccessible() {
        let consent = MPCCPAConsent()
        consent.consented = true
        consent.document = "test_document"
        consent.timestamp = Date()
        consent.location = "test_location"
        consent.hardwareId = "test_hardware_id"

        XCTAssertTrue(consent.consented)
        XCTAssertEqual(consent.document, "test_document")
        XCTAssertNotNil(consent.timestamp)
        XCTAssertEqual(consent.location, "test_location")
        XCTAssertEqual(consent.hardwareId, "test_hardware_id")
    }

    func test_MPCCPAConsent_defaultValues() {
        let consent = MPCCPAConsent()
        XCTAssertFalse(consent.consented)
        XCTAssertNil(consent.document)
        XCTAssertNil(consent.location)
        XCTAssertNil(consent.hardwareId)
    }

    func test_MPCCPAConsent_classExists() {
        let consentClass: AnyClass? = NSClassFromString("MPCCPAConsent")
        XCTAssertNotNil(consentClass, "MPCCPAConsent should exist as ObjC class")
    }

    // MARK: - MPGDPRConsent Tests

    func test_MPGDPRConsent_canBeInstantiated() {
        let consent = MPGDPRConsent()
        XCTAssertNotNil(consent)
    }

    func test_MPGDPRConsent_propertiesAccessible() {
        let consent = MPGDPRConsent()
        consent.consented = true
        consent.document = "gdpr_document"
        consent.timestamp = Date()
        consent.location = "gdpr_location"
        consent.hardwareId = "gdpr_hardware_id"

        XCTAssertTrue(consent.consented)
        XCTAssertEqual(consent.document, "gdpr_document")
        XCTAssertNotNil(consent.timestamp)
        XCTAssertEqual(consent.location, "gdpr_location")
        XCTAssertEqual(consent.hardwareId, "gdpr_hardware_id")
    }

    func test_MPGDPRConsent_defaultValues() {
        let consent = MPGDPRConsent()
        XCTAssertFalse(consent.consented)
        XCTAssertNil(consent.document)
        XCTAssertNil(consent.location)
        XCTAssertNil(consent.hardwareId)
    }

    func test_MPGDPRConsent_classExists() {
        let consentClass: AnyClass? = NSClassFromString("MPGDPRConsent")
        XCTAssertNotNil(consentClass, "MPGDPRConsent should exist as ObjC class")
    }

    // MARK: - MPSideloadedKit Tests

    func test_MPSideloadedKit_canBeInstantiated() {
        let kit = MPSideloadedKit()
        XCTAssertNotNil(kit)
    }

    func test_MPSideloadedKit_classExists() {
        let kitClass: AnyClass? = NSClassFromString("MPSideloadedKit")
        XCTAssertNotNil(kitClass, "MPSideloadedKit should exist as ObjC class")
    }

    // MARK: - SceneDelegateHandler Tests

    func test_SceneDelegateHandler_classExists() {
        let handlerClass: AnyClass? = NSClassFromString("SceneDelegateHandler")
        XCTAssertNotNil(handlerClass, "SceneDelegateHandler should exist")
    }

    // MARK: - Consent State Integration Tests

    func test_MPConsentState_canAddCCPAConsent() {
        let consentState = MPConsentState()
        let ccpaConsent = MPCCPAConsent()
        ccpaConsent.consented = false

        consentState.setCCPA(ccpaConsent)

        let retrievedConsent = consentState.ccpaConsentState()
        XCTAssertNotNil(retrievedConsent)
        XCTAssertFalse(retrievedConsent!.consented)
    }

    func test_MPConsentState_canAddGDPRConsent() {
        let consentState = MPConsentState()
        let gdprConsent = MPGDPRConsent()
        gdprConsent.consented = true
        gdprConsent.document = "privacy_policy_v1"

        consentState.addGDPRConsentState(gdprConsent, purpose: "marketing")

        let gdprStates = consentState.gdprConsentState()
        XCTAssertNotNil(gdprStates)
        XCTAssertNotNil(gdprStates?["marketing"])
        XCTAssertTrue(gdprStates?["marketing"]?.consented ?? false)
    }

    func test_MPConsentState_canRemoveGDPRConsent() {
        let consentState = MPConsentState()
        let gdprConsent = MPGDPRConsent()
        gdprConsent.consented = true

        consentState.addGDPRConsentState(gdprConsent, purpose: "analytics")
        XCTAssertNotNil(consentState.gdprConsentState()?["analytics"])

        consentState.removeGDPRConsentState(withPurpose: "analytics")
        XCTAssertNil(consentState.gdprConsentState()?["analytics"])
    }

    // MARK: - MPCCPAConsent NSCopying Tests

    func test_MPCCPAConsent_conformsToNSCopying() {
        let consent = MPCCPAConsent()
        consent.consented = true
        consent.document = "original_doc"

        let copy = consent.copy() as! MPCCPAConsent

        XCTAssertTrue(copy.consented)
        XCTAssertEqual(copy.document, "original_doc")
        XCTAssertFalse(consent === copy, "Copy should be a different instance")
    }

    // MARK: - MPGDPRConsent NSCopying Tests

    func test_MPGDPRConsent_conformsToNSCopying() {
        let consent = MPGDPRConsent()
        consent.consented = true
        consent.document = "gdpr_original_doc"

        let copy = consent.copy() as! MPGDPRConsent

        XCTAssertTrue(copy.consented)
        XCTAssertEqual(copy.document, "gdpr_original_doc")
        XCTAssertFalse(consent === copy, "Copy should be a different instance")
    }
}
