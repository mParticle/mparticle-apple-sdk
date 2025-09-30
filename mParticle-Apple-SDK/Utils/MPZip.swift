import Foundation
import zlib

@objc final public class MPZip_PRIVATE: NSObject {
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
            
            guard deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.stride)) == Z_OK else {
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
}
