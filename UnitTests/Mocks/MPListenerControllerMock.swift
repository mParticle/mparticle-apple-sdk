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

extension MPListenerControllerMock {
    
    /// Verifies that the listener was called with the expected selector and parameters.
    /// Automatically checks `onAPICalledCalled`, the selector, and up to three parameters.
    func assertCalled(
        _ expectedSelector: Selector,
        param1 expectedParam1: NSObject? = nil,
        param2 expectedParam2: NSObject? = nil,
        param3 expectedParam3: NSObject? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(onAPICalledCalled, "Expected onAPICalled to be called", file: file, line: line)
        
        guard let actualSelector = onAPICalledApiName else {
            XCTFail("Expected API name \(expectedSelector), but none was recorded", file: file, line: line)
            return
        }
        XCTAssertEqual(
            NSStringFromSelector(actualSelector),
            NSStringFromSelector(expectedSelector),
            "Expected API selector to match",
            file: file,
            line: line
        )
        
        if let expectedParam1 {
            XCTAssertEqual(
                onAPICalledParameter1,
                expectedParam1,
                "Expected param1 to match for \(expectedSelector)",
                file: file,
                line: line
            )
        }
        
        if let expectedParam2 {
            XCTAssertEqual(
                onAPICalledParameter2,
                expectedParam2,
                "Expected param2 to match for \(expectedSelector)",
                file: file,
                line: line
            )
        }
        
        if let expectedParam3 {
            XCTAssertEqual(
                onAPICalledParameter3,
                expectedParam3,
                "Expected param3 to match for \(expectedSelector)",
                file: file,
                line: line
            )
        }
    }
    
    /// Verifies that no API call occurred.
    func assertNotCalled(file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(onAPICalledCalled, "Expected onAPICalled NOT to be called", file: file, line: line)
        XCTAssertTrue(onAPICalledApiNames.isEmpty, "Expected no recorded API names", file: file, line: line)
    }
}
