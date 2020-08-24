import Foundation
import Combine

struct Backend : RestApi {
    typealias Resource = API
    private var config: Configuration
    internal var urlSession: URLSession

    init(config: Configuration, urlSession: URLSession) {
        self.config = config
        self.urlSession = urlSession
    }

    enum API {
        case getCurrentBatchId
        case getNewBatchIds(since: String)
        case getBatchFile(id: String)
        case getConfiguration
        case postDiagnosisKeys(publishToken: String?, publishRequest: DiagnosisPublishRequest, isDummyRequest: Bool)
    }

    var baseURL: URL {
        get { URL(string: config.apiBaseURL)! }
    }
}

extension Backend.API : RestResource {
    var path: String {
        switch self {
        case .getCurrentBatchId:
            return "/diagnosis/v1/current"
        case .getNewBatchIds(let previousBatchId):
            return "/diagnosis/v1/list?previous=\(previousBatchId)"
        case .getBatchFile(let batchId):
            return "/diagnosis/v1/batch/\(batchId)"
        case .getConfiguration:
            return "/exposure/configuration/v1"
        case .postDiagnosisKeys:
            return "/diagnosis/v1"
        }
    }
    
    var method: String {
        switch self {
        case .postDiagnosisKeys:
            return "POST"
        default:
            return "GET"
        }
    }
    
    var headers: [String: String]? {
        switch self {
         case .postDiagnosisKeys(let publishToken, _, let dummyToken):
            var headers = [
                "Content-type": "application/json; charset=utf-8",
                "KV-Fake-Request": dummyToken ? "1" : "0",
            ]
            if let publishToken = publishToken, !publishToken.isEmpty {
                // TODO: Remove this when correct header is deployed
                headers["KH-Publish-Token"] = publishToken
                headers["KV-Publish-Token"] = publishToken
            }
            return headers
        default:
            return nil
        }
    }
    
    func body() throws -> Data? {
        switch self {
        case .postDiagnosisKeys(_, let publishRequest, _):
            return try publishRequest.toJSON()
        default:
            return nil
        }
    }
}
