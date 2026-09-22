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

/// One `(mpid, session, data plan)` bucket of stored messages, ready to be batched into uploads.
///
/// The persistence layer nests messages four dictionaries deep and encodes "absent" as a sentinel
/// value rather than omitting the key. This type carries the decoded form: a sentinel becomes nil.
@objc(MPUploadMessageGroup)
public final class MPUploadMessageGroup: NSObject {
    @objc public let mpid: NSNumber
    @objc public let sessionId: NSNumber?
    @objc public let dataPlanId: String?
    @objc public let dataPlanVersion: NSNumber?
    @objc public let messages: [MPMessagePRIVATE]

    init(
        mpid: NSNumber,
        sessionId: NSNumber?,
        dataPlanId: String?,
        dataPlanVersion: NSNumber?,
        messages: [MPMessagePRIVATE]
    ) {
        self.mpid = mpid
        self.sessionId = sessionId
        self.dataPlanId = dataPlanId
        self.dataPlanVersion = dataPlanVersion
        self.messages = messages
        super.init()
    }
}

@objc(MPUploadGrouping)
public final class MPUploadGrouping: NSObject {
    /// Sentinels the persistence layer writes for "no session" / "no data plan".
    private enum Sentinel {
        static let sessionId = -1
        static let dataPlanId = "0"
        static let dataPlanVersion = 0
    }

    /// Flattens `fetchMessagesForUploading`'s `mpid -> sessionId -> dataPlanId -> dataPlanVersion`
    /// nesting into one group per innermost bucket, decoding the sentinels on the way.
    ///
    /// Entries whose shape does not match are skipped rather than crashing, which is the same for
    /// every well-formed payload. Buckets with no messages are kept: the caller still runs its
    /// save/delete for them, as the original nested enumeration did.
    @objc(groupsFromStoredMessages:)
    public static func groups(fromStoredMessages storedMessages: [AnyHashable: Any]?) -> [MPUploadMessageGroup] {
        var groups: [MPUploadMessageGroup] = []

        for (mpidKey, sessionMessages) in storedMessages ?? [:] {
            guard let mpid = mpidKey as? NSNumber,
                  let sessionMessages = sessionMessages as? [AnyHashable: Any] else { continue }

            for (sessionKey, dataPlanMessages) in sessionMessages {
                guard let sessionId = sessionKey as? NSNumber,
                      let dataPlanMessages = dataPlanMessages as? [AnyHashable: Any] else { continue }

                for (dataPlanKey, versionMessages) in dataPlanMessages {
                    guard let dataPlanId = dataPlanKey as? String,
                          let versionMessages = versionMessages as? [AnyHashable: Any] else { continue }

                    for (versionKey, messages) in versionMessages {
                        guard let dataPlanVersion = versionKey as? NSNumber,
                              let messages = messages as? [Any] else { continue }

                        groups.append(
                            MPUploadMessageGroup(
                                mpid: mpid,
                                sessionId: sessionId.intValue == Sentinel.sessionId ? nil : sessionId,
                                dataPlanId: dataPlanId == Sentinel.dataPlanId ? nil : dataPlanId,
                                dataPlanVersion: dataPlanVersion.intValue == Sentinel.dataPlanVersion
                                    ? nil
                                    : dataPlanVersion,
                                messages: messages.compactMap { $0 as? MPMessagePRIVATE }
                            )
                        )
                    }
                }
            }
        }

        return groups
    }
}

/// The per-message values `MPUploadBuilder` derives before it starts assembling an upload.
@objc(MPPreparedMessages)
public final class MPPreparedMessages: NSObject {
    @objc public let messageDictionaries: [NSDictionary]
    @objc public let preparedMessageIds: [NSNumber]
    @objc public let containsOptOutMessage: Bool

    init(messageDictionaries: [NSDictionary], preparedMessageIds: [NSNumber], containsOptOutMessage: Bool) {
        self.messageDictionaries = messageDictionaries
        self.preparedMessageIds = preparedMessageIds
        self.containsOptOutMessage = containsOptOutMessage
        super.init()
    }
}

public extension MPUploadBuilderFields {
    /// Every message contributes its id; only those that serialize contribute a dictionary, so the
    /// two arrays are deliberately allowed to differ in length. `NSNull` placeholders are skipped.
    @objc(preparedMessagesFrom:)
    static func preparedMessages(from messages: [Any]) -> MPPreparedMessages {
        var dictionaries: [NSDictionary] = []
        var ids: [NSNumber] = []
        var containsOptOut = false

        for case let message as MPMessagePRIVATE in messages {
            if message.messageType == kMPMessageTypeStringOptOut {
                containsOptOut = true
            }
            ids.append(NSNumber(value: message.messageId))
            if let dictionary = message.dictionaryRepresentation() {
                dictionaries.append(dictionary)
            }
        }

        return MPPreparedMessages(
            messageDictionaries: dictionaries,
            preparedMessageIds: ids,
            containsOptOutMessage: containsOptOut
        )
    }
}

/// `kMPMessageTypeStringOptOut` ("o", `MPIConstants.m`), mirrored because the Swift module cannot
/// import the ObjC module.
private let kMPMessageTypeStringOptOut = "o"
