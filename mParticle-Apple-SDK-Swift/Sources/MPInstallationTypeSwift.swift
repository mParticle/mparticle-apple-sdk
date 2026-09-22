/// Mirrors the `MPInstallationType` NS_ENUM in `Include/MPEnums.h`, which this module cannot
/// import. The raw values must stay in step with it.
@objc public enum MPInstallationTypeSwift: Int {
    case autodetect = 0
    case knownInstall
    case knownUpgrade
    case knownSameVersion
}
