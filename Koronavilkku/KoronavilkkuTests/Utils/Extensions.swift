import Combine
import Foundation
import XCTest
@testable import Koronavilkku

extension URLRequest {
    static let extractUrl: (Self) -> String? = { $0.url?.absoluteString }
    static let extractHeaders: (Self) -> [String : String]? = { $0.allHTTPHeaderFields }
    static let extractMethod: (Self) -> String? = { $0.httpMethod }
    static let extractBody: (Self) -> Data? = { $0.readHttpBody() }
    
    func readHttpBody() -> Data? {
        guard let stream = httpBodyStream else {
            return nil
        }
        
        stream.open()
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: 8)
            data.append(buffer, count: read)
        }
        
        buffer.deallocate()
        stream.close()
        return data
    }
}

extension URLSession {
    static let mocked: URLSession = {
        let urlSessionConfig = URLSessionConfiguration.ephemeral
        urlSessionConfig.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: urlSessionConfig)
    }()
}

extension XCTestCase {
    enum RestApiError : Error {
        case timeout
        case http(originatingError: Error)
        case unknown
    }

    func call<R: RestApi, T: Decodable>(api: R, endpoint: R.Resource, timeout: TimeInterval) -> Result<T, Error> {
        Result {
            let loadExpectation = expectation(description: String(describing: endpoint))
            var tasks = Set<AnyCancellable>()
            var data: T?
            var loadingError: Error?

            api.call(endpoint: endpoint)
                .sink { result in
                    if case .failure(let error) = result {
                        loadingError = error
                    }
                    
                    loadExpectation.fulfill()
                } receiveValue: { (input: T) in
                    data = input
                }
                .store(in: &tasks)
            
            let wait = XCTWaiter.wait(for: [loadExpectation], timeout: timeout)
            
            if case .timedOut = wait {
                throw RestApiError.timeout
            }
            
            if let loadingError = loadingError {
                throw RestApiError.http(originatingError: loadingError)
            }
            
            if let data = data {
                return data
            }
            
            throw RestApiError.unknown
        }
    }
}
