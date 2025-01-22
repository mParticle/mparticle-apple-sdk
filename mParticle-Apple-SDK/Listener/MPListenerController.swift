//
//  MPListenerController.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 12/16/24.
//

import Foundation

@objc public class MPListenerController : NSObject {
    private static let shared = MPListenerController()
    private var sdkListeners: [MPListenerProtocol] = []

    /**
     * Returns the shared instance object.
     * @returns the Singleton instance of the MPListener class.
     */
    @objc public class func sharedInstance() -> MPListenerController {
        return shared
    }

    /**
     * Adds a listener to the SDK to receive any MPListenerProtocol calls from the API to that object
     * @param sdkListener An instance of a class that implements the MPListenerProtocol
     */
    @objc public func addSdkListener(_ sdkListener: any MPListenerProtocol) {
        sdkListeners.append(sdkListener)
    }

    /**
     * Removes a listener from the SDK to no longer receive any MPListenerProtocol calls from the API to that object
     * If you don't remove the Listener we will retain a zombie reference of your object and it will never be released
     * @param sdkListener An instance of a class that implements the MPListenerProtocol
     */
    @objc public func removeSdkListener(_ sdkListener: any MPListenerProtocol) {
        sdkListeners = sdkListeners.filter { sdkListener !== $0 }
    }

    /**
     * Indicates that an API method was called. This includes invocations both from external sources (your code)
     * and those which originated from within the SDK
     * @param apiName the name of the API method
     * @param parameter1 to parameter4 are the arguments sent to this api, such as the MPEvent in logEvent
     */
    @objc public func onAPICalled(_ apiName: Selector, parameter1: NSObject?, parameter2: NSObject?, parameter3: NSObject?, parameter4: NSObject?) {
        
    }

    @objc public func onAPICalled(_ apiName: Selector, parameter1: NSObject?, parameter2: NSObject?, parameter3: NSObject?) {
        for delegate in sdkListeners {
            let stackTrace = Thread.callStackSymbols
            var parameters: [NSObject] = []
            if let parameter1 = parameter1 {
                parameters.append(parameter1)
            } else {
                parameters.append(NSNull())
            }
            if let parameter2 = parameter3 {
                parameters.append(parameter2)
            } else {
                parameters.append(NSNull())
            }
            if let parameter3 = parameter3 {
                parameters.append(parameter3)
            } else {
                parameters.append(NSNull())
            }
            DispatchQueue.main.async {
                delegate.onAPICalled?(NSStringFromSelector(apiName), stackTrace: stackTrace, isExternal: true, objects: parameters)
            }
        }
    }

    @objc public func onAPICalled(_ apiName: Selector, parameter1: NSObject?, parameter2: NSObject?) {
        for delegate in sdkListeners {
            let stackTrace = Thread.callStackSymbols
            var parameters: [NSObject] = []
            if parameter1 != nil {
                parameters.append(parameter1!)
            } else {
                parameters.append(NSNull())
            }
            if parameter2 != nil {
                parameters.append(parameter2!)
            } else {
                parameters.append(NSNull())
            }
            DispatchQueue.main.async {
                delegate.onAPICalled?(NSStringFromSelector(apiName), stackTrace: stackTrace, isExternal: true, objects: parameters)
            }
        }
    }

    @objc public func onAPICalled(_ apiName: Selector, parameter1: NSObject?) {
        for delegate in sdkListeners {
            let stackTrace = Thread.callStackSymbols
            var parameters: [NSObject] = []
            if parameter1 != nil {
                parameters.append(parameter1!)
            } else {
                parameters.append(NSNull())
            }
            DispatchQueue.main.async {
                delegate.onAPICalled?(NSStringFromSelector(apiName), stackTrace: stackTrace, isExternal: true, objects: parameters)
            }
        }
    }

    @objc public func onAPICalled(_ apiName: Selector) {
        for delegate in sdkListeners {
            let stackTrace = Thread.callStackSymbols
            let parameters: [NSObject] = []
            DispatchQueue.main.async {
                delegate.onAPICalled?(NSStringFromSelector(apiName), stackTrace: stackTrace, isExternal: true, objects: parameters)
            }
        }
    }

    /**
     * Indicates that a new Database entry has been created
     * @param tableName the name of the table
     * @param primaryKey a unique identifier for the database row
     * @param message the database entry in JSON form
     */
    @objc public func onEntityStored(_ tableName: MPDatabaseTable, primaryKey: NSNumber, message: String) {
        for delegate in sdkListeners {
            DispatchQueue.main.async {
                delegate.onEntityStored?(tableName, primaryKey: primaryKey, message: message)
            }
        }
    }

