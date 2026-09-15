import Foundation

/// Builds a persisted upload from messages and live dependencies supplied by the SDK boundary.
@objc(MPUploadBuilder)
public final class MPUploadBuilderPRIVATE: NSObject {
    @objc public let sessionId: NSNumber?
    @objc public let preparedMessageIds: NSMutableArray

    private var uploadDictionary: NSMutableDictionary
    private let containsOptOutMessage: Bool
    private let dataPlanId: String?
    private let dataPlanVersion: NSNumber?
    private let uploadSettings: NSObject
    private let context: MPUploadBuilderContext

    @objc(initWithMpid:sessionId:messages:sessionTimeout:uploadInterval:dataPlanId:dataPlanVersion:uploadSettings:context:)
    public init?(
        mpid: NSNumber,
        sessionId: NSNumber?,
        messages: [Any]?,
        sessionTimeout: TimeInterval,
        uploadInterval: TimeInterval,
        dataPlanId: String?,
        dataPlanVersion: NSNumber?,
        uploadSettings: NSObject,
        context: MPUploadBuilderContext
    ) {
        guard let messages, !messages.isEmpty else { return nil }
        self.sessionId = sessionId
        self.uploadSettings = uploadSettings
        self.context = context
        self.dataPlanId = dataPlanId
        self.dataPlanVersion = dataPlanId == nil ? nil : dataPlanVersion

        let prepared = MPUploadBuilderFields.preparedMessages(from: messages)
        preparedMessageIds = NSMutableArray(array: prepared.preparedMessageIds)
        containsOptOutMessage = prepared.containsOptOutMessage
        let lifetimeValue = context.lifetimeValue(mpid)
        let stateMachine = context.stateMachine()
        uploadDictionary = NSMutableDictionary(dictionary: MPUploadBuilderFields.seedDictionary(
            optOut: stateMachine.optOut, uploadInterval: uploadInterval, lifetimeValue: lifetimeValue
        ))
        if let plan = MPUploadBuilderFields.dataPlanDictionary(dataPlanId: dataPlanId, dataPlanVersion: dataPlanVersion) {
            uploadDictionary[MessageKeys.kMPContextKey] = plan
        }
        if !prepared.messageDictionaries.isEmpty {
            uploadDictionary["msgs"] = prepared.messageDictionaries
        }
        if sessionTimeout > 0 {
            uploadDictionary["stl"] = sessionTimeout
        }
        if let modules = MPUploadBuilderFields.customModulesDictionary(from: stateMachine.customModules) {
            uploadDictionary["cms"] = modules
        }
        uploadDictionary["mpid"] = mpid
        super.init()
    }

    @objc(build:)
    public func build(_ completion: (MPUploadPRIVATE?) -> Void) {
        let stateMachine = context.stateMachine()
        uploadDictionary.addEntries(from: MPUploadBuilderFields.headerFields(
            messageId: context.messageID(), timestampMs: context.timestamp(),
            sdkVersion: context.sdkVersion, apiKey: stateMachine.apiKey
        ))

        let storedInfo = sessionId.map { context.persistence().objectiveCAppAndDeviceInfo(forSessionId: $0) }
        uploadDictionary["ai"] = storedInfo?["ai"] ?? context.applicationInfo(stateMachine)
        let mpid = uploadDictionary["mpid"] as? NSNumber ?? 0
        uploadDictionary["di"] = storedInfo?["di"] ?? context.deviceInfo(mpid)

        let status = context.stateMachine().attAuthorizationStatus
        let advertiserId = context.advertiserID(mpid)
        if let deviceInfo = MPUploadBuilderFields.deviceInfoDictionary(
            byAddingAdvertiserId: advertiserId,
            isATTAuthorized: status?.intValue == MPATTAuthorizationStatusSwift.authorized.rawValue,
            to: uploadDictionary["di"] as? [String: Any]
        ) {
            uploadDictionary["di"] = deviceInfo
        }

        let consumerInfo = stateMachine.consumerInfo
        if let cookies = consumerInfo.cookiesDictionaryRepresentation() {
            uploadDictionary["ck"] = cookies
        }
        if let stamp = consumerInfo.deviceApplicationStamp {
            uploadDictionary["das"] = stamp
        }

        let persistence = context.persistence()
        if let records = persistence.objectiveCFetchForwardRecords() {
            let records = records.compactMap { $0 as? MPForwardRecordPRIVATE }
            let batch = MPUploadBuilderFields.forwardRecordBatch(
                dataDictionaries: records.map { $0.dataDictionary as Any? ?? NSNull() },
                recordIds: records.map { NSNumber(value: $0.forwardRecordId) }
            )
            if !batch.dataDictionaries.isEmpty {
                uploadDictionary[MessageKeys.kMPForwardStatsRecord] = batch.dataDictionaries
                persistence.objectiveCDeleteForwardRecords(ids: batch.recordIds)
            }
        }
        if let attributes = persistence.objectiveCFetchIntegrationAttributes() {
            let dictionaries = attributes.compactMap { ($0 as? MPIntegrationAttributesPRIVATE)?.dictionaryRepresentation() }
            uploadDictionary["ia"] = MPUploadBuilderFields.mergedIntegrationAttributesDictionary(from: dictionaries)
        }
        if let consent = context.consent(mpid) {
            uploadDictionary["con"] = consent
        }

        // Pass the actual mutable dictionary: an in-place customer mutation was historically
        // visible without adding the marker used for a different replacement dictionary.
        guard let transformed = context.transformBatch(uploadDictionary) else {
            context.logger()?.warning("Not uploading batch due to 'onCreateBatch' handler returning 'nil'")
            return
        }
        if let replacement = transformed as? NSDictionary, !replacement.isEqual(uploadDictionary) {
            context.logger()?.warning("Replacing batch with mutated version from 'onCreateBatch' handler")
            uploadDictionary = NSMutableDictionary(dictionary: replacement)
            uploadDictionary["mb"] = true
        }

        let upload = MPUploadPRIVATE(
            sessionId: sessionId, uploadDictionary: uploadDictionary, dataPlanId: dataPlanId,
            dataPlanVersion: dataPlanVersion, uploadSettings: uploadSettings
        )
        upload?.containsOptOutMessage = containsOptOutMessage
        completion(upload)
    }

    @objc(withUserAttributes:deletedUserAttributes:)
    public func withUserAttributes(_ attributes: [String: Any], deletedUserAttributes: NSSet?) -> MPUploadBuilderPRIVATE {
        if !attributes.isEmpty {
            let stringified = MPUploadBuilderFields.stringifiedUserAttributes(attributes)
            if !stringified.isEmpty { uploadDictionary["ua"] = stringified }
        }
        if let deletedUserAttributes, !deletedUserAttributes.allObjects.isEmpty, sessionId != nil {
            uploadDictionary["uad"] = deletedUserAttributes.allObjects
        }
        return self
    }

    @objc(withUserIdentities:)
    public func withUserIdentities(_ identities: [NSDictionary]) -> MPUploadBuilderPRIVATE {
        if !identities.isEmpty { uploadDictionary["ui"] = identities }
        return self
    }

    override public var description: String {
        let session = sessionId.map { " Session Id: \($0.int64Value)\n" } ?? ""
        return "MPUploadBuilder\n\(session) UploadDictionary: \(uploadDictionary)"
    }
}
