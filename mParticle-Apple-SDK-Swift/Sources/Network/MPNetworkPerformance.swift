import Foundation

/// Controls how much of a measured request URL is included in the network-performance message.
@objc public enum MPNetworkMeasurementMode: Int {
    case exclude = 0
    case preserveQuery
    case abridged
}

/// Captures one network request's timing and transfer measurements.
///
/// The Objective-C runtime name and selectors are retained because the Objective-C core creates
/// and forwards this model while its implementation now lives entirely in Swift.
@objc(MPNetworkPerformance)
public final class MPNetworkPerformance: NSObject, NSCopying {
    private enum Keys {
        static let url = "url"
        static let timeElapsed = "te"
        static let bytesIn = "bi"
        static let bytesOut = "bo"
        static let responseCode = "rc"
        static let httpMethod = "v"
        static let httpPostBody = "d"
    }

    private enum Constants {
        static let defaultHTTPMethod = "GET"
        static let googleAnalyticsSecureURL = "https://ssl.google-analytics.com/collect"
        static let googleAnalyticsPlainURL = "http://www.google-analytics.com/collect"
    }

    private var urlRequest: URLRequest?
    private var cachedPostBody: String?
    private var storedStartTime: TimeInterval = 0
    private var storedEndTime: TimeInterval = 0
    private var storedElapsedTime: TimeInterval = 0

    @objc dynamic public var urlString: String?
    @objc dynamic public var httpMethod: String?
    @objc dynamic public var bytesIn: UInt = 0
    @objc dynamic public var bytesOut: UInt = 0
    @objc dynamic public var responseCode: Int = 0
    @objc dynamic public private(set) var networkMeasurementMode: MPNetworkMeasurementMode = .exclude

    @objc dynamic public var startTime: TimeInterval {
        get { storedStartTime }
        set {
            storedStartTime = newValue
            if storedEndTime != 0 {
                storedElapsedTime = (storedEndTime - storedStartTime).rounded(.towardZero)
            }
        }
    }

    @objc dynamic public var endTime: TimeInterval {
        get { storedEndTime }
        set {
            storedEndTime = newValue
            if storedStartTime != 0 {
                storedElapsedTime = (storedEndTime - storedStartTime).rounded(.towardZero)
            }
        }
    }

    @objc dynamic public var elapsedTime: TimeInterval {
        get { storedElapsedTime }
        set {
            storedElapsedTime = newValue
            if storedStartTime != 0 {
                storedEndTime = storedStartTime + storedElapsedTime
            }
        }
    }

    @objc(POSTBody)
    public var postBody: String? {
        if let cachedPostBody {
            return cachedPostBody
        }

        guard let request = urlRequest,
              let absoluteString = request.url?.absoluteString,
              absoluteString == Constants.googleAnalyticsSecureURL
                || absoluteString == Constants.googleAnalyticsPlainURL,
              request.httpBody != nil,
              request.httpMethod == "POST"
        else {
            return nil
        }

        cachedPostBody = request.httpBody.flatMap { String(data: $0, encoding: .utf8) }
        return cachedPostBody
    }

    override public init() {
        super.init()
    }

    @objc(initWithURLRequest:networkMeasurementMode:)
    public init(urlRequest: URLRequest, networkMeasurementMode: MPNetworkMeasurementMode) {
        self.networkMeasurementMode = networkMeasurementMode
        self.urlRequest = urlRequest

        switch networkMeasurementMode {
        case .abridged:
            if let url = urlRequest.url {
                urlString = "\(url.scheme ?? "(null)")://\(url.host ?? "(null)")\(url.relativePath)"
            }
        case .preserveQuery:
            urlString = urlRequest.url?.absoluteString
        case .exclude:
            urlString = nil
        @unknown default:
            urlString = nil
        }

        httpMethod = urlRequest.httpMethod ?? Constants.defaultHTTPMethod
        super.init()
    }

    @objc(setStartDate:)
    public func setStartDate(_ date: Date) {
        startTime = date.timeIntervalSince1970 * 1_000
    }

    @objc(setEndDate:)
    public func setEndDate(_ date: Date) {
        endTime = date.timeIntervalSince1970 * 1_000
    }

    @objc public func dictionaryRepresentation() -> NSDictionary {
        let dictionary = NSMutableDictionary()
        if let httpMethod {
            dictionary[Keys.httpMethod] = httpMethod
        }
        dictionary[Keys.timeElapsed] = elapsedTime
        dictionary[Keys.bytesIn] = bytesIn
        dictionary[Keys.bytesOut] = bytesOut
        dictionary[Keys.responseCode] = responseCode == 0 ? 200 : responseCode

        if let urlString {
            dictionary[Keys.url] = urlString
        }
        if let postBody {
            dictionary[Keys.httpPostBody] = postBody
        }
        return dictionary.copy() as? NSDictionary ?? dictionary
    }

    override public var description: String {
        let requestURL = urlRequest?.url?.absoluteString ?? "(null)"
        return String(
            format: "Network Performance \nURL: %@ \nHTTP Method: %@ \nStart Time: %.2f "
                + "\nEnd Time: %.2f \nElapsedTime: %.2f \nBytes In: %ld \nBytes Out: %ld "
                + "\nResponseCode: %ld\n\n",
            requestURL,
            httpMethod ?? "(null)",
            startTime,
            endTime,
            elapsedTime,
            Int(bytesIn),
            Int(bytesOut),
            responseCode
        )
    }

    @objc public func copy(with _: NSZone? = nil) -> Any {
        let copy = MPNetworkPerformance()
        copy.urlString = urlString.map { String($0) }
        copy.httpMethod = httpMethod.map { String($0) }
        copy.startTime = startTime
        copy.endTime = endTime
        copy.elapsedTime = elapsedTime
        copy.bytesIn = bytesIn
        copy.bytesOut = bytesOut
        copy.responseCode = responseCode
        copy.networkMeasurementMode = networkMeasurementMode
        copy.urlRequest = urlRequest
        return copy
    }
}
