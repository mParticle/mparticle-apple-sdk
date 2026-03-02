@testable import mParticle_Adobe

class SessionProtocolMock: SessionProtocol {
    var dataTaskCalled = false
    var dataTaskRequestParam: URLRequest?
    var dataTaskCompletionHandlerParam: ((Data?, URLResponse?, (any Error)?) -> Void)?

    func dataTask(with request: URLRequest,
                  completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
        dataTaskCalled = true
        dataTaskRequestParam = request
        dataTaskCompletionHandlerParam = completionHandler

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        return session.dataTask(with: URLRequest(url: URL(string: "https://localhost")!))
    }
}
