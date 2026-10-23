import Foundation

/// The persistence operations the Objective-C core reaches through `MParticle.persistenceAdapter`.
/// Every requirement is optional, as in the Objective-C protocol this replaces, so test doubles
/// implement only what they exercise.
@objc(MPPersistenceAdapting)
public protocol MPPersistenceAdapting: NSObjectProtocol {
    @objc(saveForwardRecord:) optional func save(_ forwardRecord: MPForwardRecordPRIVATE?)
    @objc(fetchIntegrationAttributes) optional func fetchIntegrationAttributes() -> [MPIntegrationAttributesPRIVATE]?
    @objc(fetchIntegrationAttributesForId:)
    optional func fetchIntegrationAttributes(forId integrationId: NSNumber) -> [AnyHashable: Any]?
    @objc(saveIntegrationAttributes:) optional func save(_ integrationAttributes: MPIntegrationAttributesPRIVATE)
    @objc(deleteIntegrationAttributesForIntegrationId:)
    optional func deleteIntegrationAttributes(forIntegrationId integrationId: NSNumber)
    @objc(fetchConsumerInfoForUserId:) optional func fetchConsumerInfo(forUserId userId: NSNumber) -> MPConsumerInfoPRIVATE?
    @objc(fetchCookiesForUserId:) optional func fetchCookies(forUserId userId: NSNumber) -> [MPCookiePRIVATE]?
    @objc(saveConsumerInfo:) optional func save(_ consumerInfo: MPConsumerInfoPRIVATE)
    @objc(updateConsumerInfo:) optional func update(_ consumerInfo: MPConsumerInfoPRIVATE)
    @objc(moveContentFromMpidZeroToMpid:) optional func moveContentFromMpidZero(toMpid mpid: NSNumber)
    @objc(updateSession:) optional func update(_ session: MPSessionPRIVATE)
    @objc(saveUpload:optedOut:) optional func saveUpload(_ upload: MPUploadPRIVATE, optedOut: Bool)
    @objc(deleteUpload:) optional func deleteUpload(_ upload: MPUploadPRIVATE)
    @objc(resetDatabase) optional func resetDatabase()
    @objc(resetDatabaseForWorkspaceSwitching) optional func resetDatabaseForWorkspaceSwitching()
}

/// Maps the SDK's model objects onto the rows of the Swift store.
@objc(MPPersistenceAdapter)
public final class MPPersistenceAdapter: NSObject, MPPersistenceAdapting {
    private let store: MPPersistenceStorePRIVATE
    private let userDefaults: UserDefaults

    @objc(initWithStore:)
    public convenience init(store: MPPersistenceStorePRIVATE) {
        self.init(store: store, userDefaults: .standard)
    }

    init(store: MPPersistenceStorePRIVATE, userDefaults: UserDefaults) {
        self.store = store
        self.userDefaults = userDefaults
        super.init()
    }

    /// The store writes the row id it assigns into `forwardRecord`, which is the object an
    /// `MPForwardRecord` reads its `forwardRecordId` through. nil, from a record created with
    /// plain `-init`, has nothing to save.
    @objc(saveForwardRecord:)
    public func save(_ forwardRecord: MPForwardRecordPRIVATE?) {
        guard let forwardRecord else { return }
        store.objectiveCSaveForwardRecord(forwardRecord)
    }

    @objc(fetchIntegrationAttributes)
    public func fetchIntegrationAttributes() -> [MPIntegrationAttributesPRIVATE]? {
        store.objectiveCFetchIntegrationAttributes() as? [MPIntegrationAttributesPRIVATE]
    }

    @objc(fetchIntegrationAttributesForId:)
    public func fetchIntegrationAttributes(forId integrationId: NSNumber) -> [AnyHashable: Any]? {
        store.objectiveCFetchIntegrationAttributes(forId: integrationId) as? [AnyHashable: Any]
    }

    @objc(saveIntegrationAttributes:)
    public func save(_ integrationAttributes: MPIntegrationAttributesPRIVATE) {
        store.objectiveCSaveIntegrationAttributes(integrationAttributes)
    }

    @objc(deleteIntegrationAttributesForIntegrationId:)
    public func deleteIntegrationAttributes(forIntegrationId integrationId: NSNumber) {
        store.objectiveCDeleteIntegrationAttributes(forId: integrationId)
    }

