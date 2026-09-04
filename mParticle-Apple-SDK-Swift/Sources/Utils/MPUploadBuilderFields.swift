import Foundation

@objc(MPUploadBuilderFields)
public final class MPUploadBuilderFields: NSObject {
    @objc(seedDictionaryWithOptOut:uploadInterval:lifetimeValue:)
    public static func seedDictionary(
        optOut: Bool,
        uploadInterval: TimeInterval,
        lifetimeValue: NSNumber
    ) -> [String: Any] {
        [
            kMPOptOutKeySwift: optOut,
            kMPUploadIntervalKeySwift: uploadInterval,
            kMPLifeTimeValueKeySwift: lifetimeValue
        ]
    }

    /// The `{kMPDataPlanKey: {...}}` fragment `MPUploadBuilder` assigns under
    /// `kMPContextKey`. `nil` when there is no data plan id, matching the
    /// original `if (dataPlanId != nil)` guard.
    @objc(dataPlanDictionaryWithDataPlanId:dataPlanVersion:)
    public static func dataPlanDictionary(dataPlanId: String?, dataPlanVersion: NSNumber?) -> [String: Any]? {
        guard let dataPlanId else {
            return nil
        }

        var innerDictionary: [String: Any] = [kMPDataPlanIdKeySwift: dataPlanId]
        if let dataPlanVersion {
            innerDictionary[kMPDataPlanVersionKeySwift] = dataPlanVersion
        }

        return [kMPDataPlanKeySwift: innerDictionary]
    }

    /// `nil` when `customModules` is `nil`, matching the original
    /// `if (stateMachine.customModules)` guard — an empty (non-nil) array
    /// still produces an empty (non-nil) dictionary.
    @objc(customModulesDictionaryFrom:)
    public static func customModulesDictionary(from customModules: [CustomModule]?) -> [String: Any]? {
        guard let customModules else {
            return nil
        }

        var result: [String: Any] = [:]
        for customModule in customModules {
            result[customModule.customModuleId.stringValue] = customModule.dictionaryRepresentation()
        }
        return result
    }

    /// Stringifies `NSNumber` values, leaving every other value untouched —
    /// mirrors `withUserAttributes:deletedUserAttributes:`'s per-key loop.
    @objc(stringifiedUserAttributes:)
    public static func stringifiedUserAttributes(_ userAttributes: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in userAttributes {
            if let number = value as? NSNumber {
                result[key] = number.stringValue
            } else {
                result[key] = value
            }
        }
        return result
    }

    /// The five upload-header fields `build:` seeds the dictionary with.
    /// `sdkVersion` and `apiKey` are passed in rather than mirrored, since
    /// `kMParticleSDKVersion` changes every release and mirroring it here
    /// would give the release workflow a second, unsynced place to edit.
    @objc(headerFieldsWithMessageId:timestampMs:sdkVersion:apiKey:)
    public static func headerFields(
        messageId: String,
        timestampMs: NSNumber,
        sdkVersion: String,
        apiKey: String?
    ) -> [String: Any] {
        var fields: [String: Any] = [
            kMPMessageTypeKeySwift: kMPMessageTypeRequestHeaderSwift,
            kMPmParticleSDKVersionKeySwift: sdkVersion,
            kMPMessageIdKeySwift: messageId,
            kMPTimestampKeySwift: timestampMs
        ]
        if let apiKey {
            fields[kMPApplicationKeySwift] = apiKey
        }
        return fields
    }

    /// `nil` when the device shouldn't be updated with an advertiser id —
    /// mirrors `build:`'s `if (authStatus && advertiserId && authStatus.intValue
    /// == MPATTAuthorizationStatusAuthorized)` guard. The caller computes
    /// `isATTAuthorized` since the raw `MPATTAuthorizationStatus` enum can't
    /// cross into this Foundation-only module.
    @objc(deviceInfoDictionaryByAddingAdvertiserId:isATTAuthorized:to:)
    public static func deviceInfoDictionary(
        byAddingAdvertiserId advertiserId: String?,
        isATTAuthorized: Bool,
        to deviceInfoDictionary: [String: Any]?
    ) -> [String: Any]? {
        guard isATTAuthorized, let advertiserId, let deviceInfoDictionary else {
            return nil
        }

        var updated = deviceInfoDictionary
        updated[kMPDeviceAdvertiserIdKeySwift] = advertiserId
        return updated
    }

