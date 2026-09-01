import Foundation

/// A Foundation-only view of a projection match.
@objc(MPKitProjectionMatchSnapshot)
public final class MPKitProjectionMatchSnapshot: NSObject {
    fileprivate let attributeKey: String?
    fileprivate let attributeValues: [String]

    /// Creates an immutable projection-match snapshot.
    @objc public init(attributeKey: String?, attributeValues: [String]?) {
        self.attributeKey = attributeKey
        self.attributeValues = attributeValues ?? []
        super.init()
    }
}

/// A Foundation-only view of an attribute projection.
@objc(MPKitAttributeProjectionSnapshot)
public final class MPKitAttributeProjectionSnapshot: NSObject {
    fileprivate let name: String?
    fileprivate let projectedName: String?
    fileprivate let matchType: Int
    fileprivate let propertyKind: UInt
    fileprivate let dataType: Int
    fileprivate let required: Bool

    /// Creates an immutable attribute-projection snapshot.
    @objc public init(
        name: String?,
        projectedName: String?,
        matchType: Int,
        propertyKind: UInt,
        dataType: Int,
        required: Bool
    ) {
        self.name = name
        self.projectedName = projectedName
        self.matchType = matchType
        self.propertyKind = propertyKind
        self.dataType = dataType
        self.required = required
        super.init()
    }
}

/// A Foundation-only view of an event projection.
@objc(MPKitProjectionSnapshot)
public final class MPKitProjectionSnapshot: NSObject {
    fileprivate let projectionId: UInt
    fileprivate let name: String?
    fileprivate let projectedName: String?
    fileprivate let matchType: Int
    fileprivate let projectionType: UInt
    fileprivate let propertyKind: UInt
    fileprivate let projectionMatches: [MPKitProjectionMatchSnapshot]?
    fileprivate let attributeProjections: [MPKitAttributeProjectionSnapshot]
    fileprivate let behaviorSelector: UInt
    fileprivate let eventType: UInt
    fileprivate let messageType: UInt
    fileprivate let outboundMessageType: UInt
    fileprivate let maxCustomParameters: UInt
    fileprivate let appendAsIs: Bool

    /// Creates an immutable event-projection snapshot.
    @objc public init(
        projectionId: UInt,
        name: String?,
        projectedName: String?,
        matchType: Int,
        projectionType: UInt,
        propertyKind: UInt,
        projectionMatches: [MPKitProjectionMatchSnapshot]?,
        attributeProjections: [MPKitAttributeProjectionSnapshot]?,
        behaviorSelector: UInt,
        eventType: UInt,
        messageType: UInt,
        outboundMessageType: UInt,
        maxCustomParameters: UInt,
        appendAsIs: Bool
    ) {
        self.projectionId = projectionId
        self.name = name
        self.projectedName = projectedName
        self.matchType = matchType
        self.projectionType = projectionType
        self.propertyKind = propertyKind
        self.projectionMatches = projectionMatches
        self.attributeProjections = attributeProjections ?? []
        self.behaviorSelector = behaviorSelector
        self.eventType = eventType
        self.messageType = messageType
        self.outboundMessageType = outboundMessageType
        self.maxCustomParameters = maxCustomParameters
        self.appendAsIs = appendAsIs
        super.init()
    }
}

/// A Foundation-only view of a non-commerce event being projected.
@objc(MPKitEventProjectionSource)
public final class MPKitEventProjectionSource: NSObject {
    fileprivate let type: UInt
    fileprivate let name: String
    fileprivate let attributes: [String: Any]?
    fileprivate let attributeKeys: [String]
    fileprivate let matchingAttributes: [String: Any]
    fileprivate let messageType: UInt

