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
    var setCustomerUserIDCallCount = 0
    var lastCustomerUserID: String?

    override func start() {
        startCallCount += 1
    }

    override var customerUserID: String? {
        get { super.customerUserID }
        set {
            setCustomerUserIDCallCount += 1
            lastCustomerUserID = newValue
            super.customerUserID = newValue
        }
    }

    override func logEvent(_ eventName: String, withValues values: [AnyHashable: Any]?) {
        logEventCalled = true
        logEventEventName = eventName
        logEventValues = values
    }
}
