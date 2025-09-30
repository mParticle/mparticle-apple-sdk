//
//  MPLaunchInfo.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 2/11/25.
//

import Foundation
@objc public class MPLaunchInfo : NSObject {
    private let annotationKey = UIApplication.OpenURLOptionsKey.annotation
    private let sourceAppKey = UIApplication.OpenURLOptionsKey.sourceApplication
    private var sourceApp: String?
    
    @objc public private(set) var sourceApplication: String?
    @objc public private(set) var annotation: String?
    @objc public private(set) var url: URL
    
    @objc required public init(URL: URL, sourceApplication: String?, annotation: Any?) {
        sourceApp = sourceApplication
        self.url = URL
        if let sourceApp = sourceApp {
            let urlString = url.absoluteString
            let appLinksRange = urlString.range(of: "al_applink_data")
            self.sourceApplication = appLinksRange?.lowerBound == nil ? sourceApp : String(format: "AppLink(%@)", sourceApp)
        } else {
            self.sourceApplication = nil
        }
        self.annotation = MPLaunchInfo.stringifyAnnotation(annotation)
        
        super.init()
    }
    
    @objc public init(URL: URL, options: [String : Any]?) {
        self.url = URL
        if let options = options {
            if let sourceApp = options[self.sourceAppKey.rawValue] as? String {
                self.sourceApp = sourceApp
            }
            if let sourceApp = self.sourceApp {
                let urlString = url.absoluteString
                let appLinksRange = urlString.range(of: "al_applink_data")
                self.sourceApplication = appLinksRange?.lowerBound == nil ? sourceApp : String(format: "AppLink(%@)", sourceApp)
            } else {
                self.sourceApplication = nil
            }
            
            if let annotation = options[self.annotationKey.rawValue] as? String {
                self.annotation = annotation
            }
        }
        
        super.init()
    }

    private class func stringifyAnnotation(_ annotation: Any?) -> String? {
        if let stringAnnotation = annotation as? String {
            return stringAnnotation
        }
        if let numberAnnotation = annotation as? NSNumber {
            return numberAnnotation.stringValue
        }
        if let dateAnnotation = annotation as? Date {
            return MPDateFormatter.string(fromDateRFC3339: dateAnnotation)
        }
        if let dictionaryAnnotation = annotation as? [String: Any?] {
            var jsonData: Data?
            var stringDict: [String: String] = [:]
            for key in dictionaryAnnotation.keys {
                if let value = dictionaryAnnotation[key] {
                    stringDict[key] = stringifyAnnotation(value)
                }
            }
            do {
                jsonData = try JSONSerialization.data(withJSONObject: stringDict, options: [])
            } catch {
                MPLog.error("Error serializing annotation from app launch: \(dictionaryAnnotation)")
            }
            if let jsonData = jsonData {
                return String(data: jsonData, encoding: .utf8)
            } else {
                return nil
            }
        }
        if let arrayAnnotation = annotation as? [Any] {
            var jsonData: Data?
            var stringArray: [String] = []
            for value in arrayAnnotation {
                if let value = stringifyAnnotation(value) {
                    stringArray.append(value)
                }
            }
            do {
                jsonData = try JSONSerialization.data(withJSONObject: stringArray, options: [])
            } catch {
                MPLog.error("Error serializing annotation from app launch: \(arrayAnnotation)")
            }
            if let jsonData = jsonData {
                return String(data: jsonData, encoding: .utf8)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    @objc public var options: [String : Any] {
        get {
            var options: [String : Any] = [:]
            
            if let sourceApplication = self.sourceApplication {
                options[self.sourceAppKey.rawValue] = sourceApplication
            }
            
            if let annotation = self.annotation {
                options[self.annotationKey.rawValue] = annotation
            }
            
            return options
        }
    }
}
