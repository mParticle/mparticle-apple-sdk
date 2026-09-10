import Foundation

@objc public protocol MPPersistenceLifecycle {
    @objc(isDatabaseOpen) func objectiveCDatabaseOpen() -> Bool
    @objc(openDatabase) func objectiveCOpenDatabase() -> Bool
    @objc(closeDatabase) func objectiveCCloseDatabase() -> Bool
    @objc(purgeMemory) func objectiveCPurgeMemory()
    @objc(deleteRecordsOlderThan:) func objectiveCDeleteRecords(olderThan timestamp: TimeInterval)
}

@objc public protocol MPSessionPersistence {
    @objc(saveSession:) func objectiveCSaveSession(_ session: MPSessionPRIVATE)
    @objc(updateSession:) func objectiveCUpdateSession(_ session: MPSessionPRIVATE)
    @objc(fetchSessions) func objectiveCFetchSessions() -> NSMutableArray?
    @objc(fetchPossibleSessionsFromCrash) func objectiveCFetchPossibleSessionsFromCrash() -> NSArray?
    @objc(archiveSession:) func objectiveCArchiveSession(_ session: MPSessionPRIVATE) -> MPSessionPRIVATE?
    @objc(fetchPreviousSession) func objectiveCFetchPreviousSession() -> MPSessionPRIVATE?
    @objc(deletePreviousSession) func objectiveCDeletePreviousSession()
    @objc(deleteSession:) func objectiveCDeleteSession(_ session: MPSessionPRIVATE)
    @objc(deleteAllSessionsExcept:) func objectiveCDeleteAllSessions(except session: MPSessionPRIVATE?)
    @objc(appAndDeviceInfoForSessionId:)
    func objectiveCAppAndDeviceInfo(forSessionId sessionId: NSNumber) -> NSDictionary
}

@objc public protocol MPMessagePersistence {
    @objc(saveMessage:) func objectiveCSaveMessage(_ message: MPMessagePRIVATE)
    @objc(deleteMessages:) func objectiveCDeleteMessages(_ messages: [MPMessagePRIVATE])
    @objc(deleteNetworkPerformanceMessages) func objectiveCDeleteNetworkPerformanceMessages()
    @objc(fetchMessagesForUploading) func objectiveCFetchMessagesForUploading() -> NSMutableDictionary?
    @objc(fetchSessionEndMessageInSession:)
    func objectiveCFetchSessionEndMessage(in session: MPSessionPRIVATE) -> MPMessagePRIVATE?
    @objc(fetchUploadedMessagesInSession:)
    func objectiveCFetchUploadedMessages(in session: MPSessionPRIVATE) -> NSArray?
    @objc(saveBreadcrumb:) func objectiveCSaveBreadcrumb(_ message: MPMessagePRIVATE)
    @objc(fetchBreadcrumbs) func objectiveCFetchBreadcrumbs() -> NSArray?
}

@objc public protocol MPUploadPersistence {
    @objc(saveUpload:optedOut:)
    func objectiveCSaveUpload(_ upload: MPUploadPRIVATE, optedOut: Bool)
    @objc(fetchUploads) func objectiveCFetchUploads() -> NSArray?
    @objc(deleteUpload:) func objectiveCDeleteUpload(_ upload: MPUploadPRIVATE)
    @objc(deleteUploadId:) func objectiveCDeleteUpload(id: Int64)
    @objc(saveUploads:deleteMessages:optedOut:)
    func objectiveCSaveUploads(
        _ uploads: [MPUploadPRIVATE],
        deleteMessages messages: [MPMessagePRIVATE],
        optedOut: Bool
    ) -> Bool
}

@objc public protocol MPBackendPersistence:
    MPPersistenceLifecycle,
    MPSessionPersistence,
    MPMessagePersistence,
    MPUploadPersistence {}

extension MPPersistenceStorePRIVATE: MPBackendPersistence {}
