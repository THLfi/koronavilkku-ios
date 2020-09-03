import Foundation
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
