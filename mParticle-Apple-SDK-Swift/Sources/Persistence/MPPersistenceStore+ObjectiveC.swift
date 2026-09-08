import Foundation

extension MPPersistenceStorePRIVATE {
    @objc(isDatabaseOpen)
    public func objectiveCDatabaseOpen() -> Bool {
        isDatabaseOpen
    }

    @objc(openDatabase)
    public func objectiveCOpenDatabase() -> Bool {
        (try? openDatabase()) ?? false
    }

    @objc(closeDatabase)
    public func objectiveCCloseDatabase() -> Bool {
        closeDatabase()
        return !isDatabaseOpen
    }

    @objc(resetDatabase)
    public func objectiveCResetDatabase() {
        resetDatabase()
    }

    @objc(resetDatabaseForWorkspaceSwitching)
    public func objectiveCResetDatabaseForWorkspaceSwitching() {
        try? resetDatabaseForWorkspaceSwitching()
    }

    @objc(purgeMemory)
    public func objectiveCPurgeMemory() {
        purgeMemory()
    }

    @objc(deleteRecordsOlderThan:)
    public func objectiveCDeleteRecords(olderThan timestamp: TimeInterval) {
        try? deleteRecordsOlderThan(timestamp)
    }

    @objc(saveSession:)
    public func objectiveCSaveSession(_ session: MPSessionPRIVATE) {
        try? saveSession(session)
    }

    @objc(updateSession:)
    public func objectiveCUpdateSession(_ session: MPSessionPRIVATE) {
        try? updateSession(session)
    }

    @objc(fetchSessions)
    public func objectiveCFetchSessions() -> NSMutableArray? {
        guard let sessions = try? fetchSessions(), !sessions.isEmpty else {
            return nil
        }
        return NSMutableArray(array: sessions)
    }

    @objc(fetchPossibleSessionsFromCrash)
    public func objectiveCFetchPossibleSessionsFromCrash() -> NSArray? {
        guard let sessions = try? fetchPossibleSessionsFromCrash(), !sessions.isEmpty else {
            return nil
        }
        return sessions as NSArray
    }

    @objc(archiveSession:)
    public func objectiveCArchiveSession(_ session: MPSessionPRIVATE) -> MPSessionPRIVATE? {
        try? archiveSession(session)
    }

    @objc(fetchPreviousSession)
    public func objectiveCFetchPreviousSession() -> MPSessionPRIVATE? {
        try? fetchPreviousSession()
    }

    @objc(deletePreviousSession)
    public func objectiveCDeletePreviousSession() {
        try? deletePreviousSession()
    }

    @objc(deleteSession:)
    public func objectiveCDeleteSession(_ session: MPSessionPRIVATE) {
        try? deleteSession(session)
    }

    @objc(deleteAllSessionsExcept:)
    public func objectiveCDeleteAllSessions(except session: MPSessionPRIVATE?) {
        try? deleteAllSessions(except: session)
    }

    @objc(appAndDeviceInfoForSessionId:)
    public func objectiveCAppAndDeviceInfo(forSessionId sessionId: NSNumber) -> NSDictionary {
        (try? appAndDeviceInfo(forSessionId: sessionId)) as NSDictionary? ?? [:]
    }

    @objc(saveMessage:)
    public func objectiveCSaveMessage(_ message: MPMessagePRIVATE) {
        try? saveMessage(message)
    }

    @objc(deleteMessages:)
    public func objectiveCDeleteMessages(_ messages: [MPMessagePRIVATE]) {
        try? deleteMessages(messages)
    }

    @objc(deleteNetworkPerformanceMessages)
    public func objectiveCDeleteNetworkPerformanceMessages() {
        try? deleteNetworkPerformanceMessages()
    }

    @objc(fetchMessagesForUploading)
    public func objectiveCFetchMessagesForUploading() -> NSMutableDictionary? {
        guard let groups = try? fetchMessagesForUploading(), !groups.isEmpty else {
            return nil
        }
        return NSMutableDictionary(dictionary: groups)
    }

    @objc(fetchSessionEndMessageInSession:)
    public func objectiveCFetchSessionEndMessage(in session: MPSessionPRIVATE) -> MPMessagePRIVATE? {
        try? fetchSessionEndMessage(in: session)
    }

    @objc(fetchUploadedMessagesInSession:)
    public func objectiveCFetchUploadedMessages(in session: MPSessionPRIVATE) -> NSArray? {
        guard let messages = try? fetchUploadedMessages(in: session), !messages.isEmpty else {
            return nil
        }
        return messages as NSArray
    }

    @objc(saveBreadcrumb:)
    public func objectiveCSaveBreadcrumb(_ message: MPMessagePRIVATE) {
        try? saveBreadcrumb(message)
    }

    @objc(fetchBreadcrumbs)
    public func objectiveCFetchBreadcrumbs() -> NSArray? {
        guard let breadcrumbs = try? fetchBreadcrumbs(), !breadcrumbs.isEmpty else {
            return nil
        }
        return breadcrumbs as NSArray
    }

    @objc(saveUpload:)
    public func objectiveCSaveUpload(_ upload: MPUploadPRIVATE) {
        _ = try? saveUpload(upload)
    }

    @objc(fetchUploads)
    public func objectiveCFetchUploads() -> NSArray? {
        guard let uploads = try? fetchUploads(), !uploads.isEmpty else {
            return nil
        }
        return uploads as NSArray
    }

    @objc(deleteUpload:)
    public func objectiveCDeleteUpload(_ upload: MPUploadPRIVATE) {
        try? deleteUpload(upload)
    }

