//
//  MParticleKitBatchTests.swift
//  mParticle-Apple-SDK
//
//  Created by Nick Dimitrakas on 11/3/25.
//

import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

final class MParticleKitBatchTests: MParticleTestBase {
    
    func testLogKitBatch_withNilBatch_doesNotExecuteOrForward() {
        mparticle.logKitBatch(nil)

        assertReceivedMessage("Cannot log nil batch!")
        XCTAssertFalse(executor.executeOnMessageQueueAsync)
        XCTAssertFalse(kitContainer.hasKitBatchingKitsCalled)
        XCTAssertFalse(executor.executeOnMainAsync)
        XCTAssertFalse(kitContainer.forwardSDKCallCalled)
        XCTAssertFalse(persistenceController.saveCalled)
    }
    
    func testLogKitBatch_noBatchingKits_andKitsInitialized_doesNothing() {
        kitContainer.kitsInitialized = true
        kitContainer.hasKitBatchingKitsReturnValue = false

        mparticle.logKitBatch(LogKitBatchData.singleEvent)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertFalse(executor.executeOnMainAsync)
        XCTAssertFalse(kitContainer.forwardSDKCallCalled)
        XCTAssertFalse(persistenceController.saveCalled)
    }

    func testLogKitBatch_kitsNotInitialized_defersWorkUntilInitialization() {
        kitContainer.kitsInitialized = false
        kitContainer.hasKitBatchingKitsReturnValue = true

        mparticle.logKitBatch(LogKitBatchData.singleEvent)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        
        // Should queue deferred block, not execute immediately
        XCTAssertFalse(executor.executeOnMainAsync)
        XCTAssertFalse(kitContainer.forwardSDKCallCalled)
        XCTAssertFalse(persistenceController.saveCalled)

        // Simulate kits becoming initialized
        kitContainer.kitsInitialized = true
        mparticle.executeKitsInitializedBlocks()

        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "executeKitsInitializedBlocks")
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logBatch:")
        XCTAssertEqual(kitContainer.forwardSDKCallBatchParam?.count, 1)
        XCTAssertNotNil(kitContainer.forwardSDKCallKitHandlerParam)
    }

    func testLogKitBatch_withBatchingKits_forwardsParsedBatch_andPersistsForwardRecords() {
        kitContainer.kitsInitialized = true
        kitContainer.hasKitBatchingKitsReturnValue = true

        mparticle.logKitBatch(LogKitBatchData.multiEvent)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logBatch:")
        XCTAssertEqual(kitContainer.forwardSDKCallBatchParam?.count, 1)
        XCTAssertNotNil(kitContainer.forwardSDKCallKitHandlerParam)
    }
    
    func testLogKitBatch_invokesKitHandler_andPersistsForwardRecords() {
        kitContainer.kitsInitialized = true
        kitContainer.hasKitBatchingKitsReturnValue = true

        let forwardRecord = MPForwardRecord()
        kit.logBatchReturnValue = [forwardRecord]

        mparticle.logKitBatch(LogKitBatchData.singleEvent)

        guard let kitHandler = kitContainer.forwardSDKCallKitHandlerParam else {
            XCTFail("Expected kitHandler closure to be captured")
            return
        }

        // Simulate invoking the handler
        let config = MPKitConfiguration()
        kitHandler(kit, LogKitBatchData.parsedSingleEvent, config)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logBatch:")
        XCTAssertEqual(kitContainer.forwardSDKCallBatchParam?.count, 1)
        XCTAssertTrue(kit.logBatchCalled)
        XCTAssertEqual(kit.logBatchParam?["events"] as? [[String: Int]],
                       LogKitBatchData.parsedSingleEvent.values.first as? [[String : Int]])
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(persistenceController.saveCalled)
        XCTAssertTrue(persistenceController.saveForwardRecordParam === forwardRecord)
    }

    func testLogKitBatch_invalidJSON_stillForwardsWithNilBatch() {
        kitContainer.kitsInitialized = true
        kitContainer.hasKitBatchingKitsReturnValue = true

        mparticle.logKitBatch(LogKitBatchData.invalidJSON)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logBatch:")
        XCTAssertEqual(kitContainer.forwardSDKCallBatchParam?.count, 0)
        XCTAssertNotNil(kitContainer.forwardSDKCallKitHandlerParam)
    }
}
