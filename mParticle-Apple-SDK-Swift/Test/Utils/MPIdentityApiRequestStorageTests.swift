import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPIdentityApiRequestStorageTests: XCTestCase {

    private func key(_ type: MPIdentitySwift) -> NSNumber { NSNumber(value: type.rawValue) }

    func testSetNilIdentityStoresNull() {
        let storage = MPIdentityApiRequestStoragePRIVATE()
        storage.setIdentity("foo", identityType: MPIdentitySwift.other.rawValue)
        XCTAssertEqual(storage.mutableIdentities[key(.other)] as? String, "foo")
        storage.setIdentity(nil, identityType: MPIdentitySwift.other.rawValue)
        XCTAssertTrue(storage.mutableIdentities[key(.other)] is NSNull)
    }

    func testSetNSNullIdentityStoresNull() {
        let storage = MPIdentityApiRequestStoragePRIVATE()
        storage.setIdentity(NSNull(), identityType: MPIdentitySwift.other.rawValue)
        XCTAssertTrue(storage.mutableIdentities[key(.other)] is NSNull)
    }

    func testEmptyStringIsIgnored() {
        let storage = MPIdentityApiRequestStoragePRIVATE()
        storage.setIdentity("", identityType: MPIdentitySwift.other.rawValue)
        XCTAssertNil(storage.mutableIdentities[key(.other)])
    }

    func testSetIdentityOverwrites() {
        let storage = MPIdentityApiRequestStoragePRIVATE()
        storage.setIdentity("foo", identityType: MPIdentitySwift.other.rawValue)
        storage.setIdentity("bar", identityType: MPIdentitySwift.other.rawValue)
        XCTAssertEqual(storage.mutableIdentities[key(.other)] as? String, "bar")
    }

    func testIdentitiesSnapshotIsImmutable() {
        let storage = MPIdentityApiRequestStoragePRIVATE()
        storage.setIdentity("foo", identityType: MPIdentitySwift.other.rawValue)
        XCTAssertFalse(storage.identities is NSMutableDictionary)
        XCTAssertEqual(storage.identities[key(.other)] as? String, "foo")
    }

    func testEmailMapsToEmailType() {
        let storage = MPIdentityApiRequestStoragePRIVATE()
        XCTAssertNil(storage.email)
        storage.email = "test@test.com"
        XCTAssertEqual(storage.email, "test@test.com")
        XCTAssertEqual(storage.mutableIdentities[key(.email)] as? String, "test@test.com")
        storage.email = nil
        XCTAssertNil(storage.email)
        XCTAssertTrue(storage.mutableIdentities[key(.email)] is NSNull)
    }

    func testCustomerIdMapsToCustomerIdType() {
        let storage = MPIdentityApiRequestStoragePRIVATE()
        storage.customerId = "some id"
        XCTAssertEqual(storage.customerId, "some id")
        XCTAssertEqual(storage.mutableIdentities[key(.customerId)] as? String, "some id")
    }

    func testShaAccessorsUseDistinctSlots() {
        let storage = MPIdentityApiRequestStoragePRIVATE()
        storage.emailSha256 = "emailhash"
        storage.mobileSha256 = "mobilehash"
        XCTAssertEqual(storage.emailSha256, "emailhash")
        XCTAssertEqual(storage.mobileSha256, "mobilehash")
        XCTAssertEqual(storage.mutableIdentities[key(.other)] as? String, "emailhash")
        XCTAssertEqual(storage.mutableIdentities[key(.other2)] as? String, "mobilehash")
    }
}
