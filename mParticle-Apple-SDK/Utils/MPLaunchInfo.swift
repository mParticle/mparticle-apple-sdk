//
//  MPLaunchInfo.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 12/18/24.
//

import Foundation
@objc public class MPLaunchInfo : NSObject {
    @objc private var sourceApp: String?
    @objc public private(set) var url: URL
    @objc public private(set) var sourceApplication: String?
    @objc public private(set) var annotation: String?
    @objc public private(set) var options: [String : Any]?

    @objc(initWithURL:sourceApplication:annotation:) public init?(url: URL?, sourceApplication: String?, annotation: Any?) {
        guard let url else { return nil }

        self.sourceApp = sourceApplication
        self.url = url
        super.init()
        
        if let sourceApp = self.sourceApp {
            let urlString = url.absoluteString
            let appLinksRange = urlString.range(of: "al_applink_data")
            self.sourceApplication = appLinksRange == nil ? sourceApp : "AppLink(\(sourceApp))"
        } else {
            self.sourceApplication = nil
        }
        
        self.annotation = convertAnnotationToString(rawAnnotation: annotation)
        
        self.options = [:]
        if self.sourceApplication != nil {
            self.options?[UIApplication.OpenURLOptionsKey.sourceApplication.rawValue] = self.sourceApplication
        }
        if self.annotation != nil {
            self.options?[UIApplication.OpenURLOptionsKey.annotation.rawValue] = self.annotation
        }
    }

    @objc(initWithURL:options:) public init?(url: URL?, options: [String : Any]? = nil) {
        guard let url else { return nil }

        self.sourceApp = options?[UIApplication.OpenURLOptionsKey.sourceApplication.rawValue] as? String
        self.annotation = options?[UIApplication.OpenURLOptionsKey.annotation.rawValue] as? String
        self.url = url
        super.init()
                
        if let sourceApp = self.sourceApp {
            let urlString = url.absoluteString
            let appLinksRange = urlString.range(of: "al_applink_data")
            self.sourceApplication = appLinksRange == nil ? sourceApp : "AppLink(\(sourceApp))"
        } else {
            self.sourceApplication = nil
        }
    }
    
    private func convertAnnotationToString(rawAnnotation: Any?) -> String? {
        guard let rawAnnotation else { return nil }
        
        if let annotationString = rawAnnotation as? String {
            return annotationString
        } else if let annotationDictionary = rawAnnotation as? [String : Any] {
            var finalDict: [String : String] = [:]
            for (key, value) in annotationDictionary {
                if let valueString = self.convertAnnotationToString(rawAnnotation: value) {
                    finalDict[key] = valueString
                }
            }
            if finalDict.isEmpty { return nil } else {
                return serializeObject(finalDict)
            }
        } else if let annotationArray = rawAnnotation as? [Any] {
            var finalArray: [String] = []
            for value in annotationArray {
                if let valueString = self.convertAnnotationToString(rawAnnotation: value) {
                    finalArray.append(valueString)
                }
            }
            if finalArray.isEmpty { return nil } else {
                return serializeObject(finalArray)
            }
        } else if let annotationString = rawAnnotation as? String {
            return annotationString
        } else if let annotationNumber = rawAnnotation as? NSNumber {
            return annotationNumber.stringValue
        } else if let annotationDate = rawAnnotation as? Date {
            return MPDateFormatter.string(fromDateRFC3339: annotationDate)
        } else {
            return nil
        }
    }
    
    private func serializeObject(_ object: Any) -> String? {
        if let dictData = try? JSONSerialization.data(withJSONObject: object, options: []) {
            return String(data: dictData, encoding: .utf8)
        } else {
            MPLog.error("Error serializing annotation from app launch: \(object)")
            return nil
        }
    }
}
