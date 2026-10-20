import Foundation

/// Asks Apple's attribution endpoint which search ad, if any, led to this install, retrying while a
/// new token is not yet resolvable, and stores the answer on the state machine.
@objc(MPSearchAdsAttribution)
public final class MPSearchAdsAttribution: NSObject {
    static let maxRetries = 4
    private static let endpoint = "https://api-adservices.apple.com/api/v1/"
    /// Seconds before a retry; shortened by tests.
    var retryDelay: TimeInterval = 3

    private let host: MPBackendHost
    private weak var owner: MPBackendAssemblyOwner?

    init(host: MPBackendHost, owner: MPBackendAssemblyOwner) {
        self.host = host
        self.owner = owner
        super.init()
    }

    /// Requests attribution, then runs `completionHandler` on the message queue once the result is
    /// stored or the request is given up on: no token, ad tracking limited, or a failure after the
    /// last retry. `requestsCompleted` counts the attempts already made.
    ///
    /// The URL session comes from the controller on every attempt, and the controller is held until
    /// a scheduled retry runs.
    @objc(requestAttributionDetailsWithCompletion:requestsCompleted:)
    public func requestAttributionDetails(completion completionHandler: @escaping () -> Void, requestsCompleted: Int) {
        let host = self.host
        let completion = { host.executeOnMessage(completionHandler) }

        guard let token = host.attributionToken(),
              let url = URL(string: Self.endpoint),
              let session = owner?.attributionURLSession()
        else {
            completion()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(token.utf8)

        let owner = self.owner
        let retryOrComplete = { [self] in
            guard requestsCompleted + 1 <= Self.maxRetries else {
                completion()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                withExtendedLifetime(owner) {
                    self.requestAttributionDetails(completion: completionHandler, requestsCompleted: requestsCompleted + 1)
                }
            }
        }

        host.messageQueue().async {
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    host.sdkLogger()?.error("Failed requesting Ads Attribution with error: \(error.localizedDescription).")
                    // ADClientErrorLimitAdTracking: the user limits ad tracking, so retrying cannot help.
                    if (error as NSError).code == 1 {
                        completion()
                    } else {
                        retryOrComplete()
                    }
                    return
                }

                // A non-2xx response carries no error. The endpoint answers 404 for a short while after
                // a token is created, which is what the retries are for.
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                guard (200...299).contains(statusCode) else {
                    host.sdkLogger()?.error("Failed requesting Ads Attribution with HTTP status \(statusCode).")
                    retryOrComplete()
                    return
                }

                guard let data,
                      let attribution = (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary
                else {
                    host.sdkLogger()?.error("Ads Attribution response body was not a JSON object.")
                    retryOrComplete()
                    return
                }

                let mapped = MPStateMachinePRIVATE.searchAdsInfo(fromAdAttribution: attribution)
                host.stateMachine().searchAdsInfo = mapped as? [AnyHashable: Any] ?? [:]
                completion()
            }
            // A data task starts suspended.
            task.resume()
        }
    }

    /// Wraps `block` so it runs at most once, however many callers hold it and from whatever queue.
    @objc(singleShotBlock:)
    public static func singleShot(_ block: @escaping () -> Void) -> () -> Void {
        let lock = NSLock()
        var hasRun = false
        return {
            lock.lock()
            let alreadyRan = hasRun
            hasRun = true
            lock.unlock()
            if !alreadyRan {
                block()
            }
        }
    }
}
