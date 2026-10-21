import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendHostTests: XCTestCase {
    func testMessageContextTakesTheHostsDataPlanAndLogger() {
        let host = MPBackendFakeHost()
        host.planId = "plan"
        host.planVersion = 3

        let context = MPMessageBuilderContext(host: host)

        XCTAssertEqual(context.dataPlanId, "plan")
        XCTAssertEqual(context.dataPlanVersion, 3)
        XCTAssertTrue(context.logger === host.log)
        XCTAssertEqual(host.calls, ["dataPlanId", "dataPlanVersion", "sdkLogger"])
    }

    func testUploadContextAsksTheHostWhenEachProviderRuns() {
        let host = MPBackendFakeHost()
        let persistence = MPUploadEnrichmentMock()
        let context = MPUploadBuilderContext(host: host, persistence: { persistence })
        // Set after the context exists: providers read the host when called, not when built.
        host.lifetimeValues[7] = 12
        host.advertiserIDs[7] = "advertiser"
        host.consents[7] = ["ccpa": ["c": true]]
        host.batchTransform = { _ in ["transformed": true] }

        XCTAssertTrue(context.stateMachine() === host.machine)
        XCTAssertEqual(context.lifetimeValue(7), 12)
        XCTAssertTrue(context.persistence() === persistence)
        XCTAssertEqual(context.applicationInfo(host.machine), host.applicationInfoValue)
        XCTAssertEqual(context.deviceInfo(7), host.deviceInfoValue)
        XCTAssertEqual(context.advertiserID(7), "advertiser")
        XCTAssertEqual(context.consent(7), ["ccpa": ["c": true]])
        XCTAssertEqual(context.transformBatch(["batch": 1]) as? NSDictionary, ["transformed": true])
        XCTAssertTrue(context.logger() === host.log)

        XCTAssertEqual(host.calls, [
            "sdkVersion", "stateMachine", "lifetimeValue:7", "applicationInfo", "deviceInfo:7",
            "advertiserID:7", "consent:7", "transformBatch", "sdkLogger"
        ])
        XCTAssertTrue(host.applicationInfoMachines.first === host.machine)
    }

    func testUploadContextPassesThroughAbsentValues() {
        let host = MPBackendFakeHost()
        host.log = nil
        host.batchTransform = { _ in nil }
        let context = MPUploadBuilderContext(host: host, persistence: { MPUploadEnrichmentMock() })

        XCTAssertNil(context.advertiserID(7))
        XCTAssertNil(context.consent(7))
        XCTAssertNil(context.transformBatch(["batch": 1]))
        XCTAssertNil(context.logger())
    }

    func testUploadContextTakesTheSDKVersionWhenBuilt() {
        let host = MPBackendFakeHost()
        host.version = "1.2.3"
        let context = MPUploadBuilderContext(host: host, persistence: { MPUploadEnrichmentMock() })
        host.version = "9.9.9"

        XCTAssertEqual(context.sdkVersion, "1.2.3")
    }
}
