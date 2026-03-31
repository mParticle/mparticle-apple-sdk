//
//  AppsFlyerLibMock.swift
//  mParticle-AppsFlyer
//
//  Created by Nick Dimitrakas on 9/16/25.
//

import AppsFlyerLib

class AppsFlyerLibMock: AppsFlyerLib {
    var logEventCalled = false
    var logEventEventName: String?
    var logEventValues: [AnyHashable: Any]?
    var startCallCount = 0

    override func start() {
        startCallCount += 1
    }

    override func logEvent(_ eventName: String, withValues values: [AnyHashable: Any]?) {
        logEventCalled = true
        logEventEventName = eventName
        logEventValues = values
    }
}
