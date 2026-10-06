import Foundation

/// Live dependencies for reading and writing user attributes.
///
/// `validateAndLogAttribute` stays on the Objective-C side rather than calling
/// `MPAttributeValidator` from here: the original logs the offending key and value behind
/// `MPILogError`'s level gate, and several Objective-C tests pass mocks stubbed for a single
/// selector, so the message must not be built eagerly.
@objc(MPBackendUserAttributeDependencies)
public final class MPBackendUserAttributeDependencies: NSObject {
    let userDefaults: () -> MPUserDefaults
    let currentUserId: () -> NSNumber
    let optOut: () -> Bool
    /// The string stored in place of `NSNull`; the `.m` supplies `kMPNullUserAttributeString`, its
    /// one definition.
    let nullSentinel: String
    let validateAndLogAttribute: (String, Any?) -> MPAttributeValidationResult
    var now: () -> Date = { Date() }

    @objc public init(
        userDefaults: @escaping () -> MPUserDefaults,
        currentUserId: @escaping () -> NSNumber,
        optOut: @escaping () -> Bool,
        nullSentinel: String,
        validateAndLogAttribute: @escaping (String, Any?) -> MPAttributeValidationResult
    ) {
        self.userDefaults = userDefaults
        self.currentUserId = currentUserId
        self.optOut = optOut
        self.nullSentinel = nullSentinel
        self.validateAndLogAttribute = validateAndLogAttribute
        super.init()
    }
}

/// Owns the user-attribute dictionary: the stored form, the five public mutations, and the
/// set of keys deleted since the last upload.
@objc(MPBackendUserAttributeWriter)
public final class MPBackendUserAttributeWriter: NSObject {
    private let state: MPBackendSessionState
    private let dependencies: MPBackendSessionDependencies
    private let writer: MPBackendMessageWriter
    private let attributes: MPBackendUserAttributeDependencies

    /// Keys removed since the last upload, which the upload builder sends as deletions.
    /// Cleared by the upload coordinator once a batch carries them.
    ///
    /// Unsynchronised by design: every writer and every reader runs on the serial message queue.
    /// `MParticleUser` dispatches each attribute call there, and `prepareBatchesForUpload` is only
    /// ever reached from it.
    @objc public private(set) var deletedUserAttributes: NSMutableSet?

    @objc public init(
        state: MPBackendSessionState,
        dependencies: MPBackendSessionDependencies,
        writer: MPBackendMessageWriter,
        attributes: MPBackendUserAttributeDependencies
    ) {
        self.state = state
        self.dependencies = dependencies
        self.writer = writer
        self.attributes = attributes
        super.init()
    }

    @objc public func clearDeletedUserAttributes() {
        deletedUserAttributes = nil
    }

    // MARK: - Reading

    /// The stored attributes for a user, with the null sentinel decoded back to `NSNull`.
    @objc(userAttributesForUserId:)
    public func userAttributes(forUserId userId: NSNumber) -> NSMutableDictionary {
        let stored = attributes.userDefaults().mpObject(forKey: MessageKeys.kMPUserAttributeKey, userId: userId)
        guard let stored = stored as? [AnyHashable: Any] else { return NSMutableDictionary() }
        let decoded = MPUserAttributeLogic.attributesFromStorage(stored, nullSentinel: attributes.nullSentinel)
        return NSMutableDictionary(dictionary: decoded)
    }

    @objc public func clearUserAttributes() {
        let defaults = attributes.userDefaults()
        defaults.removeMPObject(forKey: MessageKeys.kMPUserAttributeKey)
        defaults.synchronize()
    }

    // MARK: - The five public mutations

    /// Sets a tag — an attribute whose value is `NSNull`.
    @objc(setUserTag:timestamp:)
    public func setUserTag(_ key: Any?, timestamp: Date?) -> MPBackendUserAttributeOutcome {
        guard let key = validKey(key) else {
            return MPBackendUserAttributeOutcome(key: key, value: nil, status: .missingParam)
        }
        return applyMutation(key: key, value: NSNull(), isArray: false, timestamp: timestamp)
    }

    @objc(setUserAttribute:value:timestamp:)
    public func setUserAttribute(
        _ key: Any?, value: Any?, timestamp: Date?
    ) -> MPBackendUserAttributeOutcome {
        guard let key = validKey(key) else {
            return MPBackendUserAttributeOutcome(key: key, value: value, status: .missingParam)
        }
        guard MPAttributeValidator.isAcceptableScalarValue(value) else {
            return MPBackendUserAttributeOutcome(key: key, value: value, status: .invalidDataType)
        }
        return applyMutation(key: key, value: value, isArray: false, timestamp: timestamp)
    }