    /// Creates an immutable event source snapshot.
    @objc public init(
        type: UInt,
        name: String,
        attributes: [String: Any]?,
        attributeKeys: [String],
        matchingAttributes: [String: Any]?,
        messageType: UInt
    ) {
        self.type = type
        self.name = name
        self.attributes = attributes
        self.attributeKeys = attributeKeys
        self.matchingAttributes = matchingAttributes ?? [:]
        self.messageType = messageType
        super.init()
    }
}

/// A Foundation-only view of a product, impression, or promotion used by commerce projections.
@objc(MPKitCommerceEntityProjectionSource)
public final class MPKitCommerceEntityProjectionSource: NSObject {
    fileprivate let fields: [String: Any]
    fileprivate let attributes: [String: Any]

    /// Creates an immutable commerce-entity source snapshot.
    @objc public init(fields: [String: Any]?, attributes: [String: Any]?) {
        self.fields = fields ?? [:]
        self.attributes = attributes ?? [:]
        super.init()
    }
}

/// A Foundation-only view of a commerce event being projected.
@objc(MPKitCommerceProjectionSource)
public final class MPKitCommerceProjectionSource: NSObject {
    fileprivate let type: UInt
    fileprivate let kind: Int
    fileprivate let eventFields: [String: Any]
    fileprivate let eventAttributes: [String: Any]
    fileprivate let originalCustomAttributes: [String: Any]?
    fileprivate let products: [MPKitCommerceEntityProjectionSource]
    fileprivate let impressions: [MPKitCommerceEntityProjectionSource]
    fileprivate let promotions: [MPKitCommerceEntityProjectionSource]

    /// Creates an immutable commerce-event source snapshot.
    @objc public init(
        type: UInt,
        kind: Int,
        eventFields: [String: Any]?,
        eventAttributes: [String: Any]?,
        originalCustomAttributes: [String: Any]?,
        products: [MPKitCommerceEntityProjectionSource]?,
        impressions: [MPKitCommerceEntityProjectionSource]?,
        promotions: [MPKitCommerceEntityProjectionSource]?
    ) {
        self.type = type
        self.kind = kind
        self.eventFields = eventFields ?? [:]
        self.eventAttributes = eventAttributes ?? [:]
        self.originalCustomAttributes = originalCustomAttributes
        self.products = products ?? []
        self.impressions = impressions ?? []
        self.promotions = promotions ?? []
        super.init()
    }
}

/// The Objective-C event shape represented by a projection output.
@objc public enum MPKitProjectionOutputKind: Int {
    /// Return the original non-commerce event.
    case originalEvent
    /// Create a projected non-commerce event.
    case projectedEvent
    /// Return the original commerce event.
    case originalCommerceEvent
    /// Create a projected commerce-event copy.
    case projectedCommerceEvent
}

/// Describes one event that Objective-C should materialize after projection evaluation.
@objc(MPKitProjectionOutput)
public final class MPKitProjectionOutput: NSObject {
    /// The event shape Objective-C should create.
    @objc public let kind: MPKitProjectionOutputKind
    /// The projected event name, when the output is a non-commerce event.
    @objc public let projectedName: String?
    /// The custom attributes to assign to the output.
    @objc public let attributes: [String: Any]?
    /// The applied projection identifier, or nil for an original event.
    @objc public let projectionId: NSNumber?

    fileprivate init(
        kind: MPKitProjectionOutputKind,
        projectedName: String? = nil,
        attributes: [String: Any]? = nil,
        projectionId: UInt? = nil
    ) {
        self.kind = kind
        self.projectedName = projectedName
        self.attributes = attributes
        self.projectionId = projectionId.map(NSNumber.init(value:))
        super.init()
    }
}

/// Evaluates event and commerce projection policy using Foundation-only snapshots.
@objc(MPKitProjectionEngine)
public final class MPKitProjectionEngine: NSObject {
    private enum MatchType {
        static let notSpecified = -1
        static let string = 0
        static let hash = 1
        static let field = 2
        static let `static` = 3
    }

    private enum ProjectionType {
        static let event: UInt = 1
    }

