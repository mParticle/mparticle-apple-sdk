import Foundation

@objc public final class MPIdentityAliasPlanPRIVATE: NSObject {
    @objc public let isValid: Bool
    @objc public let startTime: Date?
    @objc public let endTime: Date?
    @objc public let shouldWarnDateOrder: Bool

    @objc public init(isValid: Bool, startTime: Date?, endTime: Date?, shouldWarnDateOrder: Bool) {
        self.isValid = isValid
        self.startTime = startTime
        self.endTime = endTime
        self.shouldWarnDateOrder = shouldWarnDateOrder
        super.init()
    }

    @objc(planWithSourceMPID:destinationMPID:startTime:endTime:usedFirstLastSeen:aliasMaxWindow:)
    public static func plan(
        sourceMPID: NSNumber?,
        destinationMPID: NSNumber?,
        startTime: Date?,
        endTime: Date?,
        usedFirstLastSeen: Bool,
        aliasMaxWindow: NSNumber?
    ) -> MPIdentityAliasPlanPRIVATE {
        let source = sourceMPID?.int64Value ?? 0
        let destination = destinationMPID?.int64Value ?? 0
        if sourceMPID == nil || destinationMPID == nil || source == 0 || destination == 0 || sourceMPID == destinationMPID {
            return MPIdentityAliasPlanPRIVATE(isValid: false, startTime: startTime, endTime: endTime, shouldWarnDateOrder: false)
        }

        let maxDaysAgo = aliasMaxWindow?.doubleValue ?? 90
        let oldestAllowableDate = Date(timeIntervalSinceNow: -60 * 60 * 24 * maxDaysAgo)
        var adjustedStart = startTime
        var adjustedEnd = endTime

        if usedFirstLastSeen, let startTime, startTime.compare(oldestAllowableDate) == .orderedAscending {
            adjustedStart = oldestAllowableDate
        }

        if adjustedStart == nil || adjustedEnd == nil {
            adjustedStart = oldestAllowableDate
            adjustedEnd = Date()
        }

        let shouldWarn: Bool
        if let adjustedStart, let adjustedEnd {
            shouldWarn = adjustedStart.compare(adjustedEnd) != .orderedAscending
        } else {
            shouldWarn = false
        }

        return MPIdentityAliasPlanPRIVATE(
            isValid: true,
            startTime: adjustedStart,
            endTime: adjustedEnd,
            shouldWarnDateOrder: shouldWarn
        )
    }
}

@objc public final class MPIdentityApiLogicPRIVATE: NSObject {
    @objc public static func sortedIndexes(byLastSeen dates: NSArray) -> [NSNumber] {
        dates.enumerated()
            .compactMap { index, element -> (offset: Int, element: Date)? in
                guard let date = element as? Date else { return nil }
                return (index, date)
            }
            .sorted { lhs, rhs in
                let comparison = lhs.element.compare(rhs.element)
                if comparison == .orderedSame {
                    return lhs.offset < rhs.offset
                }
                return comparison == .orderedDescending
            }
            .map { NSNumber(value: $0.offset) }
    }

    @objc public static func parsedModifyChanges(_ changeResults: NSArray?) -> NSArray {
        let changes = NSMutableArray()
        changeResults?.enumerateObjects { object, _, _ in
            guard let userChange = object as? NSDictionary,
                  userChange[IdentityHTTPKeys.modifiedMPID] != nil,
                  let identityString = userChange[IdentityHTTPKeys.identityType] as? String
            else { return }
            let identityNumber = MPIdentityHTTPIdentitiesPRIVATE.identityType(for: identityString)
            let record = NSMutableDictionary()
            record[IdentityHTTPKeys.modifiedMPID] = userChange[IdentityHTTPKeys.modifiedMPID]
            record[IdentityHTTPKeys.identityType] = identityString
            if let identityNumber {
                record["identity_type_number"] = identityNumber
            }
            changes.add(record)
        }
        return changes
    }

    @objc public static func errorFields(from dictionary: NSDictionary?, httpCode: Int) -> NSDictionary {
        let result = NSMutableDictionary()
        result["httpCode"] = NSNumber(value: httpCode)
        if let dictionary {
            result["code"] = dictionary[IdentityHTTPKeys.code]
            result["message"] = dictionary[IdentityHTTPKeys.message]
        } else {
            result["code"] = NSNumber(value: httpCode)
        }
        return result
    }
}
