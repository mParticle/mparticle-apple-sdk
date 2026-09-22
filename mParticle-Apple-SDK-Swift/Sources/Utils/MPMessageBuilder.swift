import Foundation
#if canImport(UIKit)
    import UIKit
#endif

/// The values `MPMessageBuilderPRIVATE` needs from `MParticle.sharedInstance`, which the Swift
/// module cannot import. The Objective-C boundary fills it and passes it in, mirroring the
/// `MPURLRequestContext` value-context pattern.
@objc(MPMessageBuilderContext)
public final class MPMessageBuilderContext: NSObject {
    @objc public let dataPlanId: String?
    @objc public let dataPlanVersion: NSNumber?
    @objc public let logger: MPLog?

    @objc public init(dataPlanId: String?, dataPlanVersion: NSNumber?, logger: MPLog?) {
        self.dataPlanId = dataPlanId
        self.dataPlanVersion = dataPlanVersion
        self.logger = logger
        super.init()
    }
}

/// Assembles the message dictionary an `MPMessage` is built from.
///
/// The Objective-C `MPMessageBuilder` this replaces held an `atomic` pointer to a
/// `NSMutableDictionary` whose *contents* were mutated without synchronization, so the atomicity
/// never protected the dictionary itself. A builder is created, mutated and built by one owner on
/// `[MParticle messageQueue]`, so a plain Swift dictionary is equivalent.
@objc(MPMessageBuilder)
public final class MPMessageBuilderPRIVATE: NSObject {
    private var messageDictionary: [AnyHashable: Any]
    private var uuid: String?
    private let context: MPMessageBuilderContext

    @objc public private(set) var messageType: String
    @objc public private(set) var session: MPSessionPRIVATE?
    @objc public private(set) var timestamp: TimeInterval
    @objc public private(set) var dataPlanId: String?
    @objc public private(set) var dataPlanVersion: NSNumber?

    @objc public var messageInfo: [AnyHashable: Any] { messageDictionary }

    // MARK: - Message type <-> wire string

    /// `nil` from `MPMessageBuilderFields` means the raw value is not a known message type; the
    /// error is logged and `kMPMessageTypeStringUnknown` returned, as the original `default:`
    /// branch did.
    @objc(stringForMessageType:logger:)
    public static func string(forMessageType rawValue: UInt, logger: MPLog?) -> String {
        guard let string = MPMessageBuilderFields.string(forMessageTypeRawValue: rawValue) else {
            logger?.error("Unknown message type enum: \(rawValue)")
            return kMPMessageTypeStringUnknown
        }
        return string
    }

    /// Returns the raw `MPMessageType` value, or `MPMessageTypeUnknown` (0) when the string
    /// matches none of the known constants — again logging first, as the original did.
    @objc(messageTypeForString:logger:)
    public static func messageType(forString string: String, logger: MPLog?) -> UInt {
        guard let rawType = MPMessageBuilderFields.rawMessageType(forString: string) else {
            logger?.error("Unknown message type string: \(string)")
            return 0
        }
        return rawType.uintValue
    }

    // MARK: - Init

    @objc(initWithMessageType:session:context:)
    public init?(messageType rawValue: UInt, session: MPSessionPRIVATE?, context: MPMessageBuilderContext) {
        // The original returned nil for `MPMessageTypeUnknown`, whose raw value is 0.
        guard rawValue != 0 else { return nil }

        self.context = context
        self.session = session
        timestamp = Date().timeIntervalSince1970
        messageType = Self.string(forMessageType: rawValue, logger: context.logger)
        dataPlanId = context.dataPlanId
        dataPlanVersion = context.dataPlanVersion

        messageDictionary = [MessageKeys.kMPTimestampKey: MPMilliseconds(timestamp: timestamp)]

        super.init()

        if let session {
            if rawValue == MPMessageTypeSwift.sessionStart.rawValue {
                uuid = session.uuid
            } else {
                messageDictionary[MessageKeys.kMPSessionIdKey] = session.uuid
                messageDictionary[MessageKeys.kMPSessionStartTimestamp] = MPMilliseconds(timestamp: session.startTime)

                if rawValue == MPMessageTypeSwift.sessionEnd.rawValue {
                    let userIdNumbers = MPMessageBuilderFields.filteredUserIds(from: session.sessionUserIds)
                    messageDictionary[kMPSessionUserIdsKey] = userIdNumbers
                }
            }
        }

        applyPresentationContext()
    }