    private enum PropertyKind {
        static let eventField: UInt = 0
        static let eventAttribute: UInt = 1
        static let productField: UInt = 2
        static let productAttribute: UInt = 3
        static let promotionField: UInt = 4
        static let promotionAttribute: UInt = 5
    }

    private enum BehaviorSelector {
        static let forEach: UInt = 0
    }

    private enum CommerceKind {
        static let product = 1
        static let promotion = 2
        static let impression = 3
    }

    private enum MessageType {
        static let screenView: UInt = 3
        static let commerceEvent: UInt = 16
    }

    private enum AttributeProjectionResult {
        case projected([String: Any]?)
        case missingRequired
    }

    private let hasher: MPIHasher
    private let valueTransformer: MPKitValueTransformer

    /// Creates a projection engine using the SDK's stable hashing and value-coercion behavior.
    @objc public init(hasher: MPIHasher, valueTransformer: MPKitValueTransformer) {
        self.hasher = hasher
        self.valueTransformer = valueTransformer
        super.init()
    }

    /// Returns descriptors for a non-commerce event and the projections applied to it.
    @objc(projectEvent:projections:defaultProjection:)
    public func projectEvent(
        _ source: MPKitEventProjectionSource,
        projections: [MPKitProjectionSnapshot],
        defaultProjection: MPKitProjectionSnapshot?
    ) -> [MPKitProjectionOutput] {
        var outputs = projections
            .filter { $0.messageType == source.messageType }
            .compactMap { projection -> MPKitProjectionOutput? in
                guard shouldProjectEvent(source, with: projection) else { return nil }
                guard case let .projected(attributes) = projectEventAttributes(source, with: projection) else {
                    return nil
                }
                return MPKitProjectionOutput(
                    kind: .projectedEvent,
                    projectedName: projection.projectedName ?? source.name,
                    attributes: attributes,
                    projectionId: projection.projectionId
                )
            }

        if outputs.isEmpty, let defaultProjection {
            if case let .projected(attributes) = projectEventAttributes(source, with: defaultProjection) {
                let projectedName = defaultProjection.projectionType == ProjectionType.event
                    ? defaultProjection.projectedName ?? source.name
                    : source.name
                outputs.append(MPKitProjectionOutput(
                    kind: .projectedEvent,
                    projectedName: projectedName,
                    attributes: attributes,
                    projectionId: defaultProjection.projectionId
                ))
            }
        }

        if outputs.isEmpty {
            outputs.append(MPKitProjectionOutput(kind: .originalEvent))
        }
        return outputs
    }

    /// Returns descriptors for commerce and expanded non-commerce projection outputs.
    @objc(projectCommerceEvent:projections:)
    public func projectCommerceEvent(
        _ source: MPKitCommerceProjectionSource,
        projections: [MPKitProjectionSnapshot]
    ) -> [MPKitProjectionOutput] {
        let applicableProjections = projections.filter {
            $0.messageType == MessageType.commerceEvent
                && $0.eventType == source.type
                && isCommerceProjection($0, applicableTo: source)
        }
        var outputs: [MPKitProjectionOutput] = []

        for projection in applicableProjections {
            switch projectCommerceAttributes(source, with: projection) {
            case let .projected(attributeDictionaries):
                if attributeDictionaries.isEmpty {
                    outputs.append(outputWithoutProjectedAttributes(source, projection: projection))
                } else {
                    outputs.append(contentsOf: attributeDictionaries.map {
                        projectedCommerceOutput(attributes: $0, projection: projection)
                    })
                }

            case .missingRequired:
                outputs.append(MPKitProjectionOutput(kind: .originalCommerceEvent))
            }
        }

        if outputs.isEmpty {
            outputs.append(MPKitProjectionOutput(kind: .originalCommerceEvent))
        }
        return outputs
    }

