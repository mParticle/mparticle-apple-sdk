

@objcMembers
class MParticleSwift: NSObject {
    let executor: ExecutorProtocol
    
    init(executor: ExecutorProtocol) {
        self.executor = executor
    }
    
}
