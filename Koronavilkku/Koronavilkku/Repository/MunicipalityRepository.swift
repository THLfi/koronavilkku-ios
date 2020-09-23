
import Foundation
import Combine

protocol MunicipalityRepository {
    var omaoloBaseURL: String { get }

    func updateMunicipalityList() -> AnyPublisher<Void, Error>
    func getMunicipalityList() -> AnyPublisher<Municipalities, Error>
    func getOmaoloLink(for: OmaoloTarget, in: Municipality, language: String) -> URL
}

extension MunicipalityRepository {
    func getOmaoloLink(for target: OmaoloTarget, in municipality: Municipality, language: String) -> URL {
        return target.url(baseURL: omaoloBaseURL, in: municipality, language: language)
    }
}

enum MunicipalityError: Error {
    case readingListFailed
    case storingLocalCopyFailed
    case loadingLocalCopyFailed
}

class MunicipalityRepositoryImpl: MunicipalityRepository {
    internal let omaoloBaseURL: String

    private let cms: CMS
    private let storage: FileStorage
    private var tasks = [AnyCancellable]()

    let localFilename = "municipalities"

    init(cms: CMS, omaoloBaseURL: String, storage: FileStorage) {
        self.cms = cms
        self.omaoloBaseURL = omaoloBaseURL
        self.storage = storage
    }
    
    func updateMunicipalityList() -> AnyPublisher<Void, Error> {
        return cms.call(endpoint: .getMunicipalityList).tryMap { (municipalities: Municipalities) in
            if !self.storage.write(object: municipalities, to: self.localFilename) {
                throw MunicipalityError.storingLocalCopyFailed
            }
        }.eraseToAnyPublisher()
    }
    
    func getMunicipalityList() -> AnyPublisher<Municipalities, Error> {
        return readFromFile().catch { _ in
            self.cms.call(endpoint: .getMunicipalityList)
        }.eraseToAnyPublisher()
    }
    
    private func readFromFile() -> AnyPublisher<Municipalities, Error> {
        guard let municipalities: Municipalities = storage.read(from: localFilename) else {
            Log.d("Error reading from file \(localFilename)")
            return Fail(error: MunicipalityError.loadingLocalCopyFailed).eraseToAnyPublisher()
        }

        return Just(municipalities).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
