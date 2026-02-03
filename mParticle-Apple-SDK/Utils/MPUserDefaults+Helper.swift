internal import mParticle_Apple_SDK_Swift

extension MPUserDefaults {
    @objc func setLastUploadSettings(_ lastUploadSettings: MPUploadSettings?) {
        if let lastUploadSettings = lastUploadSettings {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: lastUploadSettings, requiringSecureCoding: true)
                setLastUploadSettingsData(data)
            } catch {
                let mparticle = MParticle.sharedInstance()
                let logger = MPLog(logLevel: MPLog.from(rawValue: mparticle.logLevel.rawValue))
                logger.customLogger = mparticle.customLogger
                logger.error("Failed to archive upload settings: \(error)")
            }
        } else {
            removeLastUploadSettings()
        }
    }

    @objc func lastUploadSettings() -> MPUploadSettings? {
        if let data = mpObject(forKey: Miscellaneous.kMPLastUploadSettingsUserDefaultsKey, userId: 0) as? Data {
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: MPUploadSettings.self, from: data)
            } catch {
                let mparticle = MParticle.sharedInstance()
                let logger = MPLog(logLevel: MPLog.from(rawValue: mparticle.logLevel.rawValue))
                logger.customLogger = mparticle.customLogger
                logger.error("Failed to unarchive upload settings: \(error)")
            }
        }
        return nil
    }
}