    @objc(fetchCookiesForUserId:)
    public func fetchCookies(forUserId userId: NSNumber) -> [MPCookiePRIVATE]? {
        guard let rows = try? store.fetchCookies(for: userId), !rows.isEmpty else {
            return nil
        }
        return rows.map { row in
            let cookie = MPCookiePRIVATE()
            cookie.cookieId = row.id
            cookie.content = row.content
            cookie.domain = row.domain
            cookie.expiration = row.expiration
            cookie.name = row.name
            return cookie
        }
    }

    @objc(fetchConsumerInfoForUserId:)
    public func fetchConsumerInfo(forUserId userId: NSNumber) -> MPConsumerInfoPRIVATE? {
        guard let cookies = fetchCookies(forUserId: userId) else {
            return nil
        }
        let consumerInfo = MPConsumerInfoPRIVATE()
        consumerInfo.cookies = cookies
        return consumerInfo
    }

    /// Expired cookies are not saved. The consumer-info id, and each saved cookie's id in order,
    /// are written back onto the objects; a failed save leaves the consumer-info id at 0.
    @objc(saveConsumerInfo:)
    public func save(_ consumerInfo: MPConsumerInfoPRIVATE) {
        let mpid = store.currentMpid()
        let cookies = consumerInfo.cookies ?? []
        let rows = cookies.filter { !$0.expired }.map { persistedCookie($0, consumerInfoId: 0, mpid: mpid) }
        let saved = try? store.saveConsumerInfoWithCookieIds(
            mpid: mpid,
            uniqueIdentifier: consumerInfo.uniqueIdentifier,
            cookies: rows
        )
        consumerInfo.consumerInfoId = saved?.consumerInfoId ?? 0
        let cookieIds = saved?.cookieIds ?? []
        var cookieIdIndex = 0
        for cookie in cookies where !cookie.expired && cookieIdIndex < cookieIds.count {
            cookie.cookieId = cookieIds[cookieIdIndex]
            cookieIdIndex += 1
        }
    }

    /// Expired cookies are deleted if they were saved, unsaved ones are saved and given their new
    /// id, and the rest are updated in place.
    @objc(updateConsumerInfo:)
    public func update(_ consumerInfo: MPConsumerInfoPRIVATE) {
        let mpid = store.currentMpid()
        for cookie in consumerInfo.cookies ?? [] {
            let row = persistedCookie(cookie, consumerInfoId: consumerInfo.consumerInfoId, mpid: mpid)
            if cookie.expired {
                if cookie.cookieId != 0 {
                    try? store.deleteCookie(id: cookie.cookieId)
                }
            } else if cookie.cookieId == 0 {
                cookie.cookieId = (try? store.saveCookie(row)) ?? 0
            } else {
                try? store.updateCookie(row)
            }
        }
    }

    /// Moves every `mParticle::0` user-defaults entry to the same key under `mpid` without
    /// overwriting an entry already there, then moves the database rows.
    @objc(moveContentFromMpidZeroToMpid:)
    public func moveContentFromMpidZero(toMpid mpid: NSNumber) {
        MPPersistenceUserDefaultsMigrator(userDefaults: userDefaults).moveContentFromMpidZero(to: mpid)
        try? store.moveDatabaseContentFromMpidZero(to: mpid)
    }

    @objc(updateSession:)
    public func update(_ session: MPSessionPRIVATE) {
        store.objectiveCUpdateSession(session)
    }

    @objc(saveUpload:optedOut:)
    public func saveUpload(_ upload: MPUploadPRIVATE, optedOut: Bool) {
        store.objectiveCSaveUpload(upload, optedOut: optedOut)
    }

    @objc(deleteUpload:)
    public func deleteUpload(_ upload: MPUploadPRIVATE) {
        store.objectiveCDeleteUpload(upload)
    }

    @objc(resetDatabase)
    public func resetDatabase() {
        store.objectiveCResetDatabase()
    }

    @objc(resetDatabaseForWorkspaceSwitching)
    public func resetDatabaseForWorkspaceSwitching() {
        store.objectiveCResetDatabaseForWorkspaceSwitching()
    }

    private func persistedCookie(_ cookie: MPCookiePRIVATE, consumerInfoId: Int64, mpid: NSNumber) -> MPPersistedCookie {
        MPPersistedCookie(
            id: cookie.cookieId,
            consumerInfoId: consumerInfoId,
            content: cookie.content,
            domain: cookie.domain,
            expiration: cookie.expiration,
            name: cookie.name,
            mpid: mpid.int64Value
        )
    }
}
