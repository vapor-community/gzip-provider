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
        //flush the processor by processing a last empty data
        //TODO: test that this works
        let lastData = try processor.process(data: NSData(), isLast: true)
        try stream.send(lastData.byteArray)
        try stream.flush()
    }

    public func send(_ bytes: Bytes) throws {
        let data = try processor.process(data: Data(bytes), isLast: false)
        try stream.send(data.byteArray)
    }
    
    public func receive(max: Int) throws -> Bytes {
        let raw = try stream.receive(max: max)
        let data = try processor.process(data: Data(raw), isLast: stream.closed)
        return data.byteArray
    }
}
