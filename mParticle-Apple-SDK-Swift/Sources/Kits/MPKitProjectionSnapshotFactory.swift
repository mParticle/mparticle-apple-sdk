import Foundation

/// The projection state one kit's remote `pr` array resolves to.
///
/// All three properties are nil for a kit that configures no projections, which
/// is how `MPKitConfiguration` has always represented that case.
@objc(MPKitProjectionSet)
public final class MPKitProjectionSet: NSObject {
    /// One boolean per message type, indexed by message type.
    @objc public let configuredMessageTypeProjections: [NSNumber]?

    /// Index-aligned with `configuredMessageTypeProjections`. Entries are either
    /// an `MPKitProjectionSnapshot` or `NSNull` where that message type has no
    /// default projection.
    @objc public let defaultProjections: [Any]?

    /// The non-default projections, or nil when there are none.
    @objc public let projections: [MPKitProjectionSnapshot]?

    init(
        configuredMessageTypeProjections: [NSNumber]?,
        defaultProjections: [Any]?,
        projections: [MPKitProjectionSnapshot]?
    ) {
        self.configuredMessageTypeProjections = configuredMessageTypeProjections
        self.defaultProjections = defaultProjections
        self.projections = projections
        super.init()
    }

    static let empty = MPKitProjectionSet(
        configuredMessageTypeProjections: nil,
        defaultProjections: nil,
        projections: nil
    )
}

/// Builds the projection snapshots `MPKitProjectionEngine` evaluates, directly
/// from remote kit configuration.
@objc(MPKitProjectionSnapshotFactory)
public final class MPKitProjectionSnapshotFactory: NSObject {
    /// Mirrors of Objective-C enumerations this module cannot import. Raw values
    /// must stay in step with `Include/MPEnums.h` and `MPIConstants.h`.
    private enum MessageType {
        static let event: UInt = 4
        static let commerceEvent: UInt = 16
    }

    private enum ProjectionType {
        static let event: UInt = 1
    }

    private enum DataType {
        static let string = 1
        static let long = 5
    }

    private enum BehaviorSelector {
        static let forEach: UInt = 0
        static let last: UInt = 1
    }

    private let hasher: MPIHasher
    private let logger: MPLog

    /// Creates a factory using the SDK's stable hashing behavior.
    @objc public init(hasher: MPIHasher, logger: MPLog) {
        self.hasher = hasher
        self.logger = logger
        super.init()
    }

    /// Resolves one kit's `pr` array into projections bucketed by message type.
    ///
    /// `messageTypeCount` is `+[MPEnum messageTypeSize]`, passed in rather than
    /// mirrored so the two cannot drift.
    @objc(projectionSetFromConfigurations:messageTypeCount:)
    public func projectionSet(
        from configurations: [Any]?,
        messageTypeCount: UInt
    ) -> MPKitProjectionSet {
        guard let configurations, !configurations.isEmpty else {
            return .empty
        }

        var configured = [NSNumber](repeating: NSNumber(value: false), count: Int(messageTypeCount))
        var defaults = [Any](repeating: NSNull(), count: Int(messageTypeCount))
        var projections: [MPKitProjectionSnapshot] = []

        for configuration in configurations {
            guard let configuration = configuration as? [AnyHashable: Any],
                  let projection = makeProjection(from: configuration)
            else {
                continue
            }

            let messageType = projection.snapshot.messageType
            guard messageType <= messageTypeCount else {
                logger.error("Ignoring projection with out-of-range message type: \(messageType)")
                continue
            }

            let index = Int(messageType)
            assign(NSNumber(value: true), at: index, in: &configured)
            if projection.isDefault {
                assign(projection.snapshot, at: index, in: &defaults)
            } else {
                projections.append(projection.snapshot)
            }
        }

        return MPKitProjectionSet(
            configuredMessageTypeProjections: configured,
            defaultProjections: defaults,
            projections: projections.isEmpty ? nil : projections
        )
    }

    /// Builds one event projection, or nil when the configuration carries no
    /// `action` — the case Objective-C signalled by returning nil from `init`.
    @objc(projectionSnapshotFromConfiguration:)
    public func projectionSnapshot(from configuration: [AnyHashable: Any]?) -> MPKitProjectionSnapshot? {
        makeProjection(from: configuration)?.snapshot
    }

