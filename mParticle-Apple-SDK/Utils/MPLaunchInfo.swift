//
//  MPLaunchInfo.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 10/18/24.
//

import Foundation

@objc public class MPLaunchInfo_PRIVATE: NSObject {

    @objc private(set) var url: URL
    @objc private(set) var sourceApplication: String?
    @objc private(set) var annotation: String?
    @objc private(set) var options: [String : Any]?
    
    private var sourceApp: String?
    
    @objc(initWithURL:sourceApplication:annotation:) public init(url: URL, sourceApplication: String?, annotation: Any?) {
        sourceApp = sourceApplication
        self.url = url
        super.init()
        updateSourceApplication()
        updateAnnotation(annotation: annotation)
        
        var optionsDict = [String: Any]()
        if let sourceApplication = sourceApplication {
            optionsDict[UIApplication.OpenURLOptionsKey.sourceApplication.rawValue] = sourceApplication
        }
        if let annotation = annotation {
            optionsDict[UIApplication.OpenURLOptionsKey.annotation.rawValue] = annotation
        }
        if optionsDict.count > 0 {
            options = optionsDict
        }
    }

    @objc(initWithURL:options:) public init(url: URL, options: [String : Any]?) {
        self.url = url
        self.options = options
        sourceApp = options?[UIApplication.OpenURLOptionsKey.sourceApplication.rawValue] as? String
        super.init()
        updateSourceApplication()
        updateAnnotation(annotation: options?[UIApplication.OpenURLOptionsKey.annotation.rawValue] as? String)
    }
    
    private func updateSourceApplication() {
        if let sourceApp = sourceApp {
            let urlString = url.absoluteString
            sourceApplication = urlString.contains("al_applink_data") ? sourceApp : "AppLink(\(sourceApp))"
        } else {
            sourceApplication = nil
        }
    }
    
    private func valueFromObject(_ object: Any?) -> Any? {
        var value: Any? = nil
        
        if let object = object as? Date {
            value = MPDateFormatter.string(fromDateRFC3339: object)
        } else if object is Data || object is Dictionary<AnyHashable, Any> || object is Array<AnyHashable> || object is Set<AnyHashable> {
            value = nil
        } else {
            value = object
        }
        
        return value
    }
    
    private func serializeDataObject(_ annotationObject: Any?) -> String? {
        guard let annotationObject else { return nil }
        
        do {
            let annotationData = try JSONSerialization.data(withJSONObject: annotationObject, options: [])
            let serializedAnnotation = String(data: annotationData, encoding: .utf8)
            return serializedAnnotation
        } catch {
            MPLogError("Error serializing annotation from app launch: %@", annotationObject)
            return nil
        }
    }
    
    private func updateAnnotation(annotation: Any?) {
        if var annotationDict = annotation as? [AnyHashable: Any] {
            for (key, obj) in annotationDict {
                if let value = valueFromObject(obj) {
                    annotationDict[key] = value
                }
            }
            self.annotation = serializeDataObject(annotationDict)
        } else if var annotationArray = annotation as? [Any] {
            for obj in annotationArray {
                if let value = valueFromObject(obj) {
                    annotationArray.append(value)
                }
            }
            self.annotation = serializeDataObject(annotationArray)
        } else if let annotationString = annotation as? String {
            self.annotation = annotationString
        } else if let annotationNumber = annotation as? NSNumber {
            self.annotation = annotationNumber.stringValue
        } else if let annotationDate = annotation as? Date {
            self.annotation = valueFromObject(annotationDate) as? String
        } else {
            self.annotation = nil
        }
    }
}
