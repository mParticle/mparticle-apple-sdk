import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPIdentityDTOTests: XCTestCase {
    func testIdentityTypeRoundTrip() {
        for type in 0...MPIdentitySwift.deviceApplicationStamp.rawValue where type != MPIdentitySwift.alias.rawValue {
            let string = MPIdentityHTTPIdentitiesPRIVATE.string(forIdentityType: type)
            XCTAssertNotNil(string, "missing string for \(type)")
            XCTAssertEqual(MPIdentityHTTPIdentitiesPRIVATE.identityType(for: string), NSNumber(value: type))
        }
        XCTAssertNil(MPIdentityHTTPIdentitiesPRIVATE.string(forIdentityType: MPIdentitySwift.alias.rawValue))
        XCTAssertNil(MPIdentityHTTPIdentitiesPRIVATE.identityType(for: "unknown"))
    }

    func testIdentitiesDictionaryRepresentation() {
        let identities = MPIdentityHTTPIdentitiesPRIVATE(identities: [
            NSNumber(value: MPIdentitySwift.email.rawValue): "a@b.com",
            NSNumber(value: MPIdentitySwift.customerId.rawValue): "cust",
            NSNumber(value: MPIdentitySwift.iosAdvertiserId.rawValue): "idfa"
        ], attAuthorizationStatus: nil)
        let dictionary = identities.dictionaryRepresentation()
        XCTAssertEqual(dictionary["email"] as? String, "a@b.com")
        XCTAssertEqual(dictionary["customerid"] as? String, "cust")
        XCTAssertEqual(dictionary["ios_idfa"] as? String, "idfa")
    }

    func testIdentitiesPreservesNSNullValues() {
        let identities = MPIdentityHTTPIdentitiesPRIVATE(identities: [
            NSNumber(value: MPIdentitySwift.google.rawValue): NSNull(),
            NSNumber(value: MPIdentitySwift.email.rawValue): "a@b.com"
        ], attAuthorizationStatus: nil)
        let dictionary = identities.dictionaryRepresentation()
        XCTAssertEqual(dictionary["google"] as? NSNull, NSNull())
        XCTAssertEqual(dictionary["email"] as? String, "a@b.com")
    }

    func testIdentitiesSkipsIDFAWhenATTDenied() {
        let identities = MPIdentityHTTPIdentitiesPRIVATE(identities: [
            NSNumber(value: MPIdentitySwift.iosAdvertiserId.rawValue): "idfa",
            NSNumber(value: MPIdentitySwift.email.rawValue): "a@b.com"
        ], attAuthorizationStatus: NSNumber(value: MPATTAuthorizationStatusSwift.denied.rawValue))
        XCTAssertNil(identities.advertiserId)
        XCTAssertEqual(identities.email, "a@b.com")
    }

    func testIdentitiesPreservesNonStringValues() {
        let identities = MPIdentityHTTPIdentitiesPRIVATE(identities: [
            NSNumber(value: MPIdentitySwift.google.rawValue): NSNumber(value: 12_345),
            NSNumber(value: MPIdentitySwift.other.rawValue): ["nested": "value"]
        ], attAuthorizationStatus: nil)
        let dictionary = identities.dictionaryRepresentation()
        XCTAssertEqual(dictionary["google"] as? NSNumber, 12_345)
        XCTAssertEqual((dictionary["other"] as? NSDictionary)?["nested"] as? String, "value")
    }

    func testIdentityChangeDefaultInitSerializesNSNullValues() {
        let dictionary = MPIdentityHTTPIdentityChangePRIVATE().dictionaryRepresentation()
        XCTAssertEqual(dictionary["old_value"] as? NSNull, NSNull())
        XCTAssertEqual(dictionary["new_value"] as? NSNull, NSNull())
        XCTAssertNil(dictionary["identity_type"])
    }

    func testIdentityChangeUsesNSNullForMissingValues() {
        let change = MPIdentityHTTPIdentityChangePRIVATE(oldValue: nil, value: nil, identityType: "email")
        let dictionary = change.dictionaryRepresentation()
        XCTAssertEqual(dictionary["old_value"] as? NSNull, NSNull())
        XCTAssertEqual(dictionary["new_value"] as? NSNull, NSNull())
        XCTAssertEqual(dictionary["identity_type"] as? String, "email")
    }

    func testSuccessFieldsParseMPID() {
        let fields = MPIdentityHTTPRequestBuilderPRIVATE.successFields(from: [
            "mpid": "42",
            "context": "ctx",
            "is_ephemeral": true,
            "is_logged_in": true,
            "change_results": [["modified_mpid": 1]]
        ])
        XCTAssertEqual(fields["mpid"] as? NSNumber, 42)
        XCTAssertEqual(fields["context"] as? String, "ctx")
        XCTAssertEqual((fields["is_ephemeral"] as? NSNumber)?.boolValue, true)
        XCTAssertEqual((fields["change_results"] as? NSArray)?.count, 1)
    }

    func testClientSDKPlatform() {
        let dictionary = MPIdentityHTTPRequestBuilderPRIVATE.clientSDKDictionary(withVersion: "9.4.0")
        XCTAssertEqual(dictionary["sdk_vendor"] as? String, "mparticle")
        XCTAssertEqual(dictionary["sdk_version"] as? String, "9.4.0")
        #if os(tvOS)
        XCTAssertEqual(dictionary["platform"] as? String, "tvos")
        #else
        XCTAssertEqual(dictionary["platform"] as? String, "ios")
        #endif
    }
}

