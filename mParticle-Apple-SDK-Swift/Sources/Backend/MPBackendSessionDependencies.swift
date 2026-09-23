import Foundation

/// Live dependencies shared by backend session workflows on the existing SDK queue.
@objc(MPBackendSessionDependencies)
public final class MPBackendSessionDependencies: NSObject {
    let persistence: () -> MPBackendPersistence?
    let stateMachine: () -> MPStateMachinePRIVATE
    let makeMessageContext: () -> MPMessageBuilderContext
    let runningInBackground: () -> Bool
    let enqueueOnMessage: (@escaping () -> Void) -> Void
    let upload: ((() -> Void)?) -> Void
    let logger: () -> MPLog?
    var now: () -> TimeInterval = { Date().timeIntervalSince1970 }

    @objc public init(
        persistence: @escaping () -> MPBackendPersistence?,
        stateMachine: @escaping () -> MPStateMachinePRIVATE,
        makeMessageContext: @escaping () -> MPMessageBuilderContext,
        runningInBackground: @escaping () -> Bool,
        enqueueOnMessage: @escaping (@escaping () -> Void) -> Void,
        upload: @escaping ((() -> Void)?) -> Void,
        logger: @escaping () -> MPLog?
    ) {
        self.persistence = persistence
        self.stateMachine = stateMachine
        self.makeMessageContext = makeMessageContext
        self.runningInBackground = runningInBackground
        self.enqueueOnMessage = enqueueOnMessage
        self.upload = upload
        self.logger = logger
        super.init()
    }
}