    private func shouldProjectEvent(
        _ source: MPKitEventProjectionSource,
        with projection: MPKitProjectionSnapshot
    ) -> Bool {
        let matchesName: Bool
        switch projection.matchType {
        case MatchType.string:
            matchesName = caseInsensitiveEqual(source.name, projection.name)
        case MatchType.hash:
            let hash = hasher.hashEventType(
                MPEventTypeSwift(rawValue: source.type) ?? .other,
                eventName: source.name,
                isLogScreen: source.messageType == MessageType.screenView
            )
            matchesName = (hash as NSString).integerValue == integerValue(projection.name)
        case MatchType.notSpecified:
            matchesName = true
        default:
            matchesName = false
        }
        return matchesName && matchesAll(projection.projectionMatches, attributes: source.matchingAttributes)
    }

    private func matchesAll(
        _ matches: [MPKitProjectionMatchSnapshot]?,
        attributes: [String: Any]
    ) -> Bool {
        guard let matches else { return true }
        return matches.allSatisfy { match in
            guard let key = match.attributeKey,
                  let value = value(forCaseInsensitiveKey: key, in: attributes) else {
                return false
            }
            return match.attributeValues.contains { caseInsensitiveEqual($0, value as? String) }
        }
    }

    private func projectEventAttributes(
        _ source: MPKitEventProjectionSource,
        with projection: MPKitProjectionSnapshot
    ) -> AttributeProjectionResult {
        guard let attributes = source.attributes else { return .projected(nil) }

        var remainingProjections = projection.attributeProjections
        var projectedAttributes = attributes
        var projectedKeyMarkers: [String] = []
        var nonProjectedKeys = source.attributeKeys
        let eventType = MPEventTypeSwift(rawValue: source.type) ?? .other
        var keyHashes: [String: Int] = [:]
        var hashKeys: [Int: String] = [:]

        for key in source.attributeKeys {
            let hash = hasher.hashEventAttributeKey(
                eventType,
                eventName: source.name,
                customAttributeName: key,
                isLogScreen: source.messageType == MessageType.screenView
            )
            let hashValue = (hash as NSString).integerValue
            keyHashes[key] = hashValue
            hashKeys[hashValue] = key
        }

        for key in source.attributeKeys {
            guard let value = attributes[key] else { continue }
            var projectionsToRemove: [ObjectIdentifier] = []

            for attributeProjection in remainingProjections {
                let projectedKey = attributeProjection.projectedName ?? key
                switch attributeProjection.matchType {
                case MatchType.string:
                    if caseInsensitiveEqual(key, attributeProjection.name) {
                        if let projectedValue = valueTransformer.transformValue(
                            value,
                            dataType: attributeProjection.dataType
                        ) {
                            projectedAttributes.removeValue(forKey: key)
                            projectedAttributes[projectedKey] = projectedValue
                            if let marker = projectedValue as? String {
                                projectedKeyMarkers.append(marker)
                            }
                            projectionsToRemove.append(ObjectIdentifier(attributeProjection))
                        } else if attributeProjection.required {
                            return .missingRequired
                        }
                    } else if attributeProjection.required,
                              attributeProjection.name.flatMap({ attributes[$0] }) == nil {
                        return .missingRequired
                    }

                case MatchType.hash:
                    if keyHashes[key] == integerValue(attributeProjection.name) {
                        if let projectedValue = valueTransformer.transformValue(
                            value,
                            dataType: attributeProjection.dataType
                        ) {
                            projectedAttributes.removeValue(forKey: key)
                            projectedAttributes[projectedKey] = projectedValue
                            if let marker = projectedValue as? String {
                                projectedKeyMarkers.append(marker)
                            }
                            projectionsToRemove.append(ObjectIdentifier(attributeProjection))
                        } else if attributeProjection.required {
                            return .missingRequired
                        }
                    } else if attributeProjection.required,
                              hashKeys[integerValue(attributeProjection.name)] == nil {
                        return .missingRequired
                    }

                case MatchType.field:
                    projectedAttributes[projectedKey] = source.name
                    projectedKeyMarkers.append(projectedKey)
                    projectionsToRemove.append(ObjectIdentifier(attributeProjection))

                case MatchType.static:
                    if let projectedValue = valueTransformer.transformValue(
                        attributeProjection.name,
                        dataType: attributeProjection.dataType
                    ) {
                        projectedAttributes[projectedKey] = projectedValue
                        projectedKeyMarkers.append(projectedKey)
                    }
                    projectionsToRemove.append(ObjectIdentifier(attributeProjection))

                default:
                    break
                }
            }

            remainingProjections.removeAll {
                projectionsToRemove.contains(ObjectIdentifier($0))
            }
        }

        nonProjectedKeys.removeAll { projectedKeyMarkers.contains($0) }
        if projection.appendAsIs, projection.maxCustomParameters > 0 {
            if nonProjectedKeys.count > projection.maxCustomParameters {
                let remainingSlots = Int(projection.maxCustomParameters) - projectedKeyMarkers.count
                if remainingSlots > 0 {
                    nonProjectedKeys.sort()
                    nonProjectedKeys.removeFirst(min(remainingSlots, nonProjectedKeys.count))
                    projectedAttributes.removeValues(forKeys: nonProjectedKeys)
                }
            }
        } else {
            projectedAttributes.removeValues(forKeys: nonProjectedKeys)
        }

        return .projected(projectedAttributes.isEmpty ? nil : projectedAttributes)
    }

