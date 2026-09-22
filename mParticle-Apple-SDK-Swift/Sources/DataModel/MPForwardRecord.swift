import Foundation

@objc public final class MPForwardRecordPRIVATE: NSObject {
    @objc public var forwardRecordId: UInt64 = 0
    @objc public var dataDictionary: NSMutableDictionary?
    @objc public var mpid: NSNumber

    @objc(initWithId:dataDictionary:mpid:)
    public init(recordId: Int64, dataDictionary: NSDictionary?, mpid: NSNumber) {
        forwardRecordId = UInt64(recordId)
        self.mpid = mpid
        if let dataDictionary, !MPSwiftIsNull(dataDictionary) {
            self.dataDictionary = NSMutableDictionary(dictionary: dataDictionary)
        } else {
            self.dataDictionary = nil
        }
        super.init()
    }

    @objc(initWithId:data:mpid:)
    public convenience init?(recordId: Int64, data: Data, mpid: NSNumber) {
        do {
            guard let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary else {
                return nil
            }
            self.init(recordId: recordId, dataDictionary: jsonDictionary, mpid: mpid)
        } catch {
            NSLog("mParticle -> Error deserializing the data into a dictionary representation: %@", error.localizedDescription)
            return nil
        }
    }

    @objc public var timestamp: NSNumber? {
        get { dataDictionary?[MessageKeys.kMPTimestampKey] as? NSNumber }
        set {
            if let newValue {
                dataDictionary?[MessageKeys.kMPTimestampKey] = newValue
            }
        }
    }

    @objc public func dataRepresentation() -> Data? {
        guard let dataDictionary,
              !MPSwiftIsNull(dataDictionary),
              JSONSerialization.isValidJSONObject(dataDictionary)
        else {
            NSLog("mParticle -> Invalid Data dictionary.")
            return nil
        }
        do {
            return try JSONSerialization.data(withJSONObject: dataDictionary, options: [])
        } catch {
            NSLog("mParticle -> Error serializing the dictionary into a data representation: %@", error.localizedDescription)
            return nil
        }
    }

    @objc public func isEqual(toRecord other: MPForwardRecordPRIVATE) -> Bool {
        // Match ObjC: messaging a nil dictionary's isEqualToDictionary: is NO even if both are nil.
        guard let lhs = dataDictionary, let rhs = other.dataDictionary, lhs.isEqual(rhs) else {
            return false
        }
        var equal = true
        if forwardRecordId > 0, other.forwardRecordId > 0 {
            equal = forwardRecordId == other.forwardRecordId
        }
        if equal {
            equal = mpid.isEqual(to: other.mpid)
        }
        return equal
    }

    override public var hash: Int {
        (dataDictionary?.hash ?? 0) ^ Int(truncatingIfNeeded: forwardRecordId) ^ mpid.hashValue
    }
}
