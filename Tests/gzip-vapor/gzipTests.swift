import XCTest
import Foundation
import Vapor
import HTTP
import Transport
@testable import gzip_vapor

class gzipTests: XCTestCase {

    struct TestResponder: Responder {
        let response: Response
        func respond(to request: Request) throws -> Response {
            return response
        }
    }
    
    let zippedString = "H4sIAAAAAAAAA8tIzcnJVyjPL8pJUcggmp1aVJSUn1IJAISpv6M9AAAA"
    let zippedData = Data(base64Encoded: "H4sIAAAAAAAAA8tIzcnJVyjPL8pJUcggmp1aVJSUn1IJAISpv6M9AAAA")!
    let unzippedData = "hello world hello world hello world hello world hello errbody".data(using: .utf8)!
    let unzippedString = "hello world hello world hello world hello world hello errbody"
    
    func testClient_setsHeaderAndUncompresses_zippedResponse() throws {
        
        let middleware = GzipClientMiddleware()
        
        let req = try Request(method: .get, uri: "http://hello.com")
        let cannedResponse = Response(headers: ["Content-Encoding":"gzip"], body: zippedData)
        let responder = TestResponder(response: cannedResponse)
        let response = try middleware.respond(to: req, chainingTo: responder)
        XCTAssertEqual(req.headers["Accept-Encoding"], "gzip")

        let responseString = (response.body.bytes ?? []).string
        XCTAssertEqual(responseString, unzippedString)
    }
    
    func testClient_setsHeaderAndIgnores_plainResponse() throws {
        
        let middleware = GzipClientMiddleware()
        
        let req = try Request(method: .get, uri: "http://hello.com")
        let cannedResponse = Response(headers: [:], body: unzippedData)
        let responder = TestResponder(response: cannedResponse)
        let response = try middleware.respond(to: req, chainingTo: responder)
        XCTAssertEqual(req.headers["Accept-Encoding"], "gzip")

        let responseString = (response.body.bytes ?? []).string
        XCTAssertEqual(responseString, unzippedString)
    }

    func testServer_setsHeaderAndCompresses_gzipRequest() throws {
        
        let middleware = GzipServerMiddleware()
        
        let req = try Request(method: .get, uri: "http://hello.com")
        req.headers["Accept-Encoding"] = "gzip, deflate"
        let cannedResponse = Response(body: unzippedData)
        let responder = TestResponder(response: cannedResponse)
        let response = try middleware.respond(to: req, chainingTo: responder)
        
        let responseString = (response.body.bytes ?? []).base64String
        XCTAssertEqual(responseString, zippedString)
        XCTAssertEqual(response.headers["Content-Encoding"], "gzip")
    }
    
    func testServer_noHeaderAndIgnores_plainRequest() throws {
        
        let middleware = GzipServerMiddleware()
        
        let req = try Request(method: .get, uri: "http://hello.com")
        let cannedResponse = Response(body: unzippedData)
        let responder = TestResponder(response: cannedResponse)
        let response = try middleware.respond(to: req, chainingTo: responder)
        
        let responseString = (response.body.bytes ?? []).string
        XCTAssertEqual(responseString, unzippedString)
        XCTAssertNil(response.headers["Content-Encoding"])
    }
    
    func testStream_compress_receive() throws {
        let raw = TestStream()
        try raw.send(unzippedString)
        let stream = try GzipStream(mode: .compress, stream: raw)
        let bytes = try stream.receive(max: 2048)
        try stream.close()
        let responseString = bytes.base64String
        XCTAssertEqual(responseString, zippedString)
    }
    
    func testStream_compress_send() throws {
        let raw = TestStream()
        let stream = try GzipStream(mode: .compress, stream: raw)
        try stream.send(unzippedString)
        try stream.close()
        let responseString = raw.buffer.base64String
        XCTAssertEqual(responseString, zippedString)
    }

    func testStream_uncompress_receive() throws {
        let raw = TestStream()
        try raw.send(zippedString)
        try raw.close()
        let stream = try GzipStream(mode: .uncompress, stream: raw)
        let bytes = try stream.receive(max: 2048)
        try stream.close()
        let responseString = bytes.string
        XCTAssertEqual(responseString, unzippedString)
    }
    
    func testStream_uncompress_send() throws {
        let raw = TestStream()
        let stream = try GzipStream(mode: .uncompress, stream: raw)
        try stream.send(zippedString)
        try stream.close()
        let responseString = raw.buffer.string
        XCTAssertEqual(responseString, unzippedString)
    }
}

//from Vapor.Transport tests
final class TestStream: Transport.Stream {
    var closed: Bool
    var buffer: Bytes
    var timeout: Double = -1
    // number of times flush was called
    var flushedCount = 0
    
    func setTimeout(_ timeout: Double) throws {
        self.timeout = timeout
    }
    
    init() {
        closed = false
        buffer = []
    }
    
    func close() throws {
        if !closed {
            closed = true
        }
    }
    
    func send(_ bytes: Bytes) throws {
        closed = false
        buffer += bytes
    }
    
    func flush() throws {
        flushedCount += 1
    }
    
    func receive(max: Int) throws -> Bytes {
        if buffer.count == 0 {
            try close()
            return []
        }
        
        if max >= buffer.count {
            try close()
            let data = buffer
            buffer = []
            return data
        }
        
        let data = buffer[0..<max]
        buffer.removeFirst(max)
        
        return Bytes(data)
    }
}

extension String {
    func toData() -> Foundation.Data {
        return self.data(using: String.Encoding.utf8) ?? Foundation.Data()
    }
}

extension Foundation.Data {
    func toString() -> String {
        return String(data: self, encoding: String.Encoding.utf8) ?? ""
    }
}

extension gzipTests {
    static var allTests = [
        ("testClient_setsHeaderAndUncompresses_zippedResponse", testClient_setsHeaderAndUncompresses_zippedResponse),
        ("testClient_setsHeaderAndIgnores_plainResponse", testClient_setsHeaderAndIgnores_plainResponse),
        ("testServer_setsHeaderAndCompresses_gzipRequest", testServer_setsHeaderAndCompresses_gzipRequest),
        ("testServer_noHeaderAndIgnores_plainRequest", testServer_noHeaderAndIgnores_plainRequest)
    ]
}