    @objc(deleteUploadId:)
    public func objectiveCDeleteUpload(id: Int64) {
        try? deleteUpload(id: id)
    }

    @objc(saveUploads:deleteMessages:)
    public func objectiveCSaveUploads(
        _ uploads: [MPUploadPRIVATE],
        deleteMessages messages: [MPMessagePRIVATE]
    ) -> Bool {
        (try? saveUploads(uploads, deleting: messages)) ?? false
    }

    @objc(saveForwardRecord:)
    public func objectiveCSaveForwardRecord(_ record: MPForwardRecordPRIVATE) {
        try? saveForwardRecord(record)
    }

    @objc(fetchForwardRecords)
    public func objectiveCFetchForwardRecords() -> NSArray? {
        guard let records = try? fetchForwardRecords(), !records.isEmpty else {
            return nil
        }
        return records as NSArray
    }

    @objc(deleteForwardRecordsIds:)
    public func objectiveCDeleteForwardRecords(ids: [NSNumber]) {
        try? deleteForwardRecords(ids: ids)
    }

    @objc(saveIntegrationAttributes:)
    public func objectiveCSaveIntegrationAttributes(_ attributes: MPIntegrationAttributesPRIVATE) {
        try? saveIntegrationAttributes(attributes)
    }

    @objc(fetchIntegrationAttributes)
    public func objectiveCFetchIntegrationAttributes() -> NSArray? {
        guard let attributes = try? fetchIntegrationAttributes(), !attributes.isEmpty else {
            return nil
        }
        return attributes as NSArray
    }

    @objc(fetchIntegrationAttributesForId:)
    public func objectiveCFetchIntegrationAttributes(forId integrationId: NSNumber) -> NSDictionary? {
        try? fetchIntegrationAttributes(for: integrationId)
    }

    @objc(deleteIntegrationAttributesForIntegrationId:)
    public func objectiveCDeleteIntegrationAttributes(forId integrationId: NSNumber) {
        try? deleteIntegrationAttributes(for: integrationId)
    }

    @objc(deleteAllIntegrationAttributes)
    public func objectiveCDeleteAllIntegrationAttributes() {
        try? deleteAllIntegrationAttributes()
    }

    @objc(moveDatabaseContentFromMpidZeroToMpid:)
    public func objectiveCMoveDatabaseContentFromMpidZero(to mpid: NSNumber) {
        try? moveDatabaseContentFromMpidZero(to: mpid)
    }

    @objc(fetchRawCookiesForUserId:)
    public func objectiveCFetchRawCookies(forUserId mpid: NSNumber) -> NSArray? {
        guard let cookies = try? fetchCookies(for: mpid), !cookies.isEmpty else {
            return nil
        }
        return cookies.map(rawCookieDictionary) as NSArray
    }

    @objc(fetchRawConsumerInfoForUserId:)
    public func objectiveCFetchRawConsumerInfo(forUserId mpid: NSNumber) -> NSDictionary? {
        guard let info = try? fetchConsumerInfo(for: mpid) else {
            return nil
        }
        return [
            "id": info.id,
            "mpid": info.mpid,
            "uniqueIdentifier": info.uniqueIdentifier as Any,
            "cookies": info.cookies.map(rawCookieDictionary)
        ]
    }

    @objc(saveRawConsumerInfoForMpid:uniqueIdentifier:cookies:)
    public func objectiveCSaveRawConsumerInfo(
        forMpid mpid: NSNumber,
        uniqueIdentifier: String?,
        cookies: [NSDictionary]
    ) -> Int64 {
        let rawCookies = cookies.compactMap(persistedCookie)
        return (try? saveConsumerInfo(
            mpid: mpid,
            uniqueIdentifier: uniqueIdentifier,
            cookies: rawCookies
        )) ?? 0
    }

    @objc(deleteCookieId:)
    public func objectiveCDeleteCookie(id: Int64) {
        try? deleteCookie(id: id)
    }

    @objc(saveRawCookie:)
    public func objectiveCSaveRawCookie(_ cookie: NSDictionary) -> Int64 {
        guard let cookie = persistedCookie(cookie) else {
            return 0
        }
        return (try? saveCookie(cookie)) ?? 0
    }

    @objc(updateRawCookie:)
    public func objectiveCUpdateRawCookie(_ cookie: NSDictionary) {
        guard let cookie = persistedCookie(cookie) else {
            return
        }
        try? updateCookie(cookie)
    }

    @objc(deleteConsumerInfo)
    public func objectiveCDeleteConsumerInfo() {
        try? deleteConsumerInfo()
    }

    private func rawCookieDictionary(_ cookie: MPPersistedCookie) -> NSDictionary {
        [
            "id": cookie.id,
            "consumerInfoId": cookie.consumerInfoId,
            "content": cookie.content as Any,
            "domain": cookie.domain as Any,
            "expiration": cookie.expiration as Any,
            "name": cookie.name,
            "mpid": cookie.mpid
        ]
    }

    private func persistedCookie(_ dictionary: NSDictionary) -> MPPersistedCookie? {
        guard let name = dictionary["name"] as? String else {
            return nil
        }
        return MPPersistedCookie(
            id: (dictionary["id"] as? NSNumber)?.int64Value ?? 0,
            consumerInfoId: (dictionary["consumerInfoId"] as? NSNumber)?.int64Value ?? 0,
            content: dictionary["content"] as? String,
            domain: dictionary["domain"] as? String,
            expiration: dictionary["expiration"] as? String,
            name: name,
            mpid: (dictionary["mpid"] as? NSNumber)?.int64Value ?? currentMpid().int64Value
        )
    }
}
