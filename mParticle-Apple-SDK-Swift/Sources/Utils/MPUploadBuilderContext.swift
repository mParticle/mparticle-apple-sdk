import Foundation

/// Persistence values used to enrich a batch, without constructing Objective-C model wrappers.
@objc public protocol MPUploadEnrichmentPersistence {
    @objc(appAndDeviceInfoForSessionId:)
    func objectiveCAppAndDeviceInfo(forSessionId sessionId: NSNumber) -> NSDictionary
    @objc(fetchForwardRecords) func objectiveCFetchForwardRecords() -> NSArray?
    @objc(deleteForwardRecordsIds:) func objectiveCDeleteForwardRecords(ids: [NSNumber])
    @objc(fetchIntegrationAttributes) func objectiveCFetchIntegrationAttributes() -> NSArray?
}

extension MPPersistenceStorePRIVATE: MPUploadEnrichmentPersistence {}

/// Live dependencies supplied by the Objective-C composition boundary. Providers are evaluated
/// where the builder previously read the singleton, so startup/reset cannot leave stale objects.
@objc(MPUploadBuilderContext)
public final class MPUploadBuilderContext: NSObject {
    @objc public let stateMachine: () -> MPStateMachinePRIVATE
    @objc public let lifetimeValue: (NSNumber) -> NSNumber
    @objc public let persistence: () -> MPUploadEnrichmentPersistence
    @objc public let applicationInfo: (MPStateMachinePRIVATE) -> NSDictionary
    @objc public let deviceInfo: (NSNumber) -> NSDictionary
    @objc public let advertiserID: (NSNumber) -> String?
    @objc public let consent: (NSNumber) -> NSDictionary?
    @objc public let transformBatch: (NSDictionary) -> Any?
    @objc public let logger: () -> MPLog?
    @objc public let sdkVersion: String
    @objc public var timestamp: () -> NSNumber = { NSNumber(value: trunc(Date().timeIntervalSince1970 * 1000)) }
    @objc public var messageID: () -> String = { UUID().uuidString }

    @objc public init(
        stateMachine: @escaping () -> MPStateMachinePRIVATE,
        lifetimeValue: @escaping (NSNumber) -> NSNumber,
        persistence: @escaping () -> MPUploadEnrichmentPersistence,
        applicationInfo: @escaping (MPStateMachinePRIVATE) -> NSDictionary,
        deviceInfo: @escaping (NSNumber) -> NSDictionary,
        advertiserID: @escaping (NSNumber) -> String?,
        consent: @escaping (NSNumber) -> NSDictionary?,
        transformBatch: @escaping (NSDictionary) -> Any?,
        logger: @escaping () -> MPLog?,
        sdkVersion: String
    ) {
        self.stateMachine = stateMachine
        self.lifetimeValue = lifetimeValue
        self.persistence = persistence
        self.applicationInfo = applicationInfo
        self.deviceInfo = deviceInfo
        self.advertiserID = advertiserID
        self.consent = consent
        self.transformBatch = transformBatch
        self.logger = logger
        self.sdkVersion = sdkVersion
        super.init()
    }
}
