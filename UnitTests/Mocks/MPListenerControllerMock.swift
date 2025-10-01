import XCTest

class MPListenerControllerMock: NSObject, MPListenerControllerProtocol {
    var onAPICalledCalled = false

    var onAPICalledApiNames = [Selector]()

    var onAPICalledApiName: Selector? {
        return onAPICalledApiNames.first
    }

    var onAPICalledParameter1: NSObject?
    var onAPICalledExpectation: XCTestExpectation?

    func onAPICalled(_ apiName: Selector) {
        onAPICalledCalled = true
        onAPICalledApiNames.append(apiName)
        onAPICalledExpectation?.fulfill()
    }

    func onAPICalled(_ apiName: Selector, parameter1: NSObject?) {
        onAPICalledCalled = true
        onAPICalledApiNames.append(apiName)
        onAPICalledParameter1 = parameter1
        onAPICalledExpectation?.fulfill()
    }

    var onAPICalledParameter2: NSObject?

    func onAPICalled(_ apiName: Selector, parameter1: NSObject?, parameter2: NSObject?) {
        onAPICalledCalled = true
        onAPICalledApiNames.append(apiName)
        onAPICalledParameter1 = parameter1
        onAPICalledParameter2 = parameter2
        onAPICalledExpectation?.fulfill()
    }

    var onAPICalledParameter3: NSObject?

    func onAPICalled(_ apiName: Selector, parameter1: NSObject?, parameter2: NSObject?, parameter3: NSObject?) {
        onAPICalledCalled = true
        onAPICalledApiNames.append(apiName)
        onAPICalledParameter1 = parameter1
        onAPICalledParameter2 = parameter2
        onAPICalledParameter3 = parameter3
        onAPICalledExpectation?.fulfill()
    }
}
