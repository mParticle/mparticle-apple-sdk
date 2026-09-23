import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPDeviceTokenStoreTests: XCTestCase {
    private var store: DeviceTokenStore!

    private let newTokenKey = Notifications.kMPRemoteNotificationDeviceTokenKey.rawValue
    private let oldTokenKey = Notifications.kMPRemoteNotificationOldDeviceTokenKey.rawValue

    private let tokenA = Data([0x01, 0x02, 0x03])
    private let tokenB = Data([0x0a, 0xff])

    override func setUp() {
        super.setUp()
        store = DeviceTokenStore()
    }

    // MARK: - currentToken / adopt

    func testCurrentTokenStartsNil() {
        XCTAssertNil(store.currentToken())
    }

    func testAdoptStoresAndReturnsPersistedToken() {
        XCTAssertEqual(store.adopt(persistedToken: tokenA), tokenA)
        XCTAssertEqual(store.currentToken(), tokenA)
    }

    func testAdoptClearsTheTokenWhenNothingIsPersisted() {
        _ = store.adopt(persistedToken: tokenA)

        XCTAssertNil(store.adopt(persistedToken: nil))
        XCTAssertNil(store.currentToken())
    }

    // MARK: - change de-duplication

    func testChangeToTheSameTokenIsANoOp() {
        _ = store.change(to: tokenA)

        XCTAssertNil(store.change(to: tokenA))
        XCTAssertEqual(store.currentToken(), tokenA)
    }

    func testChangeToADifferentTokenReportsBothSides() {
        _ = store.change(to: tokenA)

        let change = store.change(to: tokenB)

        XCTAssertNotNil(change)
        XCTAssertEqual(change?.userInfo[newTokenKey] as? Data, tokenB)
        XCTAssertEqual(change?.userInfo[oldTokenKey] as? Data, tokenA)
        XCTAssertEqual(store.currentToken(), tokenB)
    }

    /// The ObjC original messaged a nil receiver in its equality guard, so a nil-to-nil
    /// transition fell through rather than short-circuiting and still posted. The payload is
    /// empty, which MPBackendController's observer discards, but the post itself is preserved.
    func testChangeFromNilToNilStillProducesAChange() {
        let change = store.change(to: nil)

        XCTAssertNotNil(change)
        XCTAssertTrue(change?.userInfo.isEmpty ?? false)
        XCTAssertNil(store.currentToken())
    }

    func testChangeFromATokenToNilReportsOnlyTheOldSide() {
        _ = store.change(to: tokenA)

        let change = store.change(to: nil)

        XCTAssertNotNil(change)
        XCTAssertNil(change?.userInfo[newTokenKey])
        XCTAssertEqual(change?.userInfo[oldTokenKey] as? Data, tokenA)
        XCTAssertNil(store.currentToken())
    }

    func testFirstChangeReportsOnlyTheNewSide() {
        let change = store.change(to: tokenA)

        XCTAssertEqual(change?.userInfo[newTokenKey] as? Data, tokenA)
        XCTAssertNil(change?.userInfo[oldTokenKey])
    }

    // MARK: - shouldModifyDeviceID

    func testShouldModifyDeviceIDOnlyWhenBothSidesResolve() {
        _ = store.change(to: tokenA)
        XCTAssertTrue(store.change(to: tokenB)?.shouldModifyDeviceID ?? false)
    }

    func testShouldNotModifyDeviceIDOnTheFirstToken() {
        XCTAssertFalse(store.change(to: tokenA)?.shouldModifyDeviceID ?? true)
    }

    func testShouldNotModifyDeviceIDWhenTheTokenIsCleared() {
        _ = store.change(to: tokenA)
        XCTAssertFalse(store.change(to: nil)?.shouldModifyDeviceID ?? true)
    }

    /// `stringFromDeviceToken` returns nil for empty data, so an empty token is carried in
    /// the payload but never reported as a device-ID change.
    func testEmptyTokenIsPostedButNotReportedAsADeviceIDChange() {
        _ = store.change(to: tokenA)

        let change = store.change(to: Data())

        XCTAssertEqual(change?.userInfo[newTokenKey] as? Data, Data())
        XCTAssertNil(change?.newTokenString)
        XCTAssertFalse(change?.shouldModifyDeviceID ?? true)
    }

    // MARK: - token strings

    func testTokenStringsAreLowercaseHex() {
        _ = store.change(to: tokenA)

        let change = store.change(to: tokenB)

        XCTAssertEqual(change?.newTokenString, "0aff")
        XCTAssertEqual(change?.oldTokenString, "010203")
    }

    // MARK: - post

    func testPostDeliversTheChangePayloadUnderTheExpectedName() {
        _ = store.change(to: tokenA)
        guard let change = store.change(to: tokenB) else {
            return XCTFail("expected a change")
        }

        let expectation = expectation(forNotification: Notifications.kMPRemoteNotificationDeviceTokenNotification,
                                      object: nil) { notification in
            XCTAssertEqual(notification.userInfo?[self.newTokenKey] as? Data, self.tokenB)
            XCTAssertEqual(notification.userInfo?[self.oldTokenKey] as? Data, self.tokenA)
            return true
        }

        store.post(change)

        wait(for: [expectation], timeout: 1.0)
    }
}