    private func isCommerceProjection(
        _ projection: MPKitProjectionSnapshot,
        applicableTo source: MPKitCommerceProjectionSource
    ) -> Bool {
        guard let matches = projection.projectionMatches else { return true }
        let dictionaries: [[String: Any]]

        switch projection.propertyKind {
        case PropertyKind.eventField:
            dictionaries = [source.eventFields]
        case PropertyKind.eventAttribute:
            dictionaries = [source.eventAttributes]
        case PropertyKind.productField:
            dictionaries = source.kind == CommerceKind.product
                ? source.products.map(\.fields)
                : source.kind == CommerceKind.impression ? source.impressions.map(\.fields) : []
        case PropertyKind.productAttribute:
            dictionaries = source.kind == CommerceKind.product
                ? source.products.map(\.attributes)
                : source.kind == CommerceKind.impression ? source.impressions.map(\.attributes) : []
        case PropertyKind.promotionField:
            dictionaries = source.kind == CommerceKind.promotion ? source.promotions.map(\.fields) : []
        case PropertyKind.promotionAttribute:
            dictionaries = []
        default:
            dictionaries = []
        }

        return matches.allSatisfy { match in
            dictionaries.contains { dictionary in
                dictionary.contains { key, value in
                    guard let attributeKey = match.attributeKey,
                          attributeKey == hasher.hashCommerceEventAttribute(
                              MPEventTypeSwift(rawValue: source.type) ?? .other,
                              key: key
                          ), let stringValue = value as? String else {
                        return false
                    }
                    return match.attributeValues.contains { caseInsensitiveEqual($0, stringValue) }
                }
            }
        }
    }

