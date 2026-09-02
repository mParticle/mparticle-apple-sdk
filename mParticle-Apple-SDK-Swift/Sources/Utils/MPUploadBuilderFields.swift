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
