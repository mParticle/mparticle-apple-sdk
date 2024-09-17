//
//  MPLocationManager.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 9/12/24.
//

import Foundation
import UIKit

#if os(iOS) && !MPARTICLE_LOCATION_DISABLE
import CoreLocation
#endif

@objc final public class MPLocationManager_PRIVATE: NSObject {

    private static var _trackingLocation = false
    @objc public class var trackingLocation: Bool {
        return _trackingLocation
    }
    
    #if os(iOS) && !MPARTICLE_LOCATION_DISABLE
    private static var _locationManager: CLLocationManager?
    
    @objc public var location: CLLocation?
    @objc public private(set) var authorizationRequest: MPLocationAuthorizationRequest
    @objc public private(set) var requestedAccuracy: CLLocationAccuracy
    @objc public private(set) var requestedDistanceFilter: CLLocationDistance
    @objc public var backgroundLocationTracking: Bool

    @objc public var locationManager: CLLocationManager? {
        get {
            guard Self._locationManager == nil else {
                return Self._locationManager
            }
            
            let authorizationStatus = CLLocationManager.authorizationStatus()
            guard authorizationStatus != .restricted && authorizationStatus != .denied else {
                if let _ = Self._locationManager {
                    Self._locationManager = nil
                    location = nil
                    Self._trackingLocation = false
                }
                return nil
            }
            
            let _locationManager = CLLocationManager()
            _locationManager.delegate = self
            Self._locationManager = _locationManager
            return Self._locationManager
        }
    }
    
    @objc public init?(accuracy: CLLocationAccuracy, distanceFilter: CLLocationDistance, authorizationRequest: MPLocationAuthorizationRequest) {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        guard authorizationStatus != .restricted && authorizationStatus != .denied else {
            return nil
        }
        
        self.authorizationRequest = authorizationRequest
        requestedAccuracy = accuracy
        requestedDistanceFilter = distanceFilter
        backgroundLocationTracking = true
        Self._trackingLocation = false
        super.init()
        
        // Must be run on the main thread or no delegate methods will be called
        DispatchQueue.main.async {
            if let locationManager = self.locationManager {
                locationManager.desiredAccuracy = accuracy
                locationManager.distanceFilter = distanceFilter
                
                let keys = Bundle.main.infoDictionary?.keys
                if let keys = keys, authorizationRequest == .always && keys.contains("NSLocationAlwaysUsageDescription") {
                    locationManager.requestAlwaysAuthorization()
                } else if let keys = keys, authorizationRequest == .whenInUse && keys.contains("NSLocationWhenInUseUsageDescription") {
                    locationManager.requestWhenInUseAuthorization()
                } else {
                    locationManager.startUpdatingLocation()
                }
            }
        }
    }

    @objc public func endLocationTracking() {
        Self._locationManager?.stopUpdatingLocation()
        Self._locationManager = nil
       
        location = nil
        Self._trackingLocation = false
    }
    
    #endif
}

#if os(iOS) && !MPARTICLE_LOCATION_DISABLE
extension MPLocationManager_PRIVATE: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Self._trackingLocation = (status == .authorizedAlways || status == .authorizedWhenInUse)
        
        if Self._trackingLocation {
            locationManager?.startUpdatingLocation()
        }
    }
        
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}
#endif
