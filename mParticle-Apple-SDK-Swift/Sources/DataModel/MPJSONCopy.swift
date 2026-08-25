import Foundation

func MPSwiftIsNull(_ value: Any?) -> Bool {
    value == nil || value is NSNull
}

@objc public final class MPJSONCopyPRIVATE: NSObject {
    @objc(deepCopyJSONObject:)
    public static func deepCopyJSONObject(_ object: Any?) -> Any? {
        guard let object else { return nil }
        if object is NSNull { return object }
        if let string = object as? String { return string as NSString }
        if let number = object as? NSNumber { return number }

        if let dictionary = object as? NSDictionary {
            let snapshot = dictionary.copy() as? NSDictionary ?? dictionary
            let result = NSMutableDictionary(capacity: snapshot.count)
            snapshot.enumerateKeysAndObjects { key, value, _ in
                guard key is String, let copied = deepCopyJSONObject(value) else { return }
                result[key] = copied
            }
            return result.copy()
        }

        if let array = object as? NSArray {
            let snapshot = array.copy() as? NSArray ?? array
            let result = NSMutableArray(capacity: snapshot.count)
            for item in snapshot {
                if let copied = deepCopyJSONObject(item) {
                    result.add(copied)
                }
            }
            return result.copy()
        }

        return nil
    }
}
