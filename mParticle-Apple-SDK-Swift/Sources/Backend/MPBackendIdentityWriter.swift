import Foundation

/// Owns the stored user-identity array: reading it, applying one identity change to it, and
/// writing the user-identity-change message for a change that moved anything.
@objc(MPBackendIdentityWriter)
public final class MPBackendIdentityWriter: NSObject {
    private let state: MPBackendSessionState
    private let dependencies: MPBackendSessionDependencies
    private let writer: MPBackendMessageWriter
    private let host: MPBackendHost
    /// The date a newly added identity is first set on; overridden by tests.
    var now: () -> Date = { Date() }

    init(
        state: MPBackendSessionState,
        dependencies: MPBackendSessionDependencies,
        writer: MPBackendMessageWriter,
        host: MPBackendHost
    ) {
        self.state = state
        self.dependencies = dependencies
        self.writer = writer
        self.host = host
        super.init()
    }

    /// The stored identities of `userId` whose type is a user identity. Entries without a numeric
    /// type, or of a device identity type, are left out.
    @objc(userIdentitiesForUserId:)
    public func userIdentities(forUserId userId: NSNumber) -> NSMutableArray {
        NSMutableArray(array: validIdentities(forUserId: userId))
    }

    /// Sets, replaces or removes the identity of `identityType` for the current user.
    ///
    /// `identity` is untyped because a caller can hand over `NSNull`, or another object behind the
    /// declared string: `nil`, `NSNull` and the empty string remove the identity, and any other
    /// non-string is rejected with `invalidDataType` without touching storage.
    @objc(setUserIdentity:identityType:timestamp:)
    public func setUserIdentity(
        _ identity: Any?, identityType: MPUserIdentitySwift, timestamp: Date?
    ) -> MPBackendIdentityOutcome {
        let value: String?
        if identity == nil || identity is NSNull {
            value = nil
        } else if let string = identity as? String {
            value = string
        } else {
            return MPBackendIdentityOutcome(value: identity, type: identityType, status: .invalidDataType)
        }

        let userId = host.mpId()
        let newIdentity = MPUserIdentityInstancePRIVATE(type: identityType, value: value)
        let change = MPUserIdentityChangePRIVATE(
            newUserIdentity: newIdentity,
            userIdentities: stringKeyed(identitiesWithoutUnauthorizedAdvertiserId(forUserId: userId))
        )
        change.timestamp = timestamp

        var current = stringKeyed(validIdentities(forUserId: userId))
        let plan = MPUserIdentityLogic.plan(
            forIdentityType: NSNumber(value: identityType.rawValue),
            value: value,
            currentIdentities: current,
            typeKey: MessageKeys.kMPUserIdentityTypeKey,
            idKey: MessageKeys.kMPUserIdentityIdKey,
            dateFirstSetKey: MessageKeys.kMPDateUserIdentityWasFirstSet,
            now: now()
        )

        switch plan.kind {
        case .unchanged:
            return MPBackendIdentityOutcome(value: value, type: identityType, status: .fail)
        case .nothingToRemove:
            break
        case .remove:
            change.oldUserIdentity = MPUserIdentityInstancePRIVATE(userIdentityDictionary: plan.existingIdentity ?? [:])
            change.newUserIdentity = nil
            current.remove(at: plan.index)
        case .add:
            newIdentity.dateFirstSet = plan.dateFirstSet
            newIdentity.isFirstTimeSet = plan.isFirstTimeSet
            current.append(stringKeyed(newIdentity.dictionaryRepresentation() as? [AnyHashable: Any] ?? [:]))
        case .replace:
            change.oldUserIdentity = MPUserIdentityInstancePRIVATE(userIdentityDictionary: plan.existingIdentity ?? [:])
            newIdentity.dateFirstSet = plan.dateFirstSet
            newIdentity.isFirstTimeSet = plan.isFirstTimeSet
            current[plan.index] = stringKeyed(newIdentity.dictionaryRepresentation() as? [AnyHashable: Any] ?? [:])
        }

        if plan.kind != .nothingToRemove, change.changed {
            logChange(change)
            let defaults = host.userDefaults()
            defaults[MessageKeys.kMPUserIdentityArrayKey] = current
            defaults.synchronize()
        }

        // A removal reports no value and type 0, the outcome callers' completion handlers expect.
        return MPBackendIdentityOutcome(
            value: change.newUserIdentity?.value,
            type: change.newUserIdentity?.type ?? .other,
            status: .success
        )
    }

    // MARK: - Helpers

    /// The stored identity entries of `userId`, skipping anything that is not a dictionary.
    private func storedIdentities(forUserId userId: NSNumber) -> [[AnyHashable: Any]] {
        let stored = host.userDefaults().mpObject(forKey: MessageKeys.kMPUserIdentityArrayKey, userId: userId)
        return (stored as? [Any])?.compactMap { $0 as? [AnyHashable: Any] } ?? []
    }

    private func validIdentities(forUserId userId: NSNumber) -> [[AnyHashable: Any]] {
        MPUserIdentityLogic.validIdentities(
            storedIdentities(forUserId: userId),
            typeKey: MessageKeys.kMPUserIdentityTypeKey,
            maxValidTypeExclusive: MPIdentitySwift.iosAdvertiserId.rawValue
        )
    }

    /// The stored identities, without the advertiser ID while app tracking is known not to be
    /// authorized. The change compares the new identity against these.
    private func identitiesWithoutUnauthorizedAdvertiserId(forUserId userId: NSNumber) -> [[AnyHashable: Any]] {
        let status = host.stateMachine().attAuthorizationStatus
        let notAuthorized = status != nil && status?.intValue != MPATTAuthorizationStatusSwift.authorized.rawValue
        return MPUserIdentityLogic.identities(
            storedIdentities(forUserId: userId),
            removingType: MPIdentitySwift.iosAdvertiserId.rawValue,
            when: notAuthorized,
            typeKey: MessageKeys.kMPUserIdentityTypeKey
        )
    }

    private func stringKeyed(_ identities: [[AnyHashable: Any]]) -> [[String: Any]] {
        identities.map { stringKeyed($0) }
    }

    private func stringKeyed(_ identity: [AnyHashable: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for case let (key as String, value) in identity {
            result[key] = value
        }
        return result
    }

    /// Writes the user-identity-change message.
    private func logChange(_ change: MPUserIdentityChangePRIVATE) {
        let builder = MPMessageBuilderPRIVATE(
            messageType: MPMessageTypeSwift.userIdentityChange.rawValue,
            session: state.session,
            userIdentityChange: change,
            context: dependencies.makeMessageContext()
        )
        if let timestamp = change.timestamp {
            builder?.updateTimestamp(timestamp.timeIntervalSince1970)
        }
        writer.saveMessage(builder?.build(), updateSession: true)
    }
}

/// What setting one identity produced: the value, type and status to hand back to the caller's
/// completion handler.
@objc(MPBackendIdentityOutcome)
public final class MPBackendIdentityOutcome: NSObject {
    @objc public let value: Any?
    @objc public let type: MPUserIdentitySwift
    @objc public let status: MPExecStatus

    init(value: Any?, type: MPUserIdentitySwift, status: MPExecStatus) {
        self.value = value
        self.type = type
        self.status = status
        super.init()
    }
}
