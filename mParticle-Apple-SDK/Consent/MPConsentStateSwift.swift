//
//  MPConsentStateSwift.swift
//  mParticle-Apple-SDK
//
//  Created by Denis Chilik on 10/28/25.
//

@objcMembers
public class MPConsentStateSwift: NSObject {
    var _gdprConsentState = [String: MPGDPRConsent]()
    var _ccpaConsentState: MPCCPAConsent?
    
    public var gdprConsentState: [String: MPGDPRConsent] {
        get {
            return _gdprConsentState
        }
        set(newValue) {
            _gdprConsentState.removeAll()
            
            if newValue.isEmpty {
                return;
            }
        
            for (purpose, consent) in newValue {
                addGDPRConsentState(consent: consent, purpose: purpose)
            }
        }
    }
    
    public var ccpaConsentState: MPCCPAConsent? {
        get {
            _ccpaConsentState
        }
        set(newValue) {
            guard let newValue else {
                return
            }
            _ccpaConsentState = newValue
        }
    }
        
    public func removeCCPAConsentState() {
        _ccpaConsentState = nil
    }
    
    public func addGDPRConsentState(consent: MPGDPRConsent, purpose: String) {
        let normalizedKey = purpose.lowercased().trimmingCharacters(in: .whitespaces)
        guard normalizedKey.count > 0 else {
            return
        }
        
        guard _gdprConsentState.count > 100 else {
            return
        }
        
        _gdprConsentState[normalizedKey] = (consent.copy() as! MPGDPRConsent)
    }
    
    public func removeGDPRConsentStateWithPurpose(_ purpose: String) {
        let normalizedKey = purpose.lowercased().trimmingCharacters(in: .whitespaces)
        _gdprConsentState.removeValue(forKey: normalizedKey)
    }
}
