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
        default:
            //TODO: find out a way to uncompress chunks too
            throw GzipMiddlewareError.unsupportedStreamType
        }
        return response
    }
}

/// Server Gzip middlere:
/// 1. checks if the "Accept-Encoding" header contains "gzip"
/// 2. if so, compresses the body and sets the response header "Content-Encoding" to "gzip",
public struct GzipServerMiddleware: Middleware {
    
    public init() { }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        guard request.headers["Accept-Encoding"]?.contains("gzip") == true else {
            return try next.respond(to: request)
        }

        let response = try next.respond(to: request)
        response.headers["Content-Encoding"] = "gzip"
        
        let unzipped = response.body
        switch unzipped {
        case .data(let bytes):
            response.body = .data(Array(try Data(bytes: bytes).gzipCompressed()))
        default:
            //TODO: find out a way to compress chunks too
            throw GzipMiddlewareError.unsupportedStreamType
        }
        return response
    }
}
