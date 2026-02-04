import Foundation

class MPUserDefaultsConnectorMock: MPUserDefaultsConnectorProtocol {
    var logger = MPLog(logLevel: .warning)

    var deferredKitConfiguration: [[AnyHashable: Any]]?

    func configureKits(_ kitConfigurations: [[AnyHashable: Any]]?) {
    }

    var configureCustomModulesCustomModuleSettingsPrarams: [[AnyHashable: Any]]?
    func configureCustomModules(_ customModuleSettings: [[AnyHashable: Any]]?) {
        configureCustomModulesCustomModuleSettingsPrarams = customModuleSettings
    }

    func configureRampPercentage(_ rampPercentage: NSNumber?) {
    }

    func configureTriggers(_ triggerDictionary: [AnyHashable: Any]?) {
    }

    func configureAliasMaxWindow(_ aliasMaxWindow: NSNumber?) {
    }

    func configureDataBlocking(_ blockSettings: [AnyHashable: Any]?) {
    }

    func userId() -> NSNumber? {
        return 1
    }

    func setAllowASR(_ allowASR: Bool) {
    }

    func setEnableAudienceAPI(_ enableAudienceAPI: Bool) {
    }

    func setExceptionHandlingMode(_ exceptionHandlingMode: String?) {
    }

    func setSessionTimeout(_ sessionTimeout: TimeInterval) {
    }

    func setPushNotificationMode(_ pushNotificationMode: String) {
    }

    func setCrashMaxPLReportLength(_ crashMaxPLReportLength: NSNumber) {
    }

    func isAppExtension() -> Bool {
        return false
    }

    func registerForRemoteNotifications() {
    }

    func unregisterForRemoteNotifications() {
    }

    var canCreateConfigurationReturnValue = false

    func canCreateConfiguration() -> Bool {
        return canCreateConfigurationReturnValue
    }

    func mpId() -> NSNumber {
        1
    }

    var configMaxAgeSecondsReturnValue: NSNumber?

    func configMaxAgeSeconds() -> NSNumber? {
        configMaxAgeSecondsReturnValue
    }
}
