import Foundation

@objc public final class MPDataPlanQuery: NSObject {
    @objc public let query: String?
    @objc public let rejectedVersion: NSNumber?

    private static let minimumVersion = 1
    private static let maximumVersion = 1000

    private init(query: String?, rejectedVersion: NSNumber?) {
        self.query = query
        self.rejectedVersion = rejectedVersion
        super.init()
    }

    @objc(queryWithPlanId:planVersion:)
    public static func query(planId: String?, planVersion: NSNumber?) -> MPDataPlanQuery {
        guard let planId else {
            return MPDataPlanQuery(query: nil, rejectedVersion: nil)
        }

        guard let planVersion else {
            return MPDataPlanQuery(query: "&plan_id=\(planId)", rejectedVersion: nil)
        }

        let version = planVersion.int32Value
        guard version >= minimumVersion, version <= maximumVersion else {
            return MPDataPlanQuery(query: "&plan_id=\(planId)", rejectedVersion: planVersion)
        }

        return MPDataPlanQuery(query: "&plan_id=\(planId)&plan_version=\(planVersion)", rejectedVersion: nil)
    }
}
