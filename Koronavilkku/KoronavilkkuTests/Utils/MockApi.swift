import Foundation
@testable import Koronavilkku

struct MockApi : RestApi {
    var baseURL = URL(string: "http://mock")!
    let urlSession = URLSession.mocked

    typealias Resource = Endpoint
    
    enum Endpoint {
        case staticGetNoHeaders
        case pathVariablePostWithHeader(pathVar: Int)
        case queryStringPutUpload(queryStringParam: String)
    }
}

extension MockApi.Endpoint : RestResource {
    var path: String {
        switch self {
        case .staticGetNoHeaders:
            return "/static/path"
        case .pathVariablePostWithHeader(let pathVar):
            return "/path/\(pathVar)/variable"
        case .queryStringPutUpload(let queryStringParam):
            return "/upload/path?param=\(queryStringParam)"
        }
    }
    
    var method: String {
        switch self {
        case .pathVariablePostWithHeader:
            return "POST"
        case .queryStringPutUpload:
            return "PUT"
        default:
            return "GET"
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .pathVariablePostWithHeader:
            return ["Custom-Header": "Value"]
        default:
            return [:]
        }
    }
    
    func body() throws -> Data? {
        switch self {
        case .queryStringPutUpload:
            return "upload".data(using: .utf8)
        default:
            return nil
        }
    }
}
