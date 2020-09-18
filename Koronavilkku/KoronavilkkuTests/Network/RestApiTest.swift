import Combine
import XCTest
@testable import Koronavilkku

class RestApiTest : XCTestCase {
    var tasks = [AnyCancellable]()
    let api = MockApi()

    func testURLGeneration() {
        testEndpoint(endpoint: .staticGetNoHeaders,
                     expectedValue: "http://mock/static/path",
                     requestHandler: URLRequest.extractUrl)
        
        testEndpoint(endpoint: .pathVariablePostWithHeader(pathVar: 123),
                     expectedValue: "http://mock/path/123/variable",
                     requestHandler: URLRequest.extractUrl)
        
        testEndpoint(endpoint: .queryStringPutUpload(queryStringParam: "456"),
                     expectedValue: "http://mock/upload/path?param=456",
                     requestHandler: URLRequest.extractUrl)
    }
    
    func testHeaderGeneration() {
        // no headers
        testEndpoint(endpoint: .staticGetNoHeaders,
                     expectedValue: [:],
                     requestHandler: URLRequest.extractHeaders)
        
        // has custom headers
        testEndpoint(endpoint: .pathVariablePostWithHeader(pathVar: 789),
                     expectedValue: ["Custom-Header": "Value"],
                     requestHandler: URLRequest.extractHeaders)
        
        // implied headers due to request payload
        testEndpoint(endpoint: .queryStringPutUpload(queryStringParam: "foo"),
                     expectedValue: ["Content-Length": "6"],
                     requestHandler: URLRequest.extractHeaders)
    }
    
    func testMethodGeneration() {
        testEndpoint(endpoint: .staticGetNoHeaders,
                     expectedValue: "GET",
                     requestHandler: URLRequest.extractMethod)
        
        testEndpoint(endpoint: .pathVariablePostWithHeader(pathVar: 42),
                     expectedValue: "POST",
                     requestHandler: URLRequest.extractMethod)
        
        testEndpoint(endpoint: .queryStringPutUpload(queryStringParam: "bar"),
                     expectedValue: "PUT",
                     requestHandler: URLRequest.extractMethod)
    }
    
    func testBodyGeneration() {
        testEndpoint(endpoint: .staticGetNoHeaders,
                     expectedValue: nil,
                     requestHandler: URLRequest.extractBody)
        
        testEndpoint(endpoint: .pathVariablePostWithHeader(pathVar: 73),
                     expectedValue: nil,
                     requestHandler: URLRequest.extractBody)
        
        testEndpoint(endpoint: .queryStringPutUpload(queryStringParam: "baz"),
                     expectedValue: "upload".data(using: .utf8),
                     requestHandler: URLRequest.extractBody)
    }

    func testStatusCodeHandling() {
        testStatusCode(statusCode: 200, shouldFail: false)
        testStatusCode(statusCode: 201, shouldFail: false)
        testStatusCode(statusCode: 300, shouldFail: true)
        testStatusCode(statusCode: 304, shouldFail: true)
        testStatusCode(statusCode: 400, shouldFail: true)
        testStatusCode(statusCode: 404, shouldFail: true)
        testStatusCode(statusCode: 500, shouldFail: true)
    }
    
    func testJSONConversion() {
        let expectation1 = self.expectation(description: "Successful conversion")
        
        MockURLProtocol.requestHandler = { request in
            MockResponse(body: Data("[\"foo\"\n,\"bar\"]".utf8))
        }

        api.call(endpoint: .staticGetNoHeaders)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    XCTFail(error.localizedDescription)
                }
                
                expectation1.fulfill()
            }, receiveValue: { (list: [String]) in
                XCTAssertEqual(["foo", "bar"], list)
            })
            .store(in: &tasks)

        wait(for: [expectation1], timeout: 5)
        
        let expectation2 = self.expectation(description: "Successful conversion")
        
        MockURLProtocol.requestHandler = { request in
            MockResponse(body: Data("[\"foo\n,\"bar\"]".utf8))
        }

        api.call(endpoint: .staticGetNoHeaders)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    XCTAssert(error is DecodingError)
                } else {
                    XCTFail("Conversion should fail")
                }
                
                expectation2.fulfill()
            }, receiveValue: { (list: [String]) in
                XCTFail("This should never happen, but this is needed for type inference")
            })
            .store(in: &tasks)

        wait(for: [expectation2], timeout: 5)
    }
    
    private func testEndpoint<T: Equatable>(endpoint: MockApi.Endpoint,
                                            expectedValue: T,
                                            requestHandler: @escaping (URLRequest) -> T) {
        let expectation = self.expectation(description: endpoint.path)
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(requestHandler(request), expectedValue)
            expectation.fulfill()
            return nil
        }
        
        api.call(endpoint: endpoint).sink(receiveCompletion: { _ in }, receiveValue: { _ in }).store(in: &tasks)
        
        wait(for: [expectation], timeout: 5)
    }
    
    private func testStatusCode(statusCode: Int, shouldFail: Bool) {
        let expectation = self.expectation(description: "Status code \(statusCode)")

        MockURLProtocol.requestHandler = { request in
            MockResponse(statusCode: statusCode, body: Data("".utf8))
        }

        api.call(endpoint: .staticGetNoHeaders)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    if !shouldFail {
                        XCTFail(error.localizedDescription)
                    } else if case Koronavilkku.RestError.statusCode(let status) = error {
                        XCTAssertEqual(status, statusCode)
                    }
                } else if shouldFail {
                    XCTFail("Request should fail with RestError.statusCode")
                }

                expectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &tasks)

        wait(for: [expectation], timeout: 5)
    }
}