    private func projectCommerceAttributes(
        _ source: MPKitCommerceProjectionSource,
        with projection: MPKitProjectionSnapshot
    ) -> CommerceProjectionResult {
        let eventProjections = projection.attributeProjections.filter {
            $0.propertyKind == PropertyKind.eventField || $0.propertyKind == PropertyKind.eventAttribute
        }
        let eventAttributes: [String: Any]
        switch projectCommerceEventAttributes(source, projections: eventProjections) {
        case let .projected(attributes):
            eventAttributes = attributes ?? [:]
        case .missingRequired:
            return .missingRequired
        }

        var projectedDictionaries: [[String: Any]] = []
        switch source.kind {
        case CommerceKind.product:
            let productProjections = projection.attributeProjections.filter {
                $0.propertyKind == PropertyKind.productField || $0.propertyKind == PropertyKind.productAttribute
            }
            var previousAttributes: [String: Any]? = eventAttributes.isEmpty ? nil : eventAttributes
            for product in selectedEntities(source.products, behaviorSelector: projection.behaviorSelector) {
                switch projectProduct(
                    product,
                    projections: productProjections,
                    eventType: source.type,
                    previousAttributes: previousAttributes
                ) {
                case let .projected(attributes):
                    previousAttributes = attributes
                    guard let attributes else { continue }
                    var combinedAttributes = attributes
                    combinedAttributes.merge(eventAttributes) { _, eventValue in eventValue }
                    appendCustomAttributes(source.eventAttributes, to: &combinedAttributes, projection: projection)
                    projectedDictionaries.append(combinedAttributes)
                case .missingRequired:
                    return .missingRequired
                }
            }

        case CommerceKind.promotion:
            let promotionProjections = projection.attributeProjections.filter {
                $0.propertyKind == PropertyKind.promotionField
            }
            for promotion in selectedEntities(source.promotions, behaviorSelector: projection.behaviorSelector) {
                for attributeProjection in promotionProjections {
                    switch projectDictionary(promotion.fields, with: attributeProjection, eventType: source.type) {
                    case let .projected(attributes):
                        guard let attributes else { continue }
                        var combinedAttributes = attributes
                        combinedAttributes.merge(eventAttributes) { _, eventValue in eventValue }
                        appendCustomAttributes(source.eventAttributes, to: &combinedAttributes, projection: projection)
                        projectedDictionaries.append(combinedAttributes)
                    case .missingRequired:
                        return .missingRequired
                    }
                }
            }

        default:
            break
        }

        return .projected(projectedDictionaries)
    }

    private enum CommerceProjectionResult {
        case projected([[String: Any]])
        case missingRequired
    }

    private func projectCommerceEventAttributes(
        _ source: MPKitCommerceProjectionSource,
        projections: [MPKitAttributeProjectionSnapshot]
    ) -> AttributeProjectionResult {
        var projectedAttributes: [String: Any] = [:]
        var sourceDictionary: [String: Any] = [:]

        for propertyKind in [PropertyKind.eventField, PropertyKind.eventAttribute] {
            if projections.contains(where: { $0.propertyKind == propertyKind }) {
                sourceDictionary = propertyKind == PropertyKind.eventField
                    ? source.eventFields
                    : source.eventAttributes
            }

            for projection in projections {
                switch projectDictionary(sourceDictionary, with: projection, eventType: source.type) {
                case let .projected(attributes):
                    if let attributes {
                        projectedAttributes.merge(attributes) { _, newValue in newValue }
                    }
                case .missingRequired:
                    return .missingRequired
                }
            }
        }
        return .projected(projectedAttributes.isEmpty ? nil : projectedAttributes)
    }

    private func projectProduct(
        _ product: MPKitCommerceEntityProjectionSource,
        projections: [MPKitAttributeProjectionSnapshot],
        eventType: UInt,
        previousAttributes: [String: Any]?
    ) -> AttributeProjectionResult {
        var projectedAttributes: [String: Any] = [:]
        var lastAttributes = previousAttributes

        for propertyKind in [PropertyKind.productField, PropertyKind.productAttribute] {
            let filteredProjections = projections.filter { $0.propertyKind == propertyKind }
            guard !filteredProjections.isEmpty else { continue }
            let sourceDictionary = propertyKind == PropertyKind.productField ? product.fields : product.attributes

            for projection in filteredProjections {
                switch projectDictionary(sourceDictionary, with: projection, eventType: eventType) {
                case let .projected(attributes):
                    lastAttributes = attributes
                    if let attributes {
                        projectedAttributes.merge(attributes) { _, newValue in newValue }
                    }
                case .missingRequired:
                    return .missingRequired
                }
            }
        }

        return .projected(projectedAttributes.isEmpty ? lastAttributes : projectedAttributes)
    }

