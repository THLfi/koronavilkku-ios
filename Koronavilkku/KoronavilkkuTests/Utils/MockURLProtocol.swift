import XCTest
@testable import Koronavilkku

struct MockConfiguration : Configuration {
    var apiBaseURL: String = "http://mock"
    var cmsBaseURL: String = ""
    var omaoloBaseURL: String = ""
    var trustKit: TrustKitConfiguration? = nil
    var version: String = ""
}

struct MockResponse {
    var statusCode: Int = 200
    var body: Data
}

extension MockResponse {
    init<T: Encodable>(object: T) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        body = try encoder.encode(object)
    }
}

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> MockResponse?)?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received unexpected request with no handler set")
            return
        }
        
        do {
            guard
                let response = try handler(request),
                let url = request.url,
                let httpResponse = HTTPURLResponse(url: url, statusCode: response.statusCode, httpVersion: nil, headerFields: nil)
            else {
                throw URLError(.badServerResponse)
            }

            client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: response.body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}

