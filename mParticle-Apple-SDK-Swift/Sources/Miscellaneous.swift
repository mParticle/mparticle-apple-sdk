import Foundation

@objcMembers
public class Miscellaneous: NSObject {
    public static let kMPFirstSeenUser = "fsu"
    public static let kMPLastSeenUser = "lsu"
    public static let kMPAppInitialLaunchTimeKey = "ict"
    public static let kMPHTTPETagHeaderKey = "ETag"
    public static let kMPConfigProvisionedTimestampKey = "ConfigProvisionedTimestamp"
    public static let kMPConfigMaxAgeHeaderKey = "ConfigMaxAgeHeader"
    public static let kMPConfigParameters = "ConfigParameters"
    public static let kMPLastIdentifiedDate = "last_date_used"
    public static let MPSideloadedKitsCountUserDefaultsKey = "MPSideloadedKitsCountUserDefaultsKey"
    public static let kMPLastUploadSettingsUserDefaultsKey = "lastUploadSettings"
    public static let CONFIG_REQUESTS_DEFAULT_EXPIRATION_AGE = 5.0 * 60
    public static let CONFIG_REQUESTS_MAX_EXPIRATION_AGE = 60 * 60 * 24.0
    public static let kMPDeviceTokenTypeKey = "tot"
    public static let kMPATT = "atts"
    public static let kMPATTTimestamp = "attt"
    public static let kMPDeviceCydiaJailbrokenKey = "cydia"
}
