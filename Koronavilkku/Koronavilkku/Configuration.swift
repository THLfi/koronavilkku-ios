import Foundation
import TrustKit

protocol Configuration {
    typealias TrustKitConfiguration = [String: Any]

    var apiBaseURL: String { get }
    var cmsBaseURL: String { get }
    var omaoloBaseURL: String { get }
    var trustKit: TrustKitConfiguration? { get }
    var version: String { get }
}

class LocalConfiguration : Configuration {
    let apiBaseURL: String
    let cmsBaseURL: String
    let omaoloBaseURL: String
    let trustKit: TrustKitConfiguration?
    let version: String
    
    init() {
        var proto, base: String
        
        proto = LocalConfiguration.getValue(key: "API_USE_HTTPS") ? "https" : "http"
        base = LocalConfiguration.getValue(key: "API_BASEURL")
        apiBaseURL = "\(proto)://\(base)"
        
        proto = LocalConfiguration.getValue(key: "CMS_USE_HTTPS") ? "https" : "http"
        base = LocalConfiguration.getValue(key: "CMS_BASEURL")
        cmsBaseURL = "\(proto)://\(base)"
        
        omaoloBaseURL = LocalConfiguration.getValue(key: "OMAOLO_BASEURL")
        trustKit = LocalConfiguration.createTrustKitConfiguration()
        
        let versionName: String = LocalConfiguration.getValue(key: "CFBundleShortVersionString")
        let commitHash: String = LocalConfiguration.getValue(key: "GIT_COMMIT_HASH")
        let buildNumber: String = LocalConfiguration.getValue(key: "CFBundleVersion")
        version = "\(versionName)+\(commitHash.prefix(7)) (\(buildNumber))"
    }
}

extension LocalConfiguration {
    static func createTrustKitConfiguration() -> TrustKitConfiguration? {
        var domains = [String: Any]()
        
        if getValue(key: "API_USE_HTTPS") {
            domains[getValue(key: "API_BASEURL")] = [
                kTSKPublicKeyHashes: getValue(key: "API_TSK_HASHES") as [String],
                kTSKDisableDefaultReportUri: true,
            ]
        }
        
        return domains.count > 0 ? [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: domains,
        ] : nil
    }
    
    static func getValue<T>(key: String) -> T {
        if let value = getRawValue(key: key) as? T {
            return value
        }

        fatalError("Value for key \(key) is not a \(T.self)")
    }
    
    static func getValue<T>(key: String) -> T where T: LosslessStringConvertible {
        guard let string = getRawValue(key: key) as? String, let value = T(string) else {
            fatalError("Unable to convert value for key \(key) from string to \(T.self)")
        }

        return value
    }
    
    private static func getRawValue(key: String) -> Any {
        guard let obj = Bundle.main.object(forInfoDictionaryKey: key) else {
            fatalError("Unable to find plist value \(key)")
        }
        
        return obj
    }
}
