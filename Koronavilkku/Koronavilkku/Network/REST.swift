import Combine
import Foundation

protocol RestApi {
    associatedtype Resource : RestResource

    var baseURL: URL { get }
    var urlSession: URLSession { get }
}

let KVRestErrorDomain = "Koronavilkku.RestError"

enum RestError : Error {
    case unexpectedResponse
    case statusCode(Int)
    case invalidUrl
}

protocol RestResource {
    var path: String { get }
    var method: String { get }
    var headers: [String: String]? { get }
    func body() throws -> Data?
}

extension Encodable {
    func toJSON() throws -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

extension RestApi {
    
    func url(for path: String) -> URL {
        if path.isEmpty { return baseURL }
        return URL(string: path, relativeTo: baseURL)!
    }

    func call(endpoint resource: Resource) -> AnyPublisher<Data, Error> {
        do {
            let url = self.url(for: resource.path)
            Log.d("SEND \(resource.method) \(url.absoluteString)")
            var request = URLRequest(url: url)
            request.httpMethod = resource.method
            request.httpBody = try resource.body()
            
            resource.headers?.forEach { (key, value) in
                request.addValue(value, forHTTPHeaderField: key)
            }
            
            return urlSession.dataTaskPublisher(for: request).tryMap {
                if let statusCode = ($1 as? HTTPURLResponse)?.statusCode {
                    Log.d("RECV \(resource.method) \(url.absoluteString) (\(statusCode)): \(String(data: $0, encoding: .utf8) ?? "-")")
                    switch statusCode {
                    case 200 ..< 300:
                        return $0
                    default:
                        throw RestError.statusCode(statusCode)
                    }
                }
                
                Log.e("RECV \(resource.method) \(url.absoluteString): unexpected response")
                throw RestError.unexpectedResponse
            }.eraseToAnyPublisher()
        } catch {
            return Fail(outputType: Data.self, failure: error).eraseToAnyPublisher()
        }
    }

    func call<T>(endpoint resource: Resource) -> AnyPublisher<T, Error> where T: Decodable {
        return call(endpoint: resource).tryMap {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: $0)
        }.eraseToAnyPublisher()
    }
}
