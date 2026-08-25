import Foundation

@objc public final class MPIntegrationAttributesPRIVATE: NSObject {
    @objc public var integrationId: NSNumber
    @objc public var attributes: NSDictionary

    @objc(initWithIntegrationId:attributes:)
    public init?(integrationId: Any?, attributes: Any?) {
        guard let integrationId = integrationId as? NSNumber,
              let attributes = attributes as? NSDictionary,
              !attributes.allKeys.isEmpty else {
            return nil
        }

        var valid = true
        attributes.enumerateKeysAndObjects { key, value, stop in
            if !(key is String) || !(value is String) {
                valid = false
                NSLog("mParticle -> Integration attributes must be a dictionary of string, string.")
                stop.pointee = true
            }
        }

        guard valid else { return nil }

        self.integrationId = integrationId
        self.attributes = attributes.copy() as? NSDictionary ?? attributes
        super.init()
    }

    @objc(initWithIntegrationId:attributesData:)
    public convenience init?(integrationId: Any?, attributesData: Any?) {
        guard let attributesData = attributesData as? Data else { return nil }

        let attributes: NSDictionary?
        do {
            attributes = try JSONSerialization.jsonObject(with: attributesData, options: []) as? NSDictionary
        } catch {
            NSLog("mParticle -> Exception thrown trying to deserialize integration attributes: %@", error.localizedDescription)
            return nil
        }

        self.init(integrationId: integrationId, attributes: attributes)
    }

    @objc public func dictionaryRepresentation() -> NSDictionary {
        [integrationId.stringValue: attributes]
    }

    @objc public func serializedString() -> String? {
        let dictionary = dictionaryRepresentation()
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            NSLog("mParticle -> Exception thrown trying to serialize integration attributes: %@", error.localizedDescription)
            return nil
        }
    }
}
