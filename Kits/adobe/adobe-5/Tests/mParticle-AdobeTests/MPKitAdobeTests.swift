@testable import mParticle_Adobe
import Foundation
import XCTest

extension URLSession: @retroactive SessionProtocol {
}

final class MPKitAdobeTests: XCTestCase {
    var session: SessionProtocolMock!

    override func setUp() {
        super.setUp()
        session = SessionProtocolMock()
    }

    func testKitCode() {
        let expectedKitCode: NSNumber = 124
        let actualKitCode = MPKitAdobe.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 124")
    }

    func testSendRequestEncodeAllParametersIntoURL() {
        let sut = MPIAdobe(session: session)!
        sut.sendRequest(
            withMarketingCloudId: "marketingCloudId",
            advertiserId: "advertiserId",
            pushToken: "pushToken",
            organizationId: "organizationId",
            userIdentities: [
                NSNumber(value: MPUserIdentity.other.rawValue): "1",
                NSNumber(value: MPUserIdentity.customerId.rawValue): "2",
                NSNumber(value: MPUserIdentity.facebook.rawValue): "3",
                NSNumber(value: MPUserIdentity.twitter.rawValue): "4",
                NSNumber(value: MPUserIdentity.google.rawValue): "5",
                NSNumber(value: MPUserIdentity.microsoft.rawValue): "6",
                NSNumber(value: MPUserIdentity.yahoo.rawValue): "7",
                NSNumber(value: MPUserIdentity.email.rawValue): "8",
                NSNumber(value: MPUserIdentity.alias.rawValue): "9",
                NSNumber(value: MPUserIdentity.facebookCustomAudienceId.rawValue): "10",
                NSNumber(value: MPUserIdentity.other5.rawValue): "11"
            ],
            audienceManagerServer: "audienceManagerServer"
        ) { _, _, _, _ in }

        let expected =
            "https://audienceManagerServer/id?d_mid=marketingCloudId&d_cid=20915%2501advertiserId&d_cid=20920%2501pushToken&d_cid_ic=google%25015&d_cid_ic=facebook%25013&d_cid_ic=customerid%25012&d_cid_ic=twitter%25014&d_cid_ic=alias%25019&d_cid_ic=microsoft%25016&d_cid_ic=email%25018&d_cid_ic=yahoo%25017&d_cid_ic=other%25011&d_cid_ic=facebookcustomaudienceid%250110&d_orgid=organizationId&d_ptfm=ios&d_ver=2"

        guard
            let actualURL = session.dataTaskRequestParam?.url,
            let expectedURL = URL(string: expected),
            let actualComponents = URLComponents(url: actualURL, resolvingAgainstBaseURL: false),
            let expectedComponents = URLComponents(url: expectedURL, resolvingAgainstBaseURL: false)
        else {
            XCTFail("URLs could not be parsed")
            return
        }

        XCTAssertEqual(actualComponents.scheme, expectedComponents.scheme)
        XCTAssertEqual(actualComponents.host, expectedComponents.host)
        XCTAssertEqual(actualComponents.path, expectedComponents.path)

        let actualItems = Set(actualComponents.queryItems ?? [])
        let expectedItems = Set(expectedComponents.queryItems ?? [])

        XCTAssertEqual(actualItems, expectedItems)
    }

    func testCompletionCallback_success() throws {
        let sut = MPIAdobe(session: session)!
        sut.sendRequest(
            withMarketingCloudId: "",
            advertiserId: "",
            pushToken: "",
            organizationId: "",
            userIdentities: [:],
            audienceManagerServer: ""
        ) { marketingCloudId, locationHint, blob, error in
            XCTAssertNil(error)
            XCTAssertEqual(marketingCloudId, "mock_mid")
            XCTAssertEqual(locationHint, "mock_region")
            XCTAssertEqual(blob, "mock_blob")
        }

        let json: [String: Any] = [
            "d_mid": "mock_mid",
            "d_blob": "mock_blob",
            "dcs_region": "mock_region"
        ]

        let data = try JSONSerialization.data(withJSONObject: json, options: [])

        session.dataTaskCompletionHandlerParam?(data, URLResponse(), nil)
    }

    func testCompletionCallback_success_empty_json() throws {
        let sut = MPIAdobe(session: session)!
        sut.sendRequest(
            withMarketingCloudId: "",
            advertiserId: "",
            pushToken: "",
            organizationId: "",
            userIdentities: [:],
            audienceManagerServer: ""
        ) { marketingCloudId, locationHint, blob, error in
            XCTAssertNil(error)
            XCTAssertNil(marketingCloudId)
            XCTAssertNil(locationHint)
            XCTAssertNil(blob)
        }

        let json: [String: Any] = [:]

        let data = try JSONSerialization.data(withJSONObject: json, options: [])

        session.dataTaskCompletionHandlerParam?(data, URLResponse(), nil)
    }

    func testCompletionCallback_success_parametersNotStrings() throws {
        let sut = MPIAdobe(session: session)!
        sut.sendRequest(
            withMarketingCloudId: "",
            advertiserId: "",
            pushToken: "",
            organizationId: "",
            userIdentities: [:],
            audienceManagerServer: ""
        ) { marketingCloudId, locationHint, blob, error in
            XCTAssertNil(error)
            XCTAssertNil(marketingCloudId)
            XCTAssertNil(locationHint)
            XCTAssertNil(blob)
        }

        let json: [String: Any] = [
            "d_mid": 1,
            "d_blob": 2,
            "dcs_region": 3
        ]

        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        session.dataTaskCompletionHandlerParam?(data, URLResponse(), nil)
    }

    func testCompletionCallback_success_errorFromBackend() throws {
        let sut = MPIAdobe(session: session)!
        sut.sendRequest(
            withMarketingCloudId: "",
            advertiserId: "",
            pushToken: "",
            organizationId: "",
            userIdentities: [:],
            audienceManagerServer: ""
        ) { marketingCloudId, locationHint, blob, error in
            XCTAssertNil(marketingCloudId)
            XCTAssertNil(locationHint)
            XCTAssertNil(blob)
            XCTAssertNotNil(error)
        }

        let json: [String: Any] = [
            "error_msg": [
                "some_key": "Invalid request parameters"
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        session.dataTaskCompletionHandlerParam?(data, URLResponse(), nil)
    }

    func testCompletionCallback_success_errorErrorMsgContains_shouldNotCrash() throws {
        let sut = MPIAdobe(session: session)!
        sut.sendRequest(
            withMarketingCloudId: "",
            advertiserId: "",
            pushToken: "",
            organizationId: "",
            userIdentities: [:],
            audienceManagerServer: ""
        ) { marketingCloudId, locationHint, blob, error in
            XCTAssertNil(marketingCloudId)
            XCTAssertNil(locationHint)
            XCTAssertNil(blob)
            XCTAssertNotNil(error)
        }

        let json: [String: Any] = [
            "error_msg": "Invalid request parameters"
        ]

        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        session.dataTaskCompletionHandlerParam?(data, URLResponse(), nil)
    }
}
