//
//  MPListenerProtocol.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 1/22/25.
//

import Foundation

@objc public enum MPEndpoint: Int {
    case identityLogin = 0, identityLogout, identityIdentify, identityModify, events, config, alias
}
@objc public enum MPDatabaseTable: Int {
    case attributes = 0, breadcrumbs, messages, reporting, sessions, uploads, unknown
}

@objc public protocol MPListenerProtocol {

    /**
     * Indicates that an API method was called. This includes invocations both from external sources (your code)
     * and those which originated from within the SDK
     * @param apiName the name of the API method
     * @param stackTrace is the current stackTrace as an array of NSStrings
     * @param isExternal true, if the call originated from outside of the SDK
     * @param objects is the arguments sent to this api, such as the MPEvent in logEvent
     */
    @objc optional func onAPICalled(_ apiName: Any!, stackTrace: Any!, isExternal: Any!, objects: Any!)

    /**
     * Indicates that a new Database entry has been created
     * @param tableName the name of the table
     * @param primaryKey a unique identifier for the database row
     * @param message the database entry in NSString form
     */
    @objc optional func onEntityStored(_ tableName: Any!, primaryKey: Any!, message: Any!)

    /**
     * Indicates that a Network Request has been started.
     * @param type the type of network request, see Endpoint
     * @param url the URL of the request
     * @param body the response body in JSON form
     */
    @objc optional func onNetworkRequestStarted(_ type: Any!, url: Any!, body: Any!)

    /**
     * Indicates that a Network Request has completed.
     * @param type the type of network request, see Endpoint
     * @param url the URL of the request
     * @param body the response body in JSON form
     * @param responseCode the HTTP response code
     */
    @objc optional func onNetworkRequestFinished(_ type: Any!, url: Any!, body: Any!, responseCode: Any!)

    /**
     * Indicates that a Kit's API method has been invoked and that the name of the Kit's method is different
     * than the method containing this method's invocation
     * @param methodName the name of the Kit's method being called
     * @param kitId the Id of the kit
     * @param used whether the Kit's method returned ReportingMessages, or null if return type is void
     * @param objects the arguments supplied to the Kit
     */
    @objc optional func onKitApiCalled(_ methodName: Any!, kitId: Int32, used: Any!, objects: Any!)

    /**
     * Indicates that a Kit module, with kitId, has been included in the source files
     * @param kitId the id of the kit, corresponds with a {@see MPKitInstance}
     */
    @objc optional func onKitDetected(_ kitId: Int32)

    /**
     * Indicates that a Configuration for a kit with kitId is being applied
     * @param kitId the id of the kit, corresponds with a {@see MPKitInstance}
     * @param configuration the kit
     */
    @objc optional func onKitConfigReceived(_ kitId: Int32, configuration: Any!)

    /**
     * Indicates that a kit with kitId was successfully started
     * @param kitId the id of the kit, corresponds with a {@see MPKitInstance}
     */
    @objc optional func onKitStarted(_ kitId: Int32)

    /**
     * Indicates that either an attempt to start a kit was unsuccessful, or a started kit was stopped.
     * Possibilities for why this may happen include: {@see MParticleUser}'s loggedIn status or
     * {@see MPConsentState} required it to be stopped, the Kit crashed, or a
     * configuration was received that excluded the kit
     * @param kitId the id of the kit, corresponds with a {@see MPKitInstance}
     * @param reason a message containing the reason a kit was stopped
     */
    @objc optional func onKitExcluded(_ kitId: Int32, reason: Any!)

    /**
     * Indicates that state of a Session may have changed
     * @param session the current {@see MParticleSession} instance
     */
    @objc optional func onSessionUpdated(_ session: Any!)

    /**
     * Indicates that an alias request has completed
     * @param aliasResponse the alias response object
     */
    @objc optional func onAliasRequestFinished(_ aliasResponse: MPAliasResponse?)
}