    /// `values` is untyped because the Objective-C `NSArray<NSString *>` generic is not enforced:
    /// a non-string entry has to reach the validator, which reports it, rather than the bridge.
    @objc(setUserAttribute:values:timestamp:)
    public func setUserAttribute(
        _ key: Any?, values: Any?, timestamp: Date?
    ) -> MPBackendUserAttributeOutcome {
        guard let key = validKey(key) else {
            return MPBackendUserAttributeOutcome(key: key, value: values, status: .missingParam)
        }
        guard MPAttributeValidator.isAcceptableValueList(values) else {
            return MPBackendUserAttributeOutcome(key: key, value: values, status: .invalidDataType)
        }
        return applyMutation(key: key, value: values, isArray: true, timestamp: timestamp)
    }

    @objc(removeUserAttribute:timestamp:)
    public func removeUserAttribute(_ key: Any?, timestamp: Date?) -> MPBackendUserAttributeOutcome {
        guard let key = validKey(key) else {
            return MPBackendUserAttributeOutcome(key: key, value: nil, status: .missingParam)
        }
        return applyMutation(key: key, value: nil, isArray: false, timestamp: timestamp)
    }

    /// Adds `value` to a numeric attribute, returning the new total, or `nil` when it cannot be
    /// incremented: the stored value is a non-number, or the key or value is unusable. Untyped for
    /// the same reason as the other key-taking methods; the forwarder's `NSAssert`s are debug-only.
    @objc(incrementUserAttribute:byValue:)
    public func incrementUserAttribute(_ key: Any?, byValue value: Any?) -> NSNumber? {
        guard let key = validKey(key), let value = value as? NSNumber else { return nil }
        let timestamp = attributes.now()
        let userId = attributes.currentUserId()
        let stored = userAttributes(forUserId: userId)
        let localKey = caseInsensitiveKey(key, in: stored)

        // Unreachable while `caseInsensitiveKey` falls back to the requested key, and kept only
        // so this conversion changes no behaviour. Removing it is a separate cleanup.
        guard let localKey else {
            _ = setUserAttribute(key, value: value, timestamp: timestamp)
            return value
        }

        var currentValue = stored[localKey]
        if let currentValue, !(currentValue is NSNumber) { return nil }
        if isNull(currentValue) { currentValue = NSNumber(value: 0) }

        let newValue = MPUserAttributeLogic.incrementedValue(
            from: currentValue as? NSNumber ?? NSNumber(value: 0), byValue: value
        )
        stored[localKey] = newValue
        let forStorage = MPUserAttributeLogic.attributesForStorage(
            stored as? [AnyHashable: Any] ?? [:], nullSentinel: attributes.nullSentinel
        )

        // The original re-read storage here to snapshot the change's `userAttributes`, which at
        // this point still holds the pre-increment value; `stored` is the mutated copy.
        let snapshot = userAttributes(forUserId: userId) as? [String: Any]
        if let change = MPUserAttributeChange(userAttributes: snapshot, key: key, value: newValue) {
            change.timestamp = timestamp
            _ = applyChange(change)
        }

        let defaults = attributes.userDefaults()
        defaults[MessageKeys.kMPUserAttributeKey] = forStorage
        defaults.synchronize()

        return newValue
    }

    // MARK: - The shared mutation core

    private func applyMutation(
        key: String, value: Any?, isArray: Bool, timestamp: Date?
    ) -> MPBackendUserAttributeOutcome {
        let snapshot = userAttributes(forUserId: attributes.currentUserId()) as? [String: Any]
        // Unreachable: the change initialiser only fails for a value type the callers above have
        // already rejected, or for a nil value with no attribute snapshot, and the snapshot is
        // never nil. The original passed the nil change straight on, which reported success while
        // storing nothing; reporting the failure with the real key and value is the safer choice
        // for a branch neither version can enter.
        guard let change = MPUserAttributeChange(userAttributes: snapshot, key: key, value: value) else {
            return MPBackendUserAttributeOutcome(key: key, value: value, status: .missingParam)
        }
        change.isArray = isArray
        change.timestamp = timestamp
        return applyChange(change)
    }

