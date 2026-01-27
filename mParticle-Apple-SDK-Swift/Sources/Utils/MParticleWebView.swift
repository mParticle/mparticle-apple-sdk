import Foundation
import WebKit

@objc internal class MParticleWebView_PRIVATE: NSObject {
    @objc public var userAgent: String? { resolvedUserAgent ?? defaultUserAgent }
    @objc public var originalDefaultUserAgent: String? { "mParticle Apple SDK/\(skdVersion)" }

    private var messageQueue: DispatchQueue

    private var customUserAgent: String? = nil
    private var shouldCollect = false
    private var defaultUserAgent: String? = nil
    private var skdVersion: String

    @objc private var initializedDate: Date? = nil
    @objc private var resolvedUserAgent: String? = nil // final result
    @objc private var isCollecting: Bool = false
    @objc private var retryCount: Int = 0

    #if os(iOS)
        @objc private var webView: WKWebView?
    #endif
    
    private var logger: MPLog

    @objc public init(messageQueue: DispatchQueue, logger: MPLog, skdVersion: String) {
        self.messageQueue = messageQueue
        self.logger = logger
        self.skdVersion = skdVersion
        super.init()
    }

    @objc public func start(customUserAgent: String?, shouldCollect: Bool, defaultUserAgentOverride: String?) {
        initializedDate = Date()
        self.customUserAgent = customUserAgent
        #if os(iOS)
            self.shouldCollect = shouldCollect
        #endif
        defaultUserAgent = defaultUserAgentOverride ?? originalDefaultUserAgent
        retryCount = 0
        startCollectionIfNecessary()
    }

    private func startCollectionIfNecessary() {
        if let customUserAgent = customUserAgent {
            resolvedUserAgent = customUserAgent
        } else if !shouldCollect {
            resolvedUserAgent = defaultUserAgent
        }

        if let _ = resolvedUserAgent {
            return
        }

        #if os(iOS)
            evaluateAgent()
        #endif
    }

    #if os(iOS)
        private func evaluateAgent() {
            messageQueue.async {
                self.isCollecting = true
                DispatchQueue.main.async {
                    if self.webView == nil {
                        self.webView = WKWebView(frame: .zero)
                    }

                    self.logger.verbose("Getting user agent")
                    self.webView?.evaluateJavaScript("navigator.userAgent") { result, error in
                        if result == nil, let error = error as? NSError {
                            self.logger.verbose("Error collecting user agent: \(error)")
                        }
                        if let result = result as? String {
                            self.logger.verbose("Finished getting user agent")
                            self.resolvedUserAgent = result
                        } else {
                            if self.retryCount < 10 {
                                self.retryCount += 1
                                self.logger.verbose("User agent collection failed (count=\(self.retryCount)), retrying")
                                self.webView = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.evaluateAgent()
                                }
                                return
                            } else {
                                self.logger.verbose("Falling back on default user agent")
                                self.resolvedUserAgent = self.defaultUserAgent
                            }
                        }
                        self.webView = nil
                        self.messageQueue.async {
                            self.isCollecting = false
                        }
                    }
                }
            }
        }
    #endif

    private var printedMessage = false
    private var printedMessageDelay = false
    @objc public func shouldDelayUpload(_ maxWaitTime: TimeInterval) -> Bool {
        guard let initializedDate = initializedDate, resolvedUserAgent == nil, isCollecting else {
            return false
        }

        if -initializedDate.timeIntervalSinceNow > maxWaitTime {
            if !printedMessage {
                printedMessage = true
                logger.debug("Max wait time exceeded for user agent")
            }
            return false
        }
        if !printedMessageDelay {
            printedMessageDelay = true
            logger.verbose("Delaying initial upload for user agent")
        }
        return true
    }
}
