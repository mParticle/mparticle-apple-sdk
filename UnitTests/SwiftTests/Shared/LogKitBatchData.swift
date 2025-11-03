//
//  LogKitBatchData.swift
//  mParticle-Apple-SDK
//
//  Created by Nick Dimitrakas on 11/3/25.
//

import Foundation

enum LogKitBatchData {
    static let invalidJSON = #"{"invalid": "json""#
    static let singleEvent = #"{"events":[{"id":1}]}"#
    static let multiEvent = #"{"events":[{"id":1},{"id":2}]}"#
    static let parsedSingleEvent: [String: Any] = [
        "events": [
            ["id": 1]
        ]
    ]
}