    @objc(initWithMessageType:session:messageInfo:context:)
    public convenience init?(
        messageType rawValue: UInt,
        session: MPSessionPRIVATE?,
        messageInfo: [AnyHashable: Any]?,
        context: MPMessageBuilderContext
    ) {
        self.init(messageType: rawValue, session: session, context: context)
        guard let messageInfo else { return }

        messageDictionary.merge(messageInfo) { _, new in new }

        // The original messaged `transformValuesToString` on whatever sat under the attributes
        // key; a non-dictionary would have crashed. Leaving it untouched is the same for every
        // valid payload and safer for an invalid one.
        if let messageAttributes = messageDictionary[MessageKeys.kMPAttributesKey] as? NSDictionary {
            messageDictionary[MessageKeys.kMPAttributesKey] = AttributeValueTransformer
                .transformedAttributeValues(in: messageAttributes, logger: context.logger)
        }
    }

    @objc(initWithMessageType:session:userIdentityChange:context:)
    public convenience init?(
        messageType rawValue: UInt,
        session: MPSessionPRIVATE?,
        userIdentityChange: MPUserIdentityChangePRIVATE?,
        context: MPMessageBuilderContext
    ) {
        self.init(messageType: rawValue, session: session, context: context)
        guard let userIdentityChange else { return }
        apply(userIdentityChange: userIdentityChange)
    }

    @objc(initWithMessageType:session:userAttributeChange:context:)
    public convenience init?(
        messageType rawValue: UInt,
        session: MPSessionPRIVATE?,
        userAttributeChange: MPUserAttributeChange?,
        context: MPMessageBuilderContext
    ) {
        self.init(messageType: rawValue, session: session, context: context)
        guard let userAttributeChange else { return }
        apply(userAttributeChange: userAttributeChange)
    }

    // MARK: - Mutators

    @objc(timestamp:)
    public func updateTimestamp(_ timestamp: TimeInterval) {
        self.timestamp = timestamp
        messageDictionary[MessageKeys.kMPTimestampKey] = MPMilliseconds(timestamp: timestamp)
    }

    /// NOTE: here "sessionFinalized" is really referring to whether we are starting a new session
    /// on launch, see Facebook event forwarder backend code.
    @objc(stateTransition:previousSession:launchInfo:)
    public func stateTransition(
        _ sessionFinalized: Bool,
        previousSession: MPSessionPRIVATE?,
        launchInfo: MPLaunchInfo?
    ) {
        let fields = MPMessageBuilderFields.stateTransitionFields(
            sourceApplication: launchInfo?.sourceApplication,
            launchURLString: launchInfo?.url.absoluteString,
            launchParameters: launchInfo?.annotation,
            previousSessionInterruptions: previousSession.map { Int($0.numberOfInterruptions) } ?? 0,
            sessionFinalized: sessionFinalized
        )

        if let sourceApplication = fields.sourceApplication {
            messageDictionary[kMPLaunchSourceKey] = sourceApplication
        }
        if let launchURLString = fields.launchURLString {
            messageDictionary[kMPLaunchURLKey] = launchURLString
        }
        if let launchParameters = fields.launchParameters {
            messageDictionary[kMPLaunchParametersKey] = launchParameters
        }
        messageDictionary[kMPLaunchNumberOfSessionInterruptionsKey] = NSNumber(value: fields.numberOfSessionInterruptions)
        messageDictionary[kMPLaunchSessionFinalizedKey] = NSNumber(value: fields.sessionFinalized)
    }

    // MARK: - Build

    @objc public func build() -> MPMessagePRIVATE {
        messageDictionary[MessageKeys.kMPMessageTypeKey] = messageType
        let messageId = uuid ?? UUID().uuidString
        messageDictionary[MessageKeys.kMPMessageIdKey] = messageId

        let sessionUserId = session?.userId
        let userId = (sessionUserId?.intValue ?? 0) != 0 ? sessionUserId! : MPUserDefaults.storedMpId()

        return MPMessagePRIVATE(
            session: session,
            messageType: messageType,
            messageInfo: messageDictionary as NSDictionary,
            uploadStatus: kMPUploadStatusBatch,
            uuid: messageId,
            timestamp: timestamp,
            userId: userId,
            dataPlanId: dataPlanId,
            dataPlanVersion: dataPlanVersion
        )
    }