    private func projectDictionary(
        _ source: [String: Any],
        with projection: MPKitAttributeProjectionSnapshot,
        eventType: UInt?
    ) -> AttributeProjectionResult {
        let originalValue: Any?
        switch projection.matchType {
        case MatchType.hash:
            guard let eventType else { return .projected(nil) }
            let matchingKey = source.keys.first {
                let hash = hasher.hashCommerceEventAttribute(
                    MPEventTypeSwift(rawValue: eventType) ?? .other,
                    key: $0
                )
                return (hash as NSString).integerValue == integerValue(projection.name)
            }
            originalValue = matchingKey.flatMap { source[$0] }

        case MatchType.field, MatchType.string:
            originalValue = projection.name.flatMap { value(forCaseInsensitiveKey: $0, in: source) }

        case MatchType.static:
            originalValue = projection.name

        default:
            return .projected(nil)
        }

        guard let originalValue else {
            return projection.required ? .missingRequired : .projected(nil)
        }
        guard let value = valueTransformer.transformValue(originalValue, dataType: projection.dataType),
              let projectedName = projection.projectedName else {
            return .projected(nil)
        }
        return .projected([projectedName: value])
    }

    private func selectedEntities<T>(_ entities: [T], behaviorSelector: UInt) -> [T] {
        guard behaviorSelector != BehaviorSelector.forEach else { return entities }
        return entities.last.map { [$0] } ?? []
    }

    private func appendCustomAttributes(
        _ customAttributes: [String: Any],
        to projectedAttributes: inout [String: Any],
        projection: MPKitProjectionSnapshot
    ) {
        guard projection.appendAsIs, projection.maxCustomParameters > 0 else { return }
        let keys = customAttributes.count > projection.maxCustomParameters
            ? Array(customAttributes.keys.sorted().prefix(Int(projection.maxCustomParameters)))
            : Array(customAttributes.keys)
        for key in keys {
            projectedAttributes[key] = customAttributes[key]
        }
    }

    private func outputWithoutProjectedAttributes(
        _ source: MPKitCommerceProjectionSource,
        projection: MPKitProjectionSnapshot
    ) -> MPKitProjectionOutput {
        if projection.outboundMessageType == MessageType.commerceEvent {
            return MPKitProjectionOutput(
                kind: .projectedCommerceEvent,
                projectionId: projection.projectionId
            )
        }
        return MPKitProjectionOutput(
            kind: .projectedEvent,
            projectedName: projection.projectedName ?? " ",
            attributes: source.originalCustomAttributes,
            projectionId: projection.projectionId
        )
    }

    private func projectedCommerceOutput(
        attributes: [String: Any],
        projection: MPKitProjectionSnapshot
    ) -> MPKitProjectionOutput {
        if projection.outboundMessageType == MessageType.commerceEvent {
            return MPKitProjectionOutput(
                kind: .projectedCommerceEvent,
                attributes: attributes,
                projectionId: projection.projectionId
            )
        }
        return MPKitProjectionOutput(
            kind: .projectedEvent,
            projectedName: projection.projectedName ?? " ",
            attributes: attributes,
            projectionId: projection.projectionId
        )
    }

    private func value(forCaseInsensitiveKey key: String, in dictionary: [String: Any]) -> Any? {
        dictionary.first { caseInsensitiveEqual($0.key, key) }?.value
    }

    private func caseInsensitiveEqual(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs, let rhs else { return false }
        return lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }

    private func integerValue(_ value: String?) -> Int {
        (value as NSString?)?.integerValue ?? 0
    }
}

private extension Dictionary where Key == String, Value == Any {
    mutating func removeValues(forKeys keys: [String]) {
        for key in keys {
            removeValue(forKey: key)
        }
    }
}
