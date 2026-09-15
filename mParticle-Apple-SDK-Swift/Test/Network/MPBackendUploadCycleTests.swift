import Foundation
import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendUploadCycleTests: XCTestCase {
    func testConfigurationRejectionCompletesWithoutReadinessOrPreparationOrRetry() {
        let fixture = MPUploadCoordinatorFixture()
        fixture.network.configSuccess = false
        fixture.kitsDelayed = true
        fixture.setMessages([fixture.message(id: 1)])
        var completed = false
        fixture.coordinator.waitForKitsAndUpload { completed = true }
        XCTAssertTrue(completed)
        XCTAssertEqual(fixture.network.configRequests, 1)
        XCTAssertEqual(fixture.kitChecks, 0)
        XCTAssertEqual(fixture.webChecks, 0)
        XCTAssertTrue(fixture.persistence.transactions.isEmpty)
        XCTAssertTrue(fixture.network.uploaded.isEmpty)
        XCTAssertTrue(fixture.scheduled.isEmpty)
    }

    func testReadinessRetriesOnInjectedQueueAfterOneSecondAndRechecksConfiguration() throws {
        let fixture = MPUploadCoordinatorFixture()
        fixture.kitsDelayed = true
        fixture.webDelayed = true
        fixture.setMessages([fixture.message(id: 1)])
        var completed = false
        fixture.coordinator.waitForKitsAndUpload { completed = true }
        XCTAssertFalse(completed)
        XCTAssertEqual(fixture.webChecks, 0)
        XCTAssertEqual(fixture.delays, [1])
        XCTAssertTrue(fixture.persistence.transactions.isEmpty)
        fixture.kitsDelayed = false
        try XCTUnwrap(fixture.scheduled.first)()
        XCTAssertFalse(completed)
        XCTAssertEqual(fixture.webChecks, 1)
        XCTAssertEqual(fixture.delays, [1, 1])
        fixture.webDelayed = false
        try XCTUnwrap(fixture.scheduled.last)()
        XCTAssertTrue(completed)
        XCTAssertEqual(fixture.network.configRequests, 3)
        XCTAssertEqual(fixture.network.uploaded.count, 1)
        XCTAssertEqual(fixture.persistence.transactions.count, 1)
    }

    func testSkipIsProcessWideAndConsumedAfterPreparingMessages() {
        let first = MPUploadCoordinatorFixture()
        let second = MPUploadCoordinatorFixture()
        second.setMessages([second.message(id: 1)])
        first.coordinator.skipNextUpload()
        var completions = 0
        second.coordinator.uploadBatches { success in
            XCTAssertTrue(success)
            completions += 1
        }
        XCTAssertEqual(second.persistence.uploads.count, 1)
        XCTAssertTrue(second.network.uploaded.isEmpty)
        second.coordinator.uploadBatches { _ in completions += 1 }
        XCTAssertEqual(second.network.uploaded.count, 1)
        XCTAssertEqual(second.persistence.transactions.count, 1)
        XCTAssertEqual(completions, 2)
    }

    func testRejectedConfigurationDoesNotConsumeSkipFlag() {
        let fixture = MPUploadCoordinatorFixture()
        fixture.coordinator.skipNextUpload()
        fixture.network.configSuccess = false
        fixture.coordinator.waitForKitsAndUpload(completionHandler: nil)
        fixture.network.configSuccess = true
        fixture.setMessages([fixture.message(id: 1)])
        fixture.coordinator.waitForKitsAndUpload(completionHandler: nil)
        XCTAssertTrue(fixture.network.uploaded.isEmpty)
        fixture.coordinator.waitForKitsAndUpload(completionHandler: nil)
        XCTAssertEqual(fixture.network.uploaded.count, 1)
    }

    func testEmptyQueueCompletesWithoutNetworkSubmission() {
        let fixture = MPUploadCoordinatorFixture()
        var completed = false
        fixture.coordinator.waitForKitsAndUpload { completed = true }
        XCTAssertTrue(completed)
        XCTAssertEqual(fixture.persistence.cleanupCount, 1)
        XCTAssertTrue(fixture.network.uploaded.isEmpty)
    }

    func testRampedDataDeletesUploadsAndPerformanceMessagesWithoutCompletion() {
        let fixture = MPUploadCoordinatorFixture()
        fixture.builder.state.dataRamped = true
        fixture.setMessages([fixture.message(id: 1)])
        var completed = false
        fixture.coordinator.waitForKitsAndUpload { completed = true }
        XCTAssertFalse(completed)
        XCTAssertEqual(fixture.persistence.deletedUploads.count, 1)
        XCTAssertEqual(fixture.persistence.networkPerformanceDeletes, 1)
        XCTAssertTrue(fixture.network.uploaded.isEmpty)
        XCTAssertTrue(fixture.scheduled.isEmpty)
    }

    func testNetworkCompletionControlsPublicCompletionOrdering() {
        let fixture = MPUploadCoordinatorFixture()
        fixture.network.deferUploadCompletion = true
        fixture.setMessages([fixture.message(id: 1)])
        var completed = false
        fixture.coordinator.waitForKitsAndUpload { completed = true }
        XCTAssertFalse(completed)
        XCTAssertEqual(fixture.persistence.transactions.count, 1)
        XCTAssertEqual(fixture.network.uploaded.count, 1)
        fixture.network.uploadCompletion?()
        XCTAssertTrue(completed)
    }

    func testRetryResolvesCurrentNetworkPersistenceAndSettings() throws {
        let fixture = MPUploadCoordinatorFixture()
        let firstNetwork = fixture.network
        let firstPersistence = fixture.persistence
        fixture.kitsDelayed = true
        fixture.coordinator.waitForKitsAndUpload(completionHandler: nil)
        fixture.network = MPBackendUploadNetworkMock()
        fixture.persistence = MPUploadPersistenceMock()
        fixture.settings = NSObject()
        fixture.setMessages([fixture.message(id: 1)])
        fixture.kitsDelayed = false
        try XCTUnwrap(fixture.scheduled.first)()
        XCTAssertEqual(firstNetwork.configRequests, 1)
        XCTAssertTrue(firstNetwork.uploaded.isEmpty)
        XCTAssertTrue(firstPersistence.transactions.isEmpty)
        XCTAssertEqual(fixture.network.configRequests, 1)
        XCTAssertEqual(fixture.network.uploaded.count, 1)
        XCTAssertTrue(fixture.persistence.uploads.first?.uploadSettings === fixture.settings)
    }
}
