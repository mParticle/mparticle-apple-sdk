@testable import mParticle_Apple_SDK_Swift
import XCTest

private final class KitDispatchTargetStub: NSObject, MPKitDispatchTarget {
    var attStatus: UInt?
    var ltvAmount: Double?
    var optOut: Bool?
    var sessionId: String?
    var wrapperSDK: UInt?

    @objc func logLTVIncrease(_ increaseAmount: Double, event: Any) -> AnyObject? {
        ltvAmount = increaseAmount
        return NSObject()
    }

    @objc func setOptOut(_ optOut: Bool) -> AnyObject? {
        self.optOut = optOut
        return NSObject()
    }

    @objc func setATTStatus(_ status: UInt,
                            withATTStatusTimestampMillis _: NSNumber?) -> AnyObject? {
        attStatus = status
        return NSObject()
    }

    @objc func setWrapperSdk(_ wrapperSdk: UInt, version _: String) -> AnyObject? {
        wrapperSDK = wrapperSdk
        return NSObject()
    }

    @objc func setSessionId(_ sessionId: String) -> AnyObject? {
        self.sessionId = sessionId
        return NSObject()
    }

    @objc func continueUserActivity(_: NSUserActivity,
                                    restorationHandler: @escaping ([Any]?) -> Void) -> AnyObject? {
        restorationHandler(["restored"])
        return NSObject()
    }

    @objc func selectPlacements(withIdentifier _: String?,
                                attributes _: [String: String],
                                embeddedViews _: [String: AnyObject]?,
                                config _: AnyObject?,
                                onEvent: ((AnyObject) -> Void)?,
                                filteredUser _: AnyObject,
                                options _: AnyObject?) -> AnyObject? {
        onEvent?(NSObject())
        return NSObject()
    }

    @objc func selectShoppableAds(withIdentifier _: String,
                                  attributes _: [String: String],
                                  config _: AnyObject?,
                                  onEvent: ((AnyObject) -> Void)?,
                                  filteredUser _: AnyObject) -> AnyObject? {
        onEvent?(NSObject())
        return NSObject()
    }

    @objc func events(_: String, onEvent: ((AnyObject) -> Void)?) -> AnyObject? {
        onEvent?(NSObject())
        return NSObject()
    }

    @objc func globalEvents(_ onEvent: @escaping (AnyObject) -> Void) -> AnyObject? {
        onEvent(NSObject())
        return NSObject()
    }
}

private final class EmptyKitDispatchTarget: NSObject, MPKitDispatchTarget {}

final class MPKitSelectorInvokerTests: XCTestCase {
    private typealias RestorationBlock = @convention(block) (NSArray?) -> Void
    private typealias RoktEventBlock = @convention(block) (AnyObject) -> Void

    private let invoker = MPKitSelectorInvoker(logger: MPLog(logLevel: .none))

    func testScalarArgumentsAreUnboxed() {
        let kit = KitDispatchTargetStub()
        let event = NSObject()

        let wrapperParameters = MPForwardQueueParameters(parameters: [NSNumber(value: 4), "2.4.1"])
        XCTAssertEqual(invoke(kit, "setWrapperSdk:version:", parameters: wrapperParameters).outcome,
                       .returnedStatus)
        XCTAssertEqual(kit.wrapperSDK, 4)

        let ltvParameters = MPForwardQueueParameters(parameters: [NSNumber(value: 12.5)])
        XCTAssertEqual(invoke(kit, "logLTVIncrease:event:", event: event, parameters: ltvParameters).outcome,
                       .returnedStatus)
        XCTAssertEqual(kit.ltvAmount, 12.5)

        let optOutParameters = MPForwardQueueParameters(parameters: [NSNumber(value: true)])
        XCTAssertEqual(invoke(kit, "setOptOut:", parameters: optOutParameters).outcome, .returnedStatus)
        XCTAssertEqual(kit.optOut, true)

        let attParameters = MPForwardQueueParameters(parameters: [NSNumber(value: 3), NSNumber(value: 42)])
        XCTAssertEqual(invoke(kit,
                              "setATTStatus:withATTStatusTimestampMillis:",
                              parameters: attParameters).outcome,
                       .returnedStatus)
        XCTAssertEqual(kit.attStatus, 3)
    }

    func testBlockArgumentsAreGuardedAndRemainCallable() {
        let kit = KitDispatchTargetStub()
        let filteredUser = NSObject()
        var callbacks = Set<String>()

        let restorationHandler: RestorationBlock = { objects in
            if objects?.firstObject as? String == "restored" {
                callbacks.insert("restoration")
            }
        }
        let activityParameters = MPForwardQueueParameters(parameters: [
            NSUserActivity(activityType: "test"),
            restorationHandler
        ])
        XCTAssertEqual(invoke(kit,
                              "continueUserActivity:restorationHandler:",
                              parameters: activityParameters).outcome,
                       .returnedStatus)

        func eventHandler(_ name: String) -> RoktEventBlock {
            { _ in callbacks.insert(name) }
        }

        let placementParameters = MPForwardQueueParameters(parameters: [
            "placement",
            ["key": "value"],
            [String: AnyObject](),
            NSObject(),
            eventHandler("placements"),
            NSObject()
        ])
        XCTAssertEqual(invoke(kit,
                              "selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:",
                              filteredUser: filteredUser,
                              parameters: placementParameters).outcome,
                       .returnedStatus)

        let shoppableParameters = MPForwardQueueParameters(parameters: [
            "placement",
            ["key": "value"],
            NSObject(),
            eventHandler("shoppable")
        ])
        XCTAssertEqual(invoke(kit,
                              "selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:",
                              filteredUser: filteredUser,
                              parameters: shoppableParameters).outcome,
                       .returnedStatus)

        let eventsParameters = MPForwardQueueParameters(parameters: ["placement", eventHandler("events")])
        XCTAssertEqual(invoke(kit, "events:onEvent:", parameters: eventsParameters).outcome, .returnedStatus)

        let globalParameters = MPForwardQueueParameters(parameters: [eventHandler("global")])
        XCTAssertEqual(invoke(kit, "globalEvents:", parameters: globalParameters).outcome, .returnedStatus)

        XCTAssertEqual(callbacks, ["restoration", "placements", "shoppable", "events", "global"])
    }

    func testExplicitFailureOutcomes() {
        XCTAssertEqual(invoke(nil, "beginSession").outcome, .notImplemented)
        XCTAssertEqual(invoke(EmptyKitDispatchTarget(), "beginSession").outcome, .notImplemented)
        XCTAssertEqual(invoke(KitDispatchTargetStub(), "setSessionId:").outcome, .missingArguments)
        XCTAssertEqual(invoke(KitDispatchTargetStub(), "unknownSelector:").outcome, .unknownSelector)

        let invalidBlockParameters = MPForwardQueueParameters(parameters: ["placement", "not a block"])
        XCTAssertEqual(invoke(KitDispatchTargetStub(),
                              "events:onEvent:",
                              parameters: invalidBlockParameters).outcome,
                       .missingArguments)
    }

    private func invoke(_ kit: MPKitDispatchTarget?,
                        _ selectorName: String,
                        event: Any? = nil,
                        filteredUser: AnyObject? = nil,
                        parameters: MPForwardQueueParameters? = nil) -> MPKitInvocationResult {
        invoker.invoke(kit,
                       selectorName: selectorName,
                       event: event,
                       filteredUser: filteredUser,
                       parameters: parameters)
    }
}
