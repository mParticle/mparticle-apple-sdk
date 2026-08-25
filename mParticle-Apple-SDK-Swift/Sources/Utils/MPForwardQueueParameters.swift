import Foundation

@objc(MPForwardQueueParameters) public class MPForwardQueueParameters: NSObject {
    private var parameters: [Any] = []

    @objc public override init() {
        super.init()
    }

    @objc public init(parameters: [Any]) {
        if !parameters.isEmpty {
            self.parameters = parameters
        }
        super.init()
    }

    @objc public var count: UInt {
        UInt(parameters.count)
    }

    @objc public func addParameter(_ parameter: Any?) {
        parameters.append(parameter ?? NSNull())
    }

    @objc public subscript(idx: Int) -> Any? {
        guard idx >= 0, idx < parameters.count else {
            return nil
        }
        let value = parameters[idx]
        return (value as AnyObject) === NSNull() ? nil : value
    }
}
