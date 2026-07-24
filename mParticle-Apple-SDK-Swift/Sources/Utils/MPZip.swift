import Foundation
import zlib

@objc public final class MPZipPRIVATE: NSObject {
    @objc(compressedDataFromData:) public static func compressedData(from data: Data?) -> Data? {
        guard let data = data, !data.isEmpty else {
            return nil
        }

        var failed = false
        let chunkSize = 16384
        var output = Data(capacity: chunkSize)

        let dataCount = data.count
        data.withUnsafeBytes { inputPointer in
            guard let inputBaseAddress = inputPointer.bindMemory(to: Bytef.self).baseAddress else {
                failed = true
                return
            }

            var stream = z_stream()
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputBaseAddress)
            stream.avail_in = uInt(truncatingIfNeeded: dataCount)

            guard deflateInit2_(
                &stream,
                Z_DEFAULT_COMPRESSION,
                Z_DEFLATED,
                15 + 16,
                8,
                Z_DEFAULT_STRATEGY,
                ZLIB_VERSION,
                Int32(MemoryLayout<z_stream>.stride)
            ) == Z_OK else {
                failed = true
                return
            }

            repeat {
                let totalOut = Int(truncatingIfNeeded: stream.total_out)
                if totalOut >= output.count {
                    output.count += chunkSize
                }

                let outputCount = output.count
                output.withUnsafeMutableBytes { outputPointer in
                    guard let outputBaseAddress = outputPointer.bindMemory(to: Bytef.self).baseAddress else {
                        failed = true
                        return
                    }

                    stream.next_out = outputBaseAddress.advanced(by: totalOut)
                    stream.avail_out = uInt(truncatingIfNeeded: outputCount - totalOut)

                    failed = (deflate(&stream, Z_FINISH) != Z_OK)
                }
            } while stream.avail_out == 0 && !failed

            failed = (deflateEnd(&stream) != Z_OK)
            output.count = Int(truncatingIfNeeded: stream.total_out)
        }

        return failed ? nil : output
    }

    @objc(decompressedDataFromData:) public static func decompressedData(from data: Data?) -> Data? {
        guard let data = data, !data.isEmpty else {
            return nil
        }

        return data.withUnsafeBytes { inputPointer -> Data? in
            guard let inputBaseAddress = inputPointer.bindMemory(to: Bytef.self).baseAddress else {
                return nil
            }

            var stream = z_stream()
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputBaseAddress)
            stream.avail_in = uInt(truncatingIfNeeded: data.count)
            stream.total_out = 0
            stream.zalloc = nil
            stream.zfree = nil

            guard inflateInit2_(&stream, 15 + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.stride)) == Z_OK else {
                return nil
            }

            defer {
                inflateEnd(&stream)
            }

            let halfLength = max(data.count/2, 1)
            let output = NSMutableData(capacity: data.count + halfLength)!
            var done = false

            while !done {
                if stream.total_out >= output.length {
                    output.length += halfLength
                }

                stream.next_out = output.mutableBytes
                    .advanced(by: Int(truncatingIfNeeded: stream.total_out))
                    .assumingMemoryBound(to: Bytef.self)
                stream.avail_out = uInt(truncatingIfNeeded: output.length - Int(truncatingIfNeeded: stream.total_out))

                let status = inflate(&stream, Z_SYNC_FLUSH)
                if status == Z_STREAM_END {
                    done = true
                } else if status != Z_OK {
                    return nil
                }
            }

            output.length = Int(truncatingIfNeeded: stream.total_out)
            return output as Data
        }
    }

    @objc public static func isGzipCompressedData(_ data: Data?) -> Bool {
        guard let data = data, data.count >= 2 else {
            return false
        }

        return data[data.startIndex] == 0x1f && data[data.startIndex.advanced(by: 1)] == 0x8b
    }
}
