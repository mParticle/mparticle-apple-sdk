import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPConsentKitFilterTests: XCTestCase {
    func testFilterItemDefaults() {
        let item = MPConsentKitFilterItem()
        XCTAssertFalse(item.consented)
        XCTAssertEqual(item.javascriptHash, 0)
    }

    func testFilterItemProperties() {
        let item = MPConsentKitFilterItem()
        item.consented = true
        item.javascriptHash = 42
        XCTAssertTrue(item.consented)
        XCTAssertEqual(item.javascriptHash, 42)
    }

    func testFilterDefaults() {
        let filter = MPConsentKitFilter()
        XCTAssertFalse(filter.shouldIncludeOnMatch)
        XCTAssertNil(filter.filterItems)
    }

    func testFilterProperties() {
        let filter = MPConsentKitFilter()

        filter.shouldIncludeOnMatch = true
        XCTAssertTrue(filter.shouldIncludeOnMatch)

        filter.shouldIncludeOnMatch = false
        XCTAssertFalse(filter.shouldIncludeOnMatch)

        let item = MPConsentKitFilterItem()
        filter.filterItems = [item]

        let items = filter.filterItems
        XCTAssertEqual(items?.count, 1)
        XCTAssertEqual(items?.first, item)
        XCTAssertFalse(items?.first?.consented ?? true)
    }
}
