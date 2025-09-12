//
//  ExecutorMock.swift
//  mParticle-Apple-SDK
//
//  Created by Denis Chilik on 9/9/25.
//


class ExecutorMock: ExecutorProtocol {
    func messageQueue() -> dispatch_queue_t {
        return DispatchQueue.main
    }
    
    func isMessageQueue() -> Bool {
        return false
    }
    
    var executeOnMessageQueueAsync: Bool = false
    
    func execute(onMessage block: (() -> Void)!) {
        executeOnMessageQueueAsync = true
        block()
    }
    
    var executeOnMessageQueueSync = false
    
    func execute(onMessageSync block: (() -> Void)!) {
        executeOnMessageQueueSync = true
        block()
    }
    
    var executeOnMainAsync = false
    
    func execute(onMain block: (() -> Void)!) {
        executeOnMainAsync = true
        block()
    }
    
    var executeOnMainSync = false
    
    func execute(onMainSync block: (() -> Void)!) {
        executeOnMainSync = true
        block()
    }
}
