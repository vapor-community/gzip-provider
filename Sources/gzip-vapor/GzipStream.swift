import Core
import Transport
import gzip
import Foundation

public final class GzipStream: Transport.Stream {
    
    let mode: GzipMode
    private let processor: GzipProcessor
    let stream: Transport.Stream
    
    init(mode: GzipMode, stream: Transport.Stream) throws {
        self.mode = mode
        self.processor = mode.processor()
        try self.processor.initialize()
        self.stream = stream
    }
    
    public var closed: Bool = false
    
    public func setTimeout(_ timeout: Double) throws {
        try stream.setTimeout(timeout)
    }
    
    public func close() throws {
        processor.close()
        try stream.close()
        self.closed = true
    }

    public func flush() throws {
        if let tail = try processor.safeFlush() {
            try stream.send(tail.byteArray)
        }
        try stream.flush()
    }

    public func send(_ bytes: Bytes) throws {
        let data = try processor.process(data: Data(bytes).toNSData(), isLast: false)
        try stream.send(data.byteArray)
    }
    
    public func receive(max: Int) throws -> Bytes {
        if stream.closed {
            if let tail = try processor.safeFlush() {
                return tail.byteArray
            } else {
                return []
            }
        }
        let raw = try stream.receive(max: max)
        let data = try processor.process(data: Data(raw).toNSData(), isLast: stream.closed)
        if stream.closed {
            processor.close()
            self.closed = true
        }
        return data.byteArray
    }
}

#if os(Linux)
    extension Data {
        init(_ bytes: [UInt8]) {
            self = Data(bytes: bytes)
        }
    }
#endif