    /// Pairs each forward record's data dictionary with its record id and
    /// drops any record without one — mirrors `build:`'s
    /// `if (forwardRecord.dataDictionary)` filter, which keeps `dataDictionaries`
    /// and `recordIds` in step so the caller only deletes the records it
    /// actually queued for upload.
    @objc(forwardRecordBatchFromDataDictionaries:recordIds:)
    public static func forwardRecordBatch(dataDictionaries: [Any], recordIds: [NSNumber]) -> MPForwardRecordBatch {
        var filteredDictionaries: [NSDictionary] = []
        var filteredIds: [NSNumber] = []

        for (index, dataDictionary) in dataDictionaries.enumerated() where index < recordIds.count {
            guard let dictionary = dataDictionary as? NSDictionary else {
                continue
            }
            filteredDictionaries.append(dictionary)
            filteredIds.append(recordIds[index])
        }

        return MPForwardRecordBatch(dataDictionaries: filteredDictionaries, recordIds: filteredIds)
    }

    /// Merges every integration attribute's dictionary representation into
    /// one dictionary, later entries winning on a key collision — mirrors
    /// `build:`'s repeated `addEntriesFromDictionary:` calls.
    @objc(mergedIntegrationAttributesDictionaryFrom:)
    public static func mergedIntegrationAttributesDictionary(from dictionaries: [NSDictionary]) -> [String: Any] {
        var merged: [String: Any] = [:]
        for dictionary in dictionaries {
            for (key, value) in dictionary {
                if let key = key as? String {
                    merged[key] = value
                }
            }
        }
        return merged
    }
}

/// The parallel (data dictionary, record id) arrays `build:` uploads and,
/// on success, deletes from persistence.
@objc(MPForwardRecordBatch)
public final class MPForwardRecordBatch: NSObject {
    @objc public let dataDictionaries: [NSDictionary]
    @objc public let recordIds: [NSNumber]

    init(dataDictionaries: [NSDictionary], recordIds: [NSNumber]) {
        self.dataDictionaries = dataDictionaries
        self.recordIds = recordIds
        super.init()
    }
}

/// `kMPOptOutKey` (`MPIConstants.m:53`). Mirrored because the Swift module
/// cannot import the ObjC module.
private let kMPOptOutKeySwift = "oo"
/// `kMPUploadIntervalKey` (`MPIConstants.m:139`).
private let kMPUploadIntervalKeySwift = "uitl"
/// `kMPLifeTimeValueKey` (`MPIConstants.m:141`).
private let kMPLifeTimeValueKeySwift = "ltv"
/// `kMPDataPlanKey` (`MPIConstants.m:61`).
private let kMPDataPlanKeySwift = "dpln"
/// `kMPDataPlanIdKey` (`MPIConstants.m:62`).
private let kMPDataPlanIdKeySwift = "id"
/// `kMPDataPlanVersionKey` (`MPIConstants.m:63`).
private let kMPDataPlanVersionKeySwift = "v"
/// `kMPMessageTypeKey` (`MPIConstants.m:7`).
private let kMPMessageTypeKeySwift = "dt"
/// `kMPMessageTypeRequestHeader` (`MPIConstants.m:8`).
private let kMPMessageTypeRequestHeaderSwift = "h"
/// `kMPmParticleSDKVersionKey` (`MPIConstants.m:15`).
private let kMPmParticleSDKVersionKeySwift = "sdk"
/// `kMPApplicationKey` (`MPIConstants.m:16`).
private let kMPApplicationKeySwift = "a"
/// `kMPMessageIdKey` (`MPIConstants.m:31`).
private let kMPMessageIdKeySwift = "id"
/// `kMPTimestampKey` (`MPIConstants.m:33`).
private let kMPTimestampKeySwift = "ct"
/// `kMPDeviceAdvertiserIdKey` (`MPIConstants.m:391`).
private let kMPDeviceAdvertiserIdKeySwift = "aid"