final class MPIdentityApiLogicTests: XCTestCase {
    func testAliasPlanRejectsInvalidUsers() {
        XCTAssertFalse(MPIdentityAliasPlanPRIVATE.plan(
            sourceMPID: nil,
            destinationMPID: 2,
            startTime: nil,
            endTime: nil,
            usedFirstLastSeen: false,
            aliasMaxWindow: nil
        ).isValid)
        XCTAssertFalse(MPIdentityAliasPlanPRIVATE.plan(
            sourceMPID: 1,
            destinationMPID: 1,
            startTime: nil,
            endTime: nil,
            usedFirstLastSeen: false,
            aliasMaxWindow: nil
        ).isValid)
    }

    func testAliasPlanFillsMissingDates() {
        let plan = MPIdentityAliasPlanPRIVATE.plan(
            sourceMPID: 1,
            destinationMPID: 2,
            startTime: nil,
            endTime: nil,
            usedFirstLastSeen: false,
            aliasMaxWindow: 90
        )
        XCTAssertTrue(plan.isValid)
        XCTAssertNotNil(plan.startTime)
        XCTAssertNotNil(plan.endTime)
    }

    func testSortedIndexesByLastSeen() {
        let dates = [
            Date(timeIntervalSince1970: 1),
            Date(timeIntervalSince1970: 3),
            Date(timeIntervalSince1970: 2)
        ]
        XCTAssertEqual(MPIdentityApiLogicPRIVATE.sortedIndexes(byLastSeen: dates as NSArray), [1, 2, 0])
    }

    func testParsedModifyChangesSkipsInvalidTypes() {
        let parsed = MPIdentityApiLogicPRIVATE.parsedModifyChanges([
            ["modified_mpid": 9, "identity_type": "email"],
            ["modified_mpid": 9, "identity_type": "not-a-type"],
            ["identity_type": "email"]
        ])
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(
            (parsed[0] as? NSDictionary)?["identity_type_number"] as? NSNumber,
            NSNumber(value: MPIdentitySwift.email.rawValue)
        )
        XCTAssertNil((parsed[1] as? NSDictionary)?["identity_type_number"])
    }
}

final class MPIdentityUserStorageTests: XCTestCase {
    func testDateFromMilliseconds() {
        let date = MPIdentityUserStoragePRIVATE.date(fromMilliseconds: 1_000)
        XCTAssertEqual(date.timeIntervalSince1970, 1, accuracy: 0.001)
        XCTAssertEqual(MPIdentityUserStoragePRIVATE.date(fromMilliseconds: nil).timeIntervalSince1970, 0, accuracy: 0.001)
    }

    func testApplyingIdentityAddsReplacesAndRemoves() {
        let added = MPIdentityUserStoragePRIVATE.applyingIdentity(
            "a@b.com",
            type: MPIdentitySwift.email.rawValue,
            toStoredArray: nil
        )
        XCTAssertEqual(added.count, 1)

        let replaced = MPIdentityUserStoragePRIVATE.applyingIdentity(
            "c@d.com",
            type: MPIdentitySwift.email.rawValue,
            toStoredArray: added
        )
        XCTAssertEqual(replaced.count, 1)
        XCTAssertEqual((replaced[0] as? NSDictionary)?[MessageKeys.kMPUserIdentityIdKey] as? String, "c@d.com")

        let removed = MPIdentityUserStoragePRIVATE.applyingIdentity(
            NSNull(),
            type: MPIdentitySwift.email.rawValue,
            toStoredArray: replaced
        )
        XCTAssertEqual(removed.count, 0)
    }

    func testSkipEmptyAttribute() {
        XCTAssertTrue(MPIdentityUserStoragePRIVATE.shouldSkipEmptyAttributeValue(""))
        XCTAssertFalse(MPIdentityUserStoragePRIVATE.shouldSkipEmptyAttributeValue("x"))
        XCTAssertFalse(MPIdentityUserStoragePRIVATE.shouldSkipEmptyAttributeValue(1))
    }

    func testIsUserIdentity() {
        XCTAssertTrue(MPIdentityUserStoragePRIVATE.isUserIdentity(MPIdentitySwift.email.rawValue))
        XCTAssertTrue(MPIdentityUserStoragePRIVATE.isUserIdentity(MPIdentitySwift.phoneNumber3.rawValue))
        XCTAssertFalse(MPIdentityUserStoragePRIVATE.isUserIdentity(MPIdentitySwift.iosAdvertiserId.rawValue))
    }
}
