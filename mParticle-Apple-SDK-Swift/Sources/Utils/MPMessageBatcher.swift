import Foundation

/// Pure packing arithmetic for grouping persisted messages into uploads. The
/// caller marshals each message to its byte length and crash-report flag, keeps
/// every side effect (fetching messages, building `MPUpload`s, persistence), and
/// rebuilds the message batches from the index groups this type returns.
@objc public final class MPMessageBatcher: NSObject {
    /// Packs message indices into batches bounded by message count and byte size.
    /// Crash reports use their own, larger per-batch and per-message ceilings. A
    /// message larger than its applicable per-message ceiling is dropped. The
    /// returned arrays hold indices into the input, in original order.
    @objc(batchGroupsWithLengths:crashFlags:maxMessages:maxBatchBytes:maxMessageBytes:crashBatchBytes:crashMessageBytes:)
    public static func batchIndexGroups(byteLengths: [Int],
                                        isCrashReport: [Bool],
                                        maxBatchMessages: Int,
                                        maxBatchBytes: Int,
                                        maxMessageBytes: Int,
                                        crashMaxBatchBytes: Int,
                                        crashMaxMessageBytes: Int) -> [[Int]] {
        var batchIndexGroups: [[Int]] = []
        var batchIndices: [Int] = []
        var batchMessageCount = 0
        var batchByteCount = 0

        for index in 0..<byteLengths.count {
            let byteLength = byteLengths[index]
            let crashReport = index < isCrashReport.count && isCrashReport[index]
            let iterationMaxBatchBytes = crashReport ? crashMaxBatchBytes : maxBatchBytes
            let iterationMaxMessageBytes = crashReport ? crashMaxMessageBytes : maxMessageBytes

            if byteLength > iterationMaxMessageBytes { continue }

            if batchMessageCount + 1 > maxBatchMessages || batchByteCount + byteLength > iterationMaxBatchBytes {
                batchIndexGroups.append(batchIndices)
                batchIndices = []
                batchMessageCount = 0
                batchByteCount = 0
            }

            batchIndices.append(index)
            batchMessageCount += 1
            batchByteCount += byteLength
        }

        if !batchIndices.isEmpty {
            batchIndexGroups.append(batchIndices)
        }

        return batchIndexGroups
    }
}
