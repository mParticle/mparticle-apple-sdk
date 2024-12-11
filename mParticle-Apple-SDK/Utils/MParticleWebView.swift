//
//  MParticleWebView.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 12/10/24.
//

// NOTE: @objc specifier added to private properties to support existing Obj-C unit tests

@objc public class MParticleWebView_PRIVATE : NSObject {
    
    @objc public var userAgent: String? { resolvedUserAgent ?? defaultUserAgent }
    @objc public var originalDefaultUserAgent: String? { "mParticle Apple SDK/\(kMParticleSDKVersion)" }
    
    private var messageQueue: DispatchQueue

    private var customUserAgent: String? = nil
    private var shouldCollect = false
    private var defaultUserAgent: String? = nil
    
    @objc private var initializedDate: Date? = nil
    @objc private var resolvedUserAgent: String? = nil // final result
    @objc private var isCollecting: Bool = false
    @objc private var retryCount: Int = 0
    
#if os(iOS)
    @objc private var webView: WKWebView? = nil
#endif
    
    @objc public init(messageQueue: DispatchQueue) {
        self.messageQueue = messageQueue
        super.init()
    }
    
    @objc public func start(customUserAgent: String?, shouldCollect: Bool, defaultUserAgentOverride: String?) {
        self.initializedDate = Date()
        self.customUserAgent = customUserAgent
#if os(iOS)
        self.shouldCollect = shouldCollect
#endif
        self.defaultUserAgent = defaultUserAgentOverride ?? originalDefaultUserAgent
        self.retryCount = 0
        startCollectionIfNecessary()
    }
    
    private func startCollectionIfNecessary() {
        if let customUserAgent = customUserAgent {
            resolvedUserAgent = customUserAgent;
        } else if !shouldCollect {
            resolvedUserAgent = defaultUserAgent;
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
                MPLog.verbose("Getting user agent")
                self.webView?.evaluateJavaScript("navigator.userAgent") { result, error in
                    if result == nil, let error = error as? NSError {
                        MPLog.verbose("Error collecting user agent: %@", error)
                    }
                    if let result = result as? String {
                        MPLog.verbose("Finished getting user agent")
                        self.resolvedUserAgent = result
                    } else {
                        if self.retryCount < 10 {
                            self.retryCount += 1
                            MPLog.verbose("User agent collection failed (count=%@), retrying", self.retryCount)
                            self.webView = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.evaluateAgent()
                            }
                            return
                        } else {
                            MPLog.verbose("Falling back on default user agent")
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
                MPLog.debug("Max wait time exceeded for user agent")
            }
            return false
        }
        if !printedMessageDelay {
            printedMessageDelay = true
            MPLog.verbose("Delaying initial upload for user agent")
        }
        return true
    }
}
