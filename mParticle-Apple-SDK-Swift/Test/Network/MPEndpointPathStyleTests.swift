import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPEndpointPathStyleTests: XCTestCase {
    func testPlainRoutingUsesTheDefaultVersionSegment() {
        let style = style(usesCustomHost: false, overridesSubdirectory: false)

        XCTAssertFalse(style.usesOverrideFormat)
        XCTAssertEqual(style.versionSegment, "v2")
        XCTAssertFalse(style.warnsSubdirectoryOverrideIgnored)
    }

    func testCustomHostUsesTheCDNVersionSegment() {
        let style = style(usesCustomHost: true, overridesSubdirectory: false)

        XCTAssertFalse(style.usesOverrideFormat)
        XCTAssertEqual(style.versionSegment, "nativeevents/v2")
        XCTAssertFalse(style.warnsSubdirectoryOverrideIgnored)
    }

    func testSubdirectoryOverrideDropsTheVersionSegmentEntirely() {
        let style = style(usesCustomHost: false, overridesSubdirectory: true)

        XCTAssertTrue(style.usesOverrideFormat)
        XCTAssertFalse(style.warnsSubdirectoryOverrideIgnored)
    }

    func testCustomHostBeatsTheSubdirectoryOverrideAndWarns() {
        let style = style(usesCustomHost: true, overridesSubdirectory: true)

        XCTAssertFalse(style.usesOverrideFormat)
        XCTAssertEqual(style.versionSegment, "nativeevents/v2")
        XCTAssertTrue(style.warnsSubdirectoryOverrideIgnored)
    }

    func testWarningFiresOnlyWhenBothAreSet() {
        XCTAssertFalse(style(usesCustomHost: false, overridesSubdirectory: false).warnsSubdirectoryOverrideIgnored)
        XCTAssertFalse(style(usesCustomHost: true, overridesSubdirectory: false).warnsSubdirectoryOverrideIgnored)
        XCTAssertFalse(style(usesCustomHost: false, overridesSubdirectory: true).warnsSubdirectoryOverrideIgnored)
        XCTAssertTrue(style(usesCustomHost: true, overridesSubdirectory: true).warnsSubdirectoryOverrideIgnored)
    }

    private func style(usesCustomHost: Bool, overridesSubdirectory: Bool) -> MPEndpointPathStyle {
        MPEndpointPathStyle.style(
            defaultVersion: "v2",
            cdnVersion: "nativeevents/v2",
            usesCustomHost: usesCustomHost,
            overridesSubdirectory: overridesSubdirectory
        )
    }
}