    /**
     * Indicates that a Network Request has been started. Network Requests for a given Endpoint are performed
     * synchronously, so the next invocation of onNetworkRequestFinished of the same Endpoint will be linked
     * @param type the type of network request, see Endpoint
     * @param url the URL of the request
     * @param body the response body in JSON form
     */
    @objc public func onNetworkRequestStarted(_ type: MPEndpoint, url: String, body: NSObject) {
        for delegate in sdkListeners {
            DispatchQueue.main.async {
                delegate.onNetworkRequestStarted?(type, url: url, body: body)
            }
        }
    }

    /**
     * Indicates that a Network Request has completed.
     * @param type the type of network request, see Endpoint
     * @param url the URL of the request
     * @param body the response body in JSON form
     * @param responseCode the HTTP response code
     */
    @objc public func onNetworkRequestFinished(_ type: MPEndpoint, url: String, body: NSObject, responseCode: Int) {
        for delegate in sdkListeners {
            DispatchQueue.main.async {
                delegate.onNetworkRequestFinished?(type, url: url, body: body, responseCode: responseCode)
            }
        }
    }

    /**
     * Indicates that a Kit's API method has been invoked and that the name of the Kit's method is different
     * than the method containing this method's invocation
     * @param methodName the name of the Kit's method being called
     * @param kitId the Id of the kit
     * @param used whether the Kit's method returned ReportingMessages, or null if return type is void
     * @param objects the arguments supplied to the Kit
     */
    @objc public func onKitApiCalled(_ methodName: String, kitId: Int32, used: Bool, objects: [Any]) {
        for delegate in sdkListeners {
            DispatchQueue.main.async {
                delegate.onKitApiCalled?(methodName, kitId: kitId, used: used, objects: objects)
            }
        }
    }

    /**
     * Indicates that a Kit module, with kitId, has been included in the source files
     * @param kitId the id of the kit, corresponds with a {@see com.mparticle.MParticle.ServiceProviders}
     */
    @objc public func onKitDetected(_ kitId: Int32) {
        for delegate in sdkListeners {
            DispatchQueue.main.async {
                delegate.onKitDetected?(kitId)
            }
        }
    }

    /**
     * Indicates that a Configuration for a kit with kitId is being applied
     * @param kitId the id of the kit, corresponds with a {@see com.mparticle.MParticle.ServiceProviders}
     * @param configuration the kit
     */
    @objc public func onKitConfigReceived(_ kitId: Int32, configuration: [AnyHashable : Any]) {
        for delegate in sdkListeners {
            DispatchQueue.main.async {
                delegate.onKitConfigReceived?(kitId, configuration: configuration)
            }
        }
    }

    /**
     * Indicates that a kit with kitId was successfully started
     * @param kitId the id of the kit, corresponds with a {@see com.mparticle.MParticle.ServiceProviders}
     */
    @objc public func onKitStarted(_ kitId: Int32) {
        for delegate in sdkListeners {
            DispatchQueue.main.async {
                delegate.onKitStarted?(kitId)
            }
        }
    }

    /**
     * Indicates that either an attempt to start a kit was unsuccessful, or a started kit was stopped.
     * Possibilities for why this may happen include: {@see MParticleUser}'s loggedIn status or
     * {@see com.mparticle.consent.ConsentState} required it to be stopped, the Kit crashed, or a
     * configuration was received that excluded the kit
     * @param kitId the id of the kit, corresponds with a {@see com.mparticle.MParticle.ServiceProviders}
     * @param reason a message containing the reason a kit was stopped
     */
    @objc public func onKitExcluded(_ kitId: Int32, reason: String) {
        for delegate in sdkListeners {
            DispatchQueue.main.async {
                delegate.onKitExcluded?(kitId, reason: reason)
            }
        }
    }

    /**
     * Indicates that state of a Session may have changed
     * @param session the current {@see InternalSession} instance
     */
    @objc public func onSessionUpdated(_ session: MParticleSession?) {
        for delegate in sdkListeners {
            DispatchQueue.main.async {
                delegate.onSessionUpdated?(session)
            }
        }
    }

    /**
     * Indicates that an alias request has completed.
     * @param aliasResponse the alias response object
     */
    @objc public func onAliasRequestFinished(_ aliasResponse: MPAliasResponse?) {
        for delegate in sdkListeners {
            DispatchQueue.main.async {
                delegate.onAliasRequestFinished?(aliasResponse)
            }
        }
    }
}