    // MARK: - Private

    private func apply(userAttributeChange: MPUserAttributeChange) {
        let oldValue = userAttributeChange.userAttributes?[userAttributeChange.key]
        let fields = MPMessageBuilderFields.userAttributeChangeFields(
            deleted: userAttributeChange.deleted,
            key: userAttributeChange.key,
            oldValue: oldValue,
            newValue: userAttributeChange.valueToLog
        )

        messageDictionary[kMPUserAttributeWasDeletedKey] = NSNumber(value: fields.deleted)
        messageDictionary[MessageKeys.kMPEventNameKey] = fields.attributeKey
        messageDictionary[kMPUserAttributeOldValueKey] = fields.oldValue
        messageDictionary[kMPUserAttributeNewValueKey] = fields.newValue
        messageDictionary[kMPUserAttributeNewlyAddedKey] = NSNumber(value: fields.newlyAdded)
    }

    private func apply(userIdentityChange: MPUserIdentityChangePRIVATE) {
        if let dictionary = userIdentityChange.newUserIdentity?.dictionaryRepresentation() {
            messageDictionary[kMPUserIdentityNewValueKey] = dictionary
        }
        if let dictionary = userIdentityChange.oldUserIdentity?.dictionaryRepresentation() {
            messageDictionary[kMPUserIdentityOldValueKey] = dictionary
        }
    }

    /// Records which view controller was on screen and whether the message was built on the main
    /// thread, matching the original's three-way outcome.
    private func applyPresentationContext() {
        let presentedViewControllerDescription: String?
        let isMainThread = Thread.isMainThread

        if isMainThread {
            if MPStateMachinePRIVATE.isAppExtension() {
                presentedViewControllerDescription = "extension_message"
            } else {
                presentedViewControllerDescription = Self.presentedViewControllerDescription()
            }
        } else {
            presentedViewControllerDescription = "off_thread"
        }

        if let presentedViewControllerDescription {
            messageDictionary[kMPPresentedViewControllerKey] = presentedViewControllerDescription
        }
        messageDictionary[kMPMainThreadKey] = NSNumber(value: isMainThread)
    }

    private static func presentedViewControllerDescription() -> String? {
        guard let application = MPApplication_PRIVATE.sharedUIApplication() else { return nil }

        // `connectedScenes` is imported as non-optional, but the Objective-C getter can still
        // answer nil — an OCMock of `UIApplication` with the selector unstubbed does, and the
        // previous Objective-C code simply iterated an empty set. Read it through the runtime so
        // a nil answer stays nil instead of trapping.
        let connectedScenes = application
            .perform(NSSelectorFromString("connectedScenes"))?
            .takeUnretainedValue() as? Set<UIScene> ?? []

        // Key window from the active window scene (iOS 13+).
        let keyWindow = connectedScenes
            .lazy
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .compactMap { scene in scene.windows.first(where: \.isKeyWindow) }
            .first

        guard let presented = keyWindow?.rootViewController?.presentedViewController else {
            return nil
        }
        // The original used `[[presentedViewController class] description]`, i.e. the Objective-C
        // runtime name, which is not what Swift's `type(of:)` prints for a Swift class.
        return NSStringFromClass(type(of: presented))
    }
}

// Wire keys mirrored from `MPIConstants.m` and the deleted `MPMessageBuilder.{h,m}`; the Swift
// module cannot import the ObjC module, so the canonical values are duplicated here as literals.
private let kMPMessageTypeStringUnknown = "unknown"
private let kMPSessionUserIdsKey = "smpids"
private let kMPPresentedViewControllerKey = "vc"
private let kMPMainThreadKey = "mt"
private let kMPLaunchSourceKey = "src"
private let kMPLaunchURLKey = "lr"
private let kMPLaunchParametersKey = "lpr"
private let kMPLaunchSessionFinalizedKey = "sf"
private let kMPLaunchNumberOfSessionInterruptionsKey = "nsi"
private let kMPUserAttributeWasDeletedKey = "d"
private let kMPUserAttributeNewValueKey = "nv"
private let kMPUserAttributeOldValueKey = "ov"
private let kMPUserAttributeNewlyAddedKey = "na"
private let kMPUserIdentityNewValueKey = "ni"
private let kMPUserIdentityOldValueKey = "oi"

/// `MPUploadStatusBatch` (`MPIConstants.h`).
private let kMPUploadStatusBatch = 1
