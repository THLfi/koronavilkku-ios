import Foundation

struct CMS: RestApi {
    typealias Resource = API
    
    private var config: Configuration
    internal var urlSession: URLSession

    init(config: Configuration, urlSession: URLSession) {
        self.config = config
        self.urlSession = urlSession
    }
    
    enum API {
        case getMunicipalityList
    }
    
    var baseURL: URL {
        get { URL(string: config.cmsBaseURL)! }
    }
}

extension CMS.API: RestResource {
    var path: String {
        switch self {
        case .getMunicipalityList:
            return "/sites/koronavilkku/yhteystiedot.json"
        }
    }
    var method: String {
        "GET"
    }
    
    var headers: [String : String]? {
        ["Accept": "application/json; charset=utf-8"]
    }
    
    func body() throws -> Data? {
        nil
    }
}