    /// Applies one attribute change to storage and logs it when it changed anything.
    ///
    /// The parameter is non-optional; the Objective-C forwarder keeps the nil case, which the
    /// original reported as success without storing anything.
    @objc(applyChange:)
    public func applyChange(_ change: MPUserAttributeChange) -> MPBackendUserAttributeOutcome {
        if attributes.optOut() {
            return MPBackendUserAttributeOutcome(key: change.key, value: change.value, status: .optOut)
        }

        let stored = userAttributes(forUserId: attributes.currentUserId())
        // The `?? change.key` never fires — `caseInsensitiveKey` already falls back to the
        // requested key — and exists only so the helper can keep the optional return type that
        // documents the unreachable branch in `incrementUserAttribute`.
        let localKey = caseInsensitiveKey(change.key, in: stored) ?? change.key
        let validation = attributes.validateAndLogAttribute(localKey, change.value)

        switch MPUserAttributeLogic.mutation(
            forValidationResult: validation, keyExists: stored[localKey] != nil
        ) {
        case .store:
            stored[localKey] = change.value
        case .delete:
            change.deleted = true
            stored.removeObject(forKey: localKey)
            if deletedUserAttributes == nil {
                deletedUserAttributes = NSMutableSet(capacity: 1)
            }
            deletedUserAttributes?.add(change.key)
        case .reject:
            return MPBackendUserAttributeOutcome(
                key: change.key, value: change.value, status: .invalidDataType
            )
        }

        let forStorage = MPUserAttributeLogic.attributesForStorage(
            stored as? [AnyHashable: Any] ?? [:], nullSentinel: attributes.nullSentinel
        )

        if change.changed {
            change.valueToLog = MPUserAttributeLogic.valueToLog(for: change.value)
            logChange(change)
        }

        let defaults = attributes.userDefaults()
        defaults[MessageKeys.kMPUserAttributeKey] = forStorage
        defaults.synchronize()

        return MPBackendUserAttributeOutcome(key: change.key, value: change.value, status: .success)
    }

    /// Writes the user-attribute-change message for an attribute that actually moved.
    @objc(logChange:)
    public func logChange(_ change: MPUserAttributeChange?) {
        guard let change else { return }
        let builder = MPMessageBuilderPRIVATE(
            messageType: MPMessageTypeSwift.userAttributeChange.rawValue,
            session: state.session,
            userAttributeChange: change,
            context: dependencies.makeMessageContext()
        )
        if let timestamp = change.timestamp {
            builder?.updateTimestamp(timestamp.timeIntervalSince1970)
        }
        writer.saveMessage(builder?.build(), updateSession: true)
    }

    // MARK: - Helpers

    /// `nil` for a key that is absent, `NSNull`, or not a string.
    ///
    /// **This is deliberately stricter than the original, and is the one intentional behaviour
    /// change in this conversion.** The original opened with `NSString *keyCopy = [key mutableCopy]`
    /// and only then checked `!MPIsNull(keyCopy) && [keyCopy isKindOfClass:NSString.class]`.
    /// Neither `NSNull` nor `NSNumber` conforms to `NSMutableCopying`, so for any caller that put a
    /// non-string object behind the declared `NSString *` — a wrapper SDK coercing `null` across an
    /// untyped bridge, say — `mutableCopy` raised `NSInvalidArgumentException` and took the process
    /// down before the guard ran. Only a literal `nil` ever reached it. The surviving
    /// `isKindOfClass:` half was unreachable too, because `mutableCopy` on a string returns an
    /// `NSMutableString`, which is one.
    ///
    /// Rejecting those keys with `MPExecStatusMissingParam` instead of crashing is the reason the
    /// parameter is `Any?` rather than `String?`: a `String?` import has no safe representation for
    /// the `NSNull` a caller can still hand us.
    private func validKey(_ key: Any?) -> String? {
        guard !isNull(key), let key = key as? String else { return nil }
        return key
    }

    private func isNull(_ value: Any?) -> Bool {
        value == nil || value is NSNull
    }

    /// The stored key that matches `key` ignoring case, falling back to `key` itself, mirroring
    /// `-[NSDictionary caseInsensitiveKey:]`. The Swift lookup cannot raise, so the Objective-C
    /// category's `@try`/`@catch` has nothing to translate.
    private func caseInsensitiveKey(_ key: String, in dictionary: NSMutableDictionary) -> String? {
        dictionary.mpCaseInsensitiveKey(key) ?? key
    }
}

/// What one attribute mutation produced: the key and value to hand back to the caller's
/// completion handler, and the status the `.m` casts to `MPExecStatus`.
@objc(MPBackendUserAttributeOutcome)
public final class MPBackendUserAttributeOutcome: NSObject {
    @objc public let key: Any?
    @objc public let value: Any?
    @objc public let status: MPExecStatusSwift

    init(key: Any?, value: Any?, status: MPExecStatusSwift) {
        self.key = key
        self.value = value
        self.status = status
        super.init()
    }
}
