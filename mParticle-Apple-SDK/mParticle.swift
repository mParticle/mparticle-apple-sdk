

@objcMembers
class MParticleSwift: NSObject {
    private let executor: ExecutorProtocol
    private let kitContainer: MPKitContainerProtocol
    var backendController: MPBackendControllerProtocol!
    
    init(executor: ExecutorProtocol, kitContainer: MPKitContainerProtocol) {
        self.executor = executor
        self.kitContainer = kitContainer
    }
    
}