    /// Builds the attribute projection at `attributeIndex`, or nil when the
    /// configuration carries no `action` or no attribute map at that index.
    @objc(attributeProjectionSnapshotFromConfiguration:attributeIndex:)
    public func attributeProjectionSnapshot(
        from configuration: [AnyHashable: Any]?,
        attributeIndex: UInt
    ) -> MPKitAttributeProjectionSnapshot? {
        guard let action = MPProjectionFieldParser.action(from: configuration),
              let fields = MPProjectionFieldParser.attributeFields(from: action, attributeIndex: attributeIndex)
        else {
            return nil
        }

        let attributeFields = MPProjectionFieldParser.attributeProjectionFields(
            from: configuration,
            attributeIndex: attributeIndex
        )

        return MPKitAttributeProjectionSnapshot(
            name: fields.name,
            projectedName: fields.projectedName,
            matchType: fields.matchType.rawValue,
            propertyKind: fields.propertyKind.rawValue,
            dataType: clampedDataType(attributeFields.dataType),
            required: attributeFields.isRequired
        )
    }

    // MARK: - Private

    private func makeProjection(
        from configuration: [AnyHashable: Any]?
    ) -> (snapshot: MPKitProjectionSnapshot, isDefault: Bool)? {
        guard let action = MPProjectionFieldParser.action(from: configuration) else {
            return nil
        }

        let fields = MPProjectionFieldParser.eventFields(from: configuration, action: action)
        let behavior = MPEventProjectionParser.behavior(from: configuration)
        let messageType = MPEventProjectionParser.messageType(
            fromMatchesIn: configuration,
            defaultValue: MessageType.event
        )
        let matches = MPEventProjectionParser.matches(
            from: configuration,
            isCommerceEvent: messageType == MessageType.commerceEvent
        )

        let snapshot = MPKitProjectionSnapshot(
            projectionId: MPProjectionFieldParser.projectionId(from: configuration),
            name: fields.name,
            projectedName: fields.projectedName,
            matchType: fields.matchType.rawValue,
            projectionType: ProjectionType.event,
            propertyKind: fields.propertyKind.rawValue,
            projectionMatches: matches?.map(matchSnapshot(from:)),
            attributeProjections: attributeProjections(from: configuration, action: action),
            behaviorSelector: behavior.selectsLast ? BehaviorSelector.last : BehaviorSelector.forEach,
            eventType: eventType(from: configuration),
            messageType: messageType,
            outboundMessageType: MPEventProjectionParser.outboundMessageType(
                from: action,
                defaultValue: MessageType.event
            ),
            maxCustomParameters: behavior.maxCustomParameters,
            appendAsIs: behavior.appendAsIs
        )

        return (snapshot, behavior.isDefault)
    }

    private func attributeProjections(
        from configuration: [AnyHashable: Any]?,
        action: [AnyHashable: Any]
    ) -> [MPKitAttributeProjectionSnapshot]? {
        guard let attributeMaps = action["attribute_maps"] as? [Any] else {
            return nil
        }

        let projections = attributeMaps.indices.compactMap {
            attributeProjectionSnapshot(from: configuration, attributeIndex: UInt($0))
        }

        return projections.isEmpty ? nil : projections
    }

    private func matchSnapshot(from fields: MPProjectionMatchFields) -> MPKitProjectionMatchSnapshot {
        MPKitProjectionMatchSnapshot(
            attributeKey: fields.attributeKey,
            // The engine only ever compares these against string attribute
            // values, so a non-string entry could never have matched.
            attributeValues: fields.attributeValues.compactMap { $0 as? String }
        )
    }

    private func eventType(from configuration: [AnyHashable: Any]?) -> UInt {
        guard let matches = configuration?["matches"] as? [Any],
              let match = matches.first as? [AnyHashable: Any],
              let eventName = match["event"] as? String,
              !eventName.isEmpty
        else {
            return MPEventTypeSwift.other.rawValue
        }

        return hasher.eventType(forHash: eventName).rawValue
    }

    private func clampedDataType(_ dataType: Int) -> Int {
        (DataType.string...DataType.long).contains(dataType) ? dataType : DataType.string
    }

    /// `-[NSMutableArray setObject:atIndexedSubscript:]` appends when the index
    /// equals the count, which is the only reason `MPMessageTypeMedia` (20)
    /// registers against a `messageTypeCount` of 20. Preserved deliberately.
    private func assign<Element>(_ value: Element, at index: Int, in array: inout [Element]) {
        if index == array.count {
            array.append(value)
        } else {
            array[index] = value
        }
    }
}
