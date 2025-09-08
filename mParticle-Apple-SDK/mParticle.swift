

@objcMembers
class MParticleSwift: NSObject {
    private let executor: ExecutorProtocol
    private let kitContainer: MPKitContainerProtocol
    
    init(executor: ExecutorProtocol, kitContainer: MPKitContainerProtocol) {
        self.executor = executor
        self.kitContainer = kitContainer
    }
    
}
