import XCTest
@testable import mParticle_Apple_SDK_Swift

final class SceneDelegateLogicTests: XCTestCase {
    // MARK: - openURLOptions

    func testSourceApplicationIsMappedToTheUIKitKey() {
        let options = SceneDelegateLogic.openURLOptions(sourceApplication: "com.example.host")

        XCTAssertEqual(options.count, 1)
        XCTAssertEqual(options["UIApplicationOpenURLOptionsSourceApplicationKey"] as? String, "com.example.host")
    }

    /// The ObjC version handed over an empty NSMutableDictionary rather than nil when
    /// there was no source application, and openURL:options: relies on that.
    func testMissingSourceApplicationYieldsAnEmptyDictionary() {
        XCTAssertTrue(SceneDelegateLogic.openURLOptions(sourceApplication: nil).isEmpty)
    }

    func testTheKeyMatchesUIKitsSpelling() {
        XCTAssertEqual(SceneDelegateLogic.sourceApplicationKey,
                       "UIApplicationOpenURLOptionsSourceApplicationKey")
    }

    // MARK: - isBrowsingWebActivity

    func testBrowsingWebIsRecognised() {
        XCTAssertTrue(SceneDelegateLogic.isBrowsingWebActivity(activityType: NSUserActivityTypeBrowsingWeb))
        XCTAssertFalse(SceneDelegateLogic.isBrowsingWebActivity(activityType: "com.example.activity"))
        XCTAssertFalse(SceneDelegateLogic.isBrowsingWebActivity(activityType: nil))
    }

    // MARK: - URL context log lines

    func testURLContextLinesInOrder() {
        let lines = SceneDelegateLogic.urlContextLogLines(url: "https://example.com/a",
                                                          sourceApplication: "com.example.host",
                                                          annotation: "note",
                                                          eventAttribution: nil,
                                                          openInPlace: false)

        XCTAssertEqual(lines, [
            "Opening URLContext URL: https://example.com/a",
            "Source: com.example.host",
            "Annotation: note",
            "Open in place: False"
        ])
    }

    func testMissingSourceApplicationLogsUnknown() {
        let lines = SceneDelegateLogic.urlContextLogLines(url: "https://example.com",
                                                          sourceApplication: nil,
                                                          annotation: nil,
                                                          eventAttribution: nil,
                                                          openInPlace: true)

        XCTAssertEqual(lines[1], "Source: unknown")
        XCTAssertEqual(lines.last, "Open in place: True")
    }

    /// Event attribution is gated on iOS 14.5 at the call site, so the line is absent
    /// rather than empty on older systems.
    func testEventAttributionLineOnlyAppearsWhenResolved() {
        let without = SceneDelegateLogic.urlContextLogLines(url: "u", sourceApplication: nil,
                                                            annotation: nil, eventAttribution: nil,
                                                            openInPlace: false)
        XCTAssertFalse(without.contains { $0.hasPrefix("Event Attribution:") })

        let with = SceneDelegateLogic.urlContextLogLines(url: "u", sourceApplication: nil,
                                                         annotation: nil, eventAttribution: "attr",
                                                         openInPlace: false)
        XCTAssertEqual(with[3], "Event Attribution: attr")
        XCTAssertEqual(with.last, "Open in place: False")
    }

    // MARK: - User activity log lines

    func testUserActivityLinesForANonWebActivity() {
        let lines = SceneDelegateLogic.userActivityLogLines(activityType: "com.example.activity",
                                                            title: "Test Activity",
                                                            userInfoDescription: "{\n    key = value;\n}",
                                                            webpageURL: nil)

        XCTAssertEqual(lines.count, 4)
        XCTAssertEqual(lines[0], "User Activity Received")
        XCTAssertEqual(lines[1], "User Activity Type: com.example.activity")
        XCTAssertEqual(lines[2], "User Activity Title: Test Activity")
    }

    func testBrowsingWebActivityAddsTheURLLine() {
        let lines = SceneDelegateLogic.userActivityLogLines(activityType: NSUserActivityTypeBrowsingWeb,
                                                            title: nil,
                                                            userInfoDescription: nil,
                                                            webpageURL: "https://example.com/page")

        XCTAssertEqual(lines.count, 5)
        XCTAssertEqual(lines.last, "Opening UserActivity URL: https://example.com/page")
    }

    /// The ObjC original used `?: @""` for a nil title and webpage URL, so both log as
    /// an empty value rather than "(null)".
    func testNilTitleAndURLLogAsEmpty() {
        let lines = SceneDelegateLogic.userActivityLogLines(activityType: NSUserActivityTypeBrowsingWeb,
                                                            title: nil,
                                                            userInfoDescription: nil,
                                                            webpageURL: nil)

        XCTAssertEqual(lines[2], "User Activity Title: ")
        XCTAssertEqual(lines.last, "Opening UserActivity URL: ")
    }
}
