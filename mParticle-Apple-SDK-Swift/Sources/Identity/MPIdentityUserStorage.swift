import Foundation

@objc public final class MPIdentityUserStoragePRIVATE: NSObject {
    @objc public static func date(fromMilliseconds milliseconds: Any?) -> Date {
        let value = (milliseconds as AnyObject?)?.doubleValue ?? 0
        return Date(timeIntervalSince1970: value/1000.0)
    }

    @objc public static func shouldSkipEmptyAttributeValue(_ value: Any?) -> Bool {
        guard let string = value as? NSString else { return false }
        return string.length <= 0
    }

    @objc public static func applyingIdentity(
        _ identityString: Any?,
        type identityType: Int,
        toStoredArray storedArray: NSArray?
    ) -> NSArray {
        let identities = NSMutableArray(array: storedArray ?? [])
        let identityTypeNumber = NSNumber(value: identityType)
        let existingIndex = identities.indexOfObject(passingTest: { object, _, stop in
            guard let dictionary = object as? NSDictionary,
                  let currentType = dictionary[MessageKeys.kMPUserIdentityTypeKey] as? NSNumber,
                  currentType.isEqual(to: identityTypeNumber)
            else { return false }
            stop.pointee = true
            return true
        })

        let shouldRemove = identityString == nil
            || identityString is NSNull
            || (identityString as? String)?.isEmpty == true

        if shouldRemove {
            if existingIndex != NSNotFound {
                identities.removeObject(at: existingIndex)
            }
            return identities
        }

        let newIdentityDictionary = NSMutableDictionary(capacity: 4)
        newIdentityDictionary[MessageKeys.kMPUserIdentityTypeKey] = identityTypeNumber
        newIdentityDictionary[MessageKeys.kMPUserIdentityIdKey] = identityString

        if existingIndex == NSNotFound {
            identities.add(newIdentityDictionary)
        } else {
            identities.replaceObject(at: existingIndex, with: newIdentityDictionary)
        }
        return identities
    }

    @objc public static func isUserIdentity(_ identityType: Int) -> Bool {
        identityType <= MPIdentitySwift.phoneNumber3.rawValue
    }

    @objc public static func audienceDisabledError() -> NSError {
        NSError(
            domain: "mParticle Audience",
            code: 202,
            userInfo: ["message": "Your workspace is not enabled to retrieve user audiences."]
        )
    }
}
