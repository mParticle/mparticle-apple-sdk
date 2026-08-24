import Foundation

/// Value derivation for custom module preferences. Mirrors MPDataType from MPIConstants.h,
/// which cannot be imported here, so the boundary passes the raw integer.
private enum CustomModuleDataType: Int {
    case string = 1
    case int = 2
    case bool = 3
    case float = 4
    case long = 5
}

@objc(MPCustomModulePreferenceLogic) public final class CustomModulePreferenceLogic: NSObject {
    private static let macroPlaceholders = ["%gn%", "%oaid%", "%dt%", "%glsb%", "%g%"]

    /// Takes Any so that an NSNull coming straight out of parsed config is handled here
    /// rather than needing a guard at every call site.
    @objc(isMacroPlaceholder:) public static func isMacroPlaceholder(_ candidate: Any?) -> Bool {
        guard let candidate = candidate as? String else {
            return false
        }
        return macroPlaceholders.contains(candidate)
    }

    @objc(defaultValueForMacroPlaceholder:) public static func defaultValue(forMacroPlaceholder placeholder: String) -> String {
        return defaultValue(forMacroPlaceholder: placeholder, uuid: { UUID() }, date: { Date() })
    }

    public static func defaultValue(forMacroPlaceholder placeholder: String,
                                    uuid: () -> UUID,
                                    date: () -> Date) -> String {
        switch placeholder {
        case "%gn%":
            return undashedUUID(uuid())
        case "%oaid%":
            return advertisingIdentifier(from: undashedUUID(uuid()))
        case "%dt%":
            return macroDateFormatter.string(from: date())
        case "%glsb%":
            return leastSignificantBits(of: uuid())
        case "%g%":
            return uuid().uuidString
        default:
            return ""
        }
    }

    @objc(defaultValueForDataType:) public static func defaultValue(forDataType rawDataType: Int) -> String? {
        switch CustomModuleDataType(rawValue: rawDataType) {
        case .string:
            return ""
        case .int, .long:
            return "0"
        case .bool:
            return "false"
        case .float:
            return "0.0"
        case .none:
            return nil
        }
    }

    /// Coerces an already-resolved default string into the typed value the preference vends.
    /// Uses NSString's parsing so that inputs the strict Swift initializers would reject,
    /// such as trailing characters, keep behaving as they do today.
    @objc(valueForDefaultValue:dataType:) public static func value(forDefaultValue defaultValue: String,
                                                                   dataType rawDataType: Int) -> Any? {
        switch CustomModuleDataType(rawValue: rawDataType) {
        case .string:
            return defaultValue
        case .int, .long:
            return NSNumber(value: (defaultValue as NSString).integerValue)
        case .bool:
            let isFalse = defaultValue == "false" || defaultValue == "NO" || defaultValue == "0"
            return NSNumber(value: !isFalse)
        case .float:
            return NSNumber(value: (defaultValue as NSString).floatValue)
        case .none:
            return nil
        }
    }

    // MARK: - Macro helpers

    private static let macroDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss Z"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    public static func undashedUUID(_ uuid: UUID) -> String {
        return uuid.uuidString.replacingOccurrences(of: "-", with: "")
    }

    /// Clamps the first character below ASCII '8' and the seventeenth below ASCII '4', then
    /// splits the 32 characters into two 16 character halves. Note the comparison is on the
    /// ASCII value, so hex letters count as above the threshold and get replaced.
    public static func advertisingIdentifier(from undashed: String,
                                             randomBelow: (UInt32) -> UInt32 = { arc4random_uniform($0) }) -> String {
        var characters = Array(undashed.utf8)
        guard characters.count >= 32 else {
            return undashed
        }

        let zero = UInt8(ascii: "0")
        if characters[0] >= UInt8(ascii: "8") {
            characters[0] = zero + UInt8(randomBelow(8))
        }
        if characters[16] >= UInt8(ascii: "4") {
            characters[16] = zero + UInt8(randomBelow(4))
        }

        let first = String(decoding: characters[0..<16], as: UTF8.self)
        let second = String(decoding: characters[16..<32], as: UTF8.self)
        return "\(first)-\(second)"
    }

    /// Assembles bytes 8 through 15 of the UUID big-endian into a signed 64 bit value.
    public static func leastSignificantBits(of uuid: UUID) -> String {
        let bytes = uuid.uuid
        let lower: [UInt8] = [bytes.8, bytes.9, bytes.10, bytes.11, bytes.12, bytes.13, bytes.14, bytes.15]

        var value: UInt64 = 0
        for byte in lower {
            value = (value << 8) | UInt64(byte)
        }

        return String(Int64(bitPattern: value))
    }
}
