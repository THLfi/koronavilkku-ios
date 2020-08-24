
import Foundation
import Combine

protocol MunicipalityRepository {
    var omaoloBaseURL: String { get }

    func updateMunicipalityList() -> AnyPublisher<Bool, Error>
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
    let localFilename = "municipalities"
    
    internal let omaoloBaseURL: String

    private let cms: CMS
    private let fileHelper: FileHelper
    private var tasks = [AnyCancellable]()
    
    init(cms: CMS, omaoloBaseURL: String, fileHelper: FileHelper) {
        self.cms = cms
        self.omaoloBaseURL = omaoloBaseURL
        self.fileHelper = fileHelper
    }
    
    @discardableResult
    func updateMunicipalityList() -> AnyPublisher<Bool, Error> {
        return cms.call(endpoint: .getMunicipalityList)
            .tryMap({ (municipalities: Municipalities) in
                if let data = try? JSONEncoder().encode(municipalities) {
                    guard let _ = self.fileHelper.createFile(name: self.localFilename,
                                                             extension: "json",
                                                             data: data,
                                                             relativeTo: .municipalities) else {
                        throw MunicipalityError.storingLocalCopyFailed
                    }
                    Log.d("Municipality contact info written to \(self.localFilename)")
                } else {
                    throw MunicipalityError.storingLocalCopyFailed
                }
                return true
            }).catch({ _ in
                Just(false).setFailureType(to: Error.self)
            })
        .eraseToAnyPublisher()
    }
    
    func getMunicipalityList() -> AnyPublisher<Municipalities, Error> {
        return readFromFile()
            .catch({ _ in self.cms.call(endpoint: .getMunicipalityList) })
        .eraseToAnyPublisher()
    }
    
    private func readFromFile() -> AnyPublisher<Municipalities, Error> {
        do {
            guard let data = fileHelper.readFile(name: self.localFilename, extension: "json", relativeTo: .municipalities)
            else { throw MunicipalityError.loadingLocalCopyFailed }
            
            let municipalities = try JSONDecoder().decode(Municipalities.self, from: data)
            return Just(municipalities).setFailureType(to: Error.self).eraseToAnyPublisher()
            
        } catch {
            Log.d("Error reading from file \(error)")
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}

class FakeMunicipalityRepository : MunicipalityRepository {
    var omaoloBaseURL: String = "omaolo.invalid"
    
    func updateMunicipalityList() -> AnyPublisher<Bool, Error> {
        return Just(true).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getMunicipalityList() -> AnyPublisher<Municipalities, Error> {
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
