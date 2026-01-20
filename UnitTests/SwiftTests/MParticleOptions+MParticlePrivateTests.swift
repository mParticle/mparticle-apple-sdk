import XCTest
import mParticle_Apple_SDK_NoLocation

class MParticleOptionsMParticlePrivateTests: XCTestCase {
    var sut: MParticleOptions!

    override func setUp() {
        super.setUp()
        sut = MParticleOptions()
    }

    func testInit() {
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.collectUserAgent)
        XCTAssertFalse(sut.collectSearchAdsAttribution)
        XCTAssertTrue(sut.trackNotifications)
        XCTAssertTrue(sut.automaticSessionTracking)
        XCTAssertTrue(sut.shouldBeginSession)
        XCTAssertFalse(sut.startKitsAsync)

        XCTAssertEqual(sut.logLevel, .none)
        XCTAssertEqual(sut.uploadInterval, 0.0)
        XCTAssertEqual(sut.sessionTimeout, 60.0)

        XCTAssertEqual(sut.apiKey, "")
        XCTAssertEqual(sut.apiSecret, "")
        XCTAssertEqual(sut.sharedGroupID, "")
        XCTAssertEqual(sut.installType, .autodetect)
        XCTAssertEqual(sut.identifyRequest, nil)
        XCTAssertEqual(sut.environment, .autoDetect)
        XCTAssertEqual(sut.customUserAgent, nil)
        XCTAssertEqual(sut.defaultAgent, "")

        XCTAssertNotNil(sut.customLogger)

        XCTAssertEqual(sut.uploadInterval, 0.0)
        XCTAssertEqual(sut.sessionTimeout, 60.0)

        XCTAssertNil(sut.networkOptions)

        XCTAssertNil(sut.consentState)
        XCTAssertNil(sut.dataPlanId)
        XCTAssertNil(sut.dataPlanVersion)
        XCTAssertNil(sut.dataPlanOptions)
        XCTAssertNil(sut.disabledKits)
        XCTAssertNil(sut.attStatus)
        XCTAssertNil(sut.attStatusTimestampMillis)
        XCTAssertNil(sut.configMaxAgeSeconds)
        XCTAssertNil(sut.persistenceMaxAgeSeconds)
        XCTAssertNil(sut.sideloadedKits)
        XCTAssertNotNil(sut.onIdentifyComplete)
        XCTAssertNotNil(sut.onAttributionComplete)
        XCTAssertNotNil(sut.onCreateBatch)
    }

    func testOptionsWithKey() {
        let sut = MParticleOptions(key: "key", secret: "secret")

        XCTAssertEqual(sut.apiKey, "key")
        XCTAssertEqual(sut.apiSecret, "secret")
    }

    func testSetCollectUserAgent() {
        XCTAssertTrue(sut.collectUserAgent)
        XCTAssertFalse(sut.isCollectUserAgentSet)

        sut.setCollectUserAgent(false)

        XCTAssertFalse(sut.collectUserAgent)
        XCTAssertTrue(sut.isCollectUserAgentSet)
    }

    func testSetCollectSearchAdsAttribution() {
        XCTAssertFalse(sut.collectSearchAdsAttribution)
        XCTAssertFalse(sut.isCollectSearchAdsAttributionSet)

        sut.setCollectSearchAdsAttribution(true)

        XCTAssertTrue(sut.collectSearchAdsAttribution)
        XCTAssertTrue(sut.isCollectSearchAdsAttributionSet)
    }

    func testSetTrackNotifications() {
        XCTAssertTrue(sut.trackNotifications)
        XCTAssertFalse(sut.isTrackNotificationsSet)

        sut.setTrackNotifications(false)

        XCTAssertFalse(sut.trackNotifications)
        XCTAssertTrue(sut.isTrackNotificationsSet)
    }

    func testSetAutomaticSessionTracking() {
        XCTAssertTrue(sut.automaticSessionTracking)
        XCTAssertFalse(sut.isAutomaticSessionTrackingSet)

        sut.setAutomaticSessionTracking(false)

        XCTAssertFalse(sut.automaticSessionTracking)
        XCTAssertTrue(sut.isAutomaticSessionTrackingSet)
    }

    func testSetStartKitsAsync() {
        XCTAssertFalse(sut.startKitsAsync)
        XCTAssertFalse(sut.isStartKitsAsyncSet)

        sut.setStartKitsAsync(true)

        XCTAssertTrue(sut.startKitsAsync)
        XCTAssertTrue(sut.isStartKitsAsyncSet)
    }

    func testSetUploadInterval() {
        XCTAssertEqual(sut.uploadInterval, 0.0)
        XCTAssertFalse(sut.isUploadIntervalSet)

        sut.setUploadInterval(1.0)

        XCTAssertEqual(sut.uploadInterval, 1.0)
        XCTAssertTrue(sut.isUploadIntervalSet)
    }

    func testSetSessionTimeout() {
        XCTAssertEqual(sut.sessionTimeout, 60.0)
        XCTAssertFalse(sut.isSessionTimeoutSet)

        sut.setSessionTimeout(1.0)

        XCTAssertEqual(sut.sessionTimeout, 1.0)
        XCTAssertTrue(sut.isSessionTimeoutSet)
    }

    func testSetConfigMaxAgeSeconds() {
        sut.setConfigMaxAgeSeconds(10.0)
        XCTAssertEqual(sut.configMaxAgeSeconds, 10.0)

        sut.setConfigMaxAgeSeconds(-10.0)
        XCTAssertEqual(sut.configMaxAgeSeconds, 10.0)

        sut.setConfigMaxAgeSeconds(nil)
        XCTAssertEqual(sut.configMaxAgeSeconds, nil)

        sut.setConfigMaxAgeSeconds(1.0)
        XCTAssertEqual(sut.configMaxAgeSeconds, 1.0)
    }

    func testSetPersistenceMaxAgeSeconds() {
        sut.setPersistenceMaxAgeSeconds(10.0)
        XCTAssertEqual(sut.persistenceMaxAgeSeconds, 10.0)

        sut.setPersistenceMaxAgeSeconds(-10.0)
        XCTAssertEqual(sut.persistenceMaxAgeSeconds, 10.0)

        sut.setPersistenceMaxAgeSeconds(nil)
        XCTAssertEqual(sut.persistenceMaxAgeSeconds, nil)

        sut.setPersistenceMaxAgeSeconds(1.0)
        XCTAssertEqual(sut.persistenceMaxAgeSeconds, 1.0)
    }
}
