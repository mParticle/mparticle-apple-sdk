import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPDataPlanQueryTests: XCTestCase {
    func testNoQueryWithoutAPlanId() {
        let result = MPDataPlanQuery.query(planId: nil, planVersion: NSNumber(value: 3))

        XCTAssertNil(result.query)
        XCTAssertNil(result.rejectedVersion)
    }

    func testPlanIdAloneWhenNoVersionIsGiven() {
        let result = MPDataPlanQuery.query(planId: "my_plan", planVersion: nil)

        XCTAssertEqual(result.query, "&plan_id=my_plan")
        XCTAssertNil(result.rejectedVersion)
    }

    func testPlanIdAndVersion() {
        let result = MPDataPlanQuery.query(planId: "my_plan", planVersion: NSNumber(value: 7))

        XCTAssertEqual(result.query, "&plan_id=my_plan&plan_version=7")
        XCTAssertNil(result.rejectedVersion)
    }

    func testVersionBoundsAreInclusive() {
        XCTAssertEqual(
            MPDataPlanQuery.query(planId: "p", planVersion: NSNumber(value: 1)).query,
            "&plan_id=p&plan_version=1"
        )
        XCTAssertEqual(
            MPDataPlanQuery.query(planId: "p", planVersion: NSNumber(value: 1000)).query,
            "&plan_id=p&plan_version=1000"
        )
    }

    func testOutOfRangeVersionIsDroppedAndReported() {
        for version in [0, -1, 1001, 99999] {
            let result = MPDataPlanQuery.query(planId: "p", planVersion: NSNumber(value: version))

            XCTAssertEqual(result.query, "&plan_id=p", "version \(version)")
            XCTAssertEqual(result.rejectedVersion?.intValue, version, "version \(version)")
        }
    }

    func testVersionIsRangeCheckedAsAnInt32() {
        let result = MPDataPlanQuery.query(planId: "p", planVersion: NSNumber(value: 7.9))

        XCTAssertEqual(result.query, "&plan_id=p&plan_version=7.9")
        XCTAssertNil(result.rejectedVersion)
    }
}
