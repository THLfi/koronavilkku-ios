import Foundation
import Combine

protocol Backend {
    func getCurrentBatchId() -> AnyPublisher<CurrentBatchId, Error>
    func getNewBatchIds(since: String) -> AnyPublisher<BatchIds, Error>
    func getBatchFile(id: String) -> AnyPublisher<Data, Error>
    func getConfiguration() -> AnyPublisher<ExposureConfiguration, Error>
    func postDiagnosisKeys(publishToken: String?,
                           publishRequest: DiagnosisPublishRequest,
                           isDummyRequest: Bool) -> AnyPublisher<Data, Error>
}

struct BackendRestApi : Backend, RestApi {
    typealias Resource = BackendEndpoint

    private var config: Configuration
    internal var urlSession: URLSession

    var baseURL: URL {
        get { URL(string: config.apiBaseURL)! }
    }

    init(config: Configuration, urlSession: URLSession) {
        self.config = config
        self.urlSession = urlSession
    }

    func getCurrentBatchId() -> AnyPublisher<CurrentBatchId, Error> {
        call(endpoint: .getCurrentBatchId)
    }
    
    func getNewBatchIds(since: String) -> AnyPublisher<BatchIds, Error> {
        call(endpoint: .getNewBatchIds(since: since))
    }
    
    func getBatchFile(id: String) -> AnyPublisher<Data, Error> {
        call(endpoint: .getBatchFile(id: id))
    }
    
    func getConfiguration() -> AnyPublisher<ExposureConfiguration, Error> {
        call(endpoint: .getConfiguration)
    }
    
    func postDiagnosisKeys(publishToken: String?,
                           publishRequest: DiagnosisPublishRequest,
                           isDummyRequest: Bool) -> AnyPublisher<Data, Error> {
        call(endpoint: .postDiagnosisKeys(publishToken: publishToken,
                                          publishRequest: publishRequest,
                                          isDummyRequest: isDummyRequest))
    }
}

enum BackendEndpoint : RestResource {
    case getCurrentBatchId
    case getNewBatchIds(since: String)
    case getBatchFile(id: String)
    case getConfiguration
    case postDiagnosisKeys(publishToken: String?, publishRequest: DiagnosisPublishRequest, isDummyRequest: Bool)

    var path: String {
        switch self {
        case .getCurrentBatchId:
            return "/diagnosis/v1/current"
        case .getNewBatchIds(let previousBatchId):
            return "/diagnosis/v1/list?previous=\(previousBatchId)"
        case .getBatchFile(let batchId):
            return "/diagnosis/v1/batch/\(batchId)"
        case .getConfiguration:
            return "/exposure/configuration/v2"
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
