import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPNetworkPerformanceTests: XCTestCase {
    private func request(
        _ urlString: String = "https://example.com/path/to/resource?secret=value",
        method: String? = nil,
        body: Data? = nil
    ) throws -> URLRequest {
        var request = URLRequest(url: try XCTUnwrap(URL(string: urlString)))
        request.httpMethod = method
        request.httpBody = body
        return request
    }

    func testObjectiveCRuntimeIdentityIsPreserved() throws {
        let performance = MPNetworkPerformance(
            urlRequest: try request(),
            networkMeasurementMode: .exclude
        )

        XCTAssertEqual(NSStringFromClass(MPNetworkPerformance.self), "MPNetworkPerformance")
        XCTAssertTrue(performance.responds(to: NSSelectorFromString("initWithURLRequest:networkMeasurementMode:")))
        XCTAssertTrue(performance.responds(to: NSSelectorFromString("POSTBody")))
        XCTAssertTrue(performance.responds(to: NSSelectorFromString("dictionaryRepresentation")))
    }

    func testExcludeModeOmitsURL() throws {
        let performance = MPNetworkPerformance(
            urlRequest: try request(),
            networkMeasurementMode: .exclude
        )

        XCTAssertNil(performance.urlString)
        XCTAssertNil(performance.dictionaryRepresentation()["url"])
    }

    func testPreserveQueryModeKeepsCompleteURL() throws {
        let performance = MPNetworkPerformance(
            urlRequest: try request(),
            networkMeasurementMode: .preserveQuery
        )

        XCTAssertEqual(performance.urlString, "https://example.com/path/to/resource?secret=value")
    }

    func testAbridgedModeRemovesQuery() throws {
        let performance = MPNetworkPerformance(
            urlRequest: try request(),
            networkMeasurementMode: .abridged
        )

        XCTAssertEqual(performance.urlString, "https://example.com/path/to/resource")
    }

    func testDefaultMethodAndResponseCodeAreSerialized() throws {
        let performance = MPNetworkPerformance(
            urlRequest: try request(),
            networkMeasurementMode: .exclude
        )
        let dictionary = performance.dictionaryRepresentation()

        XCTAssertEqual(performance.httpMethod, "GET")
        XCTAssertEqual(dictionary["v"] as? String, "GET")
        XCTAssertEqual(dictionary["rc"] as? Int, 200)
    }

    func testMeasurementsAndExplicitResponseCodeUseWireKeys() throws {
        let performance = MPNetworkPerformance(
            urlRequest: try request(method: "PUT"),
            networkMeasurementMode: .preserveQuery
        )
        performance.elapsedTime = 42
        performance.bytesIn = 123
        performance.bytesOut = 456
        performance.responseCode = 204

        let dictionary = performance.dictionaryRepresentation()
        XCTAssertEqual(dictionary["url"] as? String, performance.urlString)
        XCTAssertEqual(dictionary["te"] as? Double, 42)
        XCTAssertEqual(dictionary["bi"] as? UInt, 123)
        XCTAssertEqual(dictionary["bo"] as? UInt, 456)
        XCTAssertEqual(dictionary["rc"] as? Int, 204)
        XCTAssertEqual(dictionary["v"] as? String, "PUT")
    }

    func testStartAndEndTimesUpdateTruncatedElapsedTime() throws {
        let performance = MPNetworkPerformance(
            urlRequest: try request(),
            networkMeasurementMode: .exclude
        )

        performance.startTime = 1_000.25
        performance.endTime = 1_043.99
        XCTAssertEqual(performance.elapsedTime, 43)

        performance.startTime = 1_010.75
        XCTAssertEqual(performance.elapsedTime, 33)
    }

    func testElapsedTimeUpdatesEndTimeWhenStarted() throws {
        let performance = MPNetworkPerformance(
            urlRequest: try request(),
            networkMeasurementMode: .exclude
        )

        performance.startTime = 1_000
        performance.elapsedTime = 25.5

        XCTAssertEqual(performance.endTime, 1_025.5)
    }

    func testDateSettersConvertSecondsToMilliseconds() throws {
        let performance = MPNetworkPerformance(
            urlRequest: try request(),
            networkMeasurementMode: .exclude
        )

        performance.setStartDate(Date(timeIntervalSince1970: 10))
        performance.setEndDate(Date(timeIntervalSince1970: 12.345))

        XCTAssertEqual(performance.startTime, 10_000)
        XCTAssertEqual(performance.endTime, 12_345, accuracy: 0.000_1)
        XCTAssertEqual(performance.elapsedTime, 2_345)
    }

    func testGoogleAnalyticsPostBodyIsSerializedForSecureAndPlainURLs() throws {
        let data = Data("event=data".utf8)

        for url in [
            "https://ssl.google-analytics.com/collect",
            "http://www.google-analytics.com/collect"
        ] {
            let performance = MPNetworkPerformance(
                urlRequest: try request(url, method: "POST", body: data),
                networkMeasurementMode: .exclude
            )

            XCTAssertEqual(performance.postBody, "event=data")
            XCTAssertEqual(performance.dictionaryRepresentation()["d"] as? String, "event=data")
        }
    }

    func testPostBodyIsExcludedUnlessEveryRestrictionMatches() throws {
        let body = Data("event=data".utf8)
        let requests = [
            try request("https://example.com/collect", method: "POST", body: body),
            try request("https://ssl.google-analytics.com/collect", method: "GET", body: body),
            try request("https://ssl.google-analytics.com/collect", method: "POST")
        ]

        for request in requests {
            let performance = MPNetworkPerformance(
                urlRequest: request,
                networkMeasurementMode: .exclude
            )
            XCTAssertNil(performance.postBody)
            XCTAssertNil(performance.dictionaryRepresentation()["d"])
        }
    }

    func testCopyRetainsValuesAndCanBeChangedIndependently() throws {
        let original = MPNetworkPerformance(
            urlRequest: try request(method: "PATCH"),
            networkMeasurementMode: .preserveQuery
        )
        original.startTime = 1_000
        original.endTime = 1_100
        original.bytesIn = 10
        original.bytesOut = 20
        original.responseCode = 201

        let copy = try XCTUnwrap(original.copy() as? MPNetworkPerformance)
        XCTAssertFalse(copy === original)
        XCTAssertEqual(copy.dictionaryRepresentation(), original.dictionaryRepresentation())
        XCTAssertEqual(copy.networkMeasurementMode, .preserveQuery)

        copy.urlString = "https://copy.example"
        copy.bytesIn = 999

        XCTAssertNotEqual(copy.urlString, original.urlString)
        XCTAssertNotEqual(copy.bytesIn, original.bytesIn)
    }
}
