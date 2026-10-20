import Foundation

/// Sets and increments attributes on a session, and saves the session after each change.
@objc(MPBackendSessionAttributeWriter)
public final class MPBackendSessionAttributeWriter: NSObject {
    private let dependencies: MPBackendSessionDependencies
    private let host: MPBackendHost

    init(dependencies: MPBackendSessionDependencies, host: MPBackendHost) {
        self.dependencies = dependencies
        self.host = host
        super.init()
    }

    /// Stores `value` under `key`, or under the stored key that matches it ignoring case, and saves
    /// the session. `key` is untyped because a caller can pass a non-string where a string is
    /// declared; that, an unsupported or invalid value, and the value already stored are reported
    /// as `invalidDataType`.
    @objc(setSessionAttribute:key:value:)
    public func setAttribute(_ session: MPSessionPRIVATE?, key: Any?, value: Any?) -> MPExecStatus {
        guard let session else { return .missingParam }
        guard let key = key as? String else { return .invalidDataType }
        guard value is NSString || value is NSNumber else { return .invalidDataType }

        let attributes = session.attributesDictionary
        let localKey = attributes.mpCaseInsensitiveKey(key) ?? key
        let result = MPBackendAttributeValidation.validate(key: localKey, value: value, host: host)
        if result != .valid || (attributes[localKey] as? NSObject)?.isEqual(value) == true {
            return .invalidDataType
        }

        attributes[localKey] = value
        dependencies.persistence()?.objectiveCUpdateSession(session)
        return .success
    }

    /// Adds `value` to the number stored under `key`, or stores `value` when there is none, and
    /// returns the result. Returns nil when there is no session, `key` is not a string, the stored
    /// value is not a number, or `value` is not a number. A first value is stored and saved as
    /// `setAttribute` does, and is returned even when that rejects it; an increment saves the
    /// session on the message queue.
    @objc(incrementSessionAttribute:key:byValue:)
    public func incrementAttribute(_ session: MPSessionPRIVATE?, key: Any?, byValue value: Any?) -> NSNumber? {
        guard let session, let key = key as? String else { return nil }

        let attributes = session.attributesDictionary
        let localKey = attributes.mpCaseInsensitiveKey(key) ?? key
        let currentValue = attributes[localKey]
        if currentValue == nil, let value = value as? NSNumber {
            _ = setAttribute(session, key: localKey, value: value)
            return value
        }

        guard let currentValue = currentValue as? NSNumber, let value = value as? NSNumber else { return nil }
        let newValue = MPUserAttributeLogic.incrementedValue(from: currentValue, byValue: value)
        attributes[localKey] = newValue
        dependencies.enqueueOnMessage { [dependencies] in
            dependencies.persistence()?.objectiveCUpdateSession(session)
        }
        return newValue
    }
}
