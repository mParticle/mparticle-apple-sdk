import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPSearchAdsAttributionTests: XCTestCase {
    private var host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
    private var owner: MPBackendFakeOwner!
    private var attribution: MPSearchAdsAttribution!

    override func setUp() {
        super.setUp()
        host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
        host.attributionTokenValue = "token"
        owner = MPBackendFakeOwner(host: host)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MPSearchAdsStubProtocol.self]
        owner.attributionSession = URLSession(configuration: configuration)
        attribution = MPSearchAdsAttribution(host: host, owner: owner)
        attribution.retryDelay = 0.01
        MPSearchAdsStubProtocol.reset()
    }

    private func request(_ requestsCompleted: Int = 0) {
        let completed = expectation(description: "attribution completed")
        attribution.requestAttributionDetails(completion: { completed.fulfill() }, requestsCompleted: requestsCompleted)
        wait(for: [completed], timeout: 5)
    }

    func testAnAttributionIsStoredOnTheStateMachine() {
        MPSearchAdsStubProtocol.responses = [.status(200, body: #"{"attribution":true,"campaignId":7}"#)]

        request()

        XCTAssertEqual(MPSearchAdsStubProtocol.requests.count, 1)
        let sent = MPSearchAdsStubProtocol.requests[0]
        XCTAssertEqual(sent.url?.absoluteString, "https://api-adservices.apple.com/api/v1/")
        XCTAssertEqual(sent.httpMethod, "POST")
        XCTAssertEqual(sent.value(forHTTPHeaderField: "Content-Type"), "text/plain")
        XCTAssertEqual(MPSearchAdsStubProtocol.bodies[0], "token")
        let stored = host.machine.searchAdsInfo["Version4.0"] as? [String: Any]
        XCTAssertEqual(stored?["iad-attribution"] as? Bool, true)
        XCTAssertEqual(stored?["iad-campaign-id"] as? String, "7")
    }

    func testWithoutATokenItCompletesWithoutARequest() {
        host.attributionTokenValue = nil

        request()

        XCTAssertTrue(MPSearchAdsStubProtocol.requests.isEmpty)
    }

    func testAnHTTPErrorIsRetriedUntilASuccess() {
        MPSearchAdsStubProtocol.responses = [.status(404, body: ""), .status(200, body: #"{"attribution":true}"#)]

        request()

        XCTAssertEqual(MPSearchAdsStubProtocol.requests.count, 2)
    }

    func testRetriesStopAfterTheLastAttempt() {
        MPSearchAdsStubProtocol.responses = Array(repeating: .status(200, body: "not json"), count: 10)

        request()

        XCTAssertEqual(MPSearchAdsStubProtocol.requests.count, MPSearchAdsAttribution.maxRetries + 1,
                       "the first attempt and four retries")
        XCTAssertTrue(host.machine.searchAdsInfo.isEmpty)
    }

    func testLimitedAdTrackingCompletesWithoutRetrying() {
        MPSearchAdsStubProtocol.responses = [.failure(code: 1), .status(200, body: #"{"attribution":true}"#)]

        request()

        XCTAssertEqual(MPSearchAdsStubProtocol.requests.count, 1)
    }

    func testEachAttemptAsksTheControllerForItsSession() {
        MPSearchAdsStubProtocol.responses = [.failure(code: -1), .status(200, body: #"{"attribution":true}"#)]

        request()

        XCTAssertEqual(owner.calls.filter { $0 == "attributionURLSession" }.count, 2)
    }

    func testAScheduledRetryKeepsTheControllerUntilItRuns() {
        var transient: MPBackendFakeOwner? = MPBackendFakeOwner(host: host)
        transient?.attributionSession = owner.attributionSession
        let retrying = MPSearchAdsAttribution(host: host, owner: transient!)
        retrying.retryDelay = 0.2
        MPSearchAdsStubProtocol.responses = [.status(404, body: ""), .status(200, body: #"{"attribution":true}"#)]
        let completed = expectation(description: "attribution completed")

        retrying.requestAttributionDetails(completion: { completed.fulfill() }, requestsCompleted: 0)
        transient = nil
        wait(for: [completed], timeout: 5)

        XCTAssertEqual(MPSearchAdsStubProtocol.requests.count, 2, "the retry ran after the caller let the controller go")
    }

    func testASingleShotBlockRunsOnceAcrossQueues() {
        var runs = 0
        let lock = NSLock()
        let block = MPSearchAdsAttribution.singleShot {
            lock.lock()
            runs += 1
            lock.unlock()
        }

        DispatchQueue.concurrentPerform(iterations: 20) { _ in block() }

        XCTAssertEqual(runs, 1)
    }
}

/// Answers every request with the next canned response and records what was sent.
private final class MPSearchAdsStubProtocol: URLProtocol {
    enum Response {
        case status(Int, body: String)
        case failure(code: Int)
    }

    private static let lock = NSLock()
    static var responses: [Response] = []
    static var requests: [URLRequest] = []
    static var bodies: [String] = []

    static func reset() {
        lock.lock()
        responses = []
        requests = []
        bodies = []
        lock.unlock()
    }

    override static func canInit(with _: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.requests.append(request)
        Self.bodies.append(Self.body(of: request))
        let response = Self.responses.isEmpty ? .status(200, body: "") : Self.responses.removeFirst()
        Self.lock.unlock()

        switch response {
        case let .status(code, body):
            let http = HTTPURLResponse(url: request.url ?? URL(fileURLWithPath: "/"), statusCode: code,
                                       httpVersion: nil, headerFields: nil)
            if let http { client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed) }
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(code):
            client?.urlProtocol(self, didFailWithError: NSError(domain: "ADClientErrorDomain", code: code))
        }
    }

    override func stopLoading() {}

    /// URLSession moves a request body into a stream before a protocol sees it.
    private static func body(of request: URLRequest) -> String {
        if let body = request.httpBody { return String(bytes: body, encoding: .utf8) ?? "" }
        guard let stream = request.httpBodyStream else { return "" }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return String(bytes: data, encoding: .utf8) ?? ""
    }
}
