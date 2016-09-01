import HTTP
import Vapor
import gzip
import Foundation

public enum GzipMiddlewareError: Error {
    case unsupportedStreamType
}

/// Client Gzip middlere:
/// 1. sets the "Accept-Encoding" header to "gzip"
/// 2. if the response has "Content-Encoding" == "gzip", uncompresses the body
public struct GzipClientMiddleware: Middleware {
    
    public init() { }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        request.headers["Accept-Encoding"] = "gzip"
        
        let response = try next.respond(to: request)
        
        guard response.headers["Content-Encoding"] == "gzip" else {
            return response
        }
        
        let zipped = response.body
        switch zipped {
        case .data(let bytes):
            response.body = .data(Array(try Data(bytes: bytes).gzipUncompressed()))
        case .chunked(let chunker):
            response.body = .chunked({ (stream: ChunkStream) in
                let gzipStream = try GzipStream(mode: .uncompress, stream: stream.raw)
                try chunker(ChunkStream(stream: gzipStream))
            })
        }
        return response
    }
}

/// Server Gzip middlere:
/// 1. checks if the "Accept-Encoding" header contains "gzip"
/// 2. if so, compresses the body and sets the response header "Content-Encoding" to "gzip",
public struct GzipServerMiddleware: Middleware {
    
    private let shouldGzip: (_ request: Request) -> Bool
    
    /// The `shouldGzip` closure is asked for every request whether that request
    /// should allow response gzipping. Returns `true` always by default.
    public init(shouldGzip: @escaping (_ request: Request) -> Bool = { _ in true }) {
        self.shouldGzip = shouldGzip
    }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        let acceptsGzip = request.headers["Accept-Encoding"]?.contains("gzip") == true
        guard acceptsGzip && shouldGzip(request) else {
            return try next.respond(to: request)
        }

        let response = try next.respond(to: request)
        response.headers["Content-Encoding"] = "gzip"
        
        let unzipped = response.body
        switch unzipped {
        case .data(let bytes):
            response.body = .data(Array(try Data(bytes: bytes).gzipCompressed()))
        case .chunked(let chunker):
            response.body = .chunked({ (stream: ChunkStream) in
                let gzipStream = try GzipStream(mode: .compress, stream: stream.raw)
                try chunker(ChunkStream(stream: gzipStream))
            })
        }
        return response
    }
}
