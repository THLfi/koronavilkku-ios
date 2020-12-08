import Combine
import UIKit

/// EFGS participating country
struct EFGSCountry: Codable {
    /// ISO 3166-1 alpha-2 region code
    let regionCode: String
    
    /// The country name in the current locale, or the region code as a fallback
    var localizedName: String {
        Locale.current.localizedString(forRegionCode: regionCode) ?? regionCode
    }
    
    /// Sanitize the input to accept only valid country codes
    static func create(from regionCode: String) -> EFGSCountry? {
        guard Locale.isoRegionCodes.contains(regionCode) else {
            return nil
        }

        return EFGSCountry(regionCode: regionCode)
    }
}

/// Repository for accessing the EFGS data
///
/// Initially contains only the methods to retrieve the list of participating countries
/// and a method to update the list.
///
/// We're choosing not to request the country list on demand when it needs to be presented
/// in the UI, because when combined with submitting the diagnosis keys, the network
/// signature would be unique and it could potentially identify someone having received a
/// positive COVID-19 diagnosis.
protocol EFGSRepository {
    func getParticipatingCountries() -> [EFGSCountry]?
    func updateCountryList() -> AnyPublisher<Bool, Never>
}

struct EFGSRepositoryImpl: EFGSRepository {
    static let countryListFile = "efgs-country-list"
    
    let exposureRepository: ExposureRepository
    let storage: FileStorage
    
    func getParticipatingCountries() -> [EFGSCountry]? {
        storage.read(from: Self.countryListFile)
    }
    
    func updateCountryList() -> AnyPublisher<Bool, Never> {
        exposureRepository
            .getConfiguration()
            .map { config in
                let countryList = config.participatingCountries.compactMap { regionCode in
                    EFGSCountry.create(from: regionCode)
                }
                
                return storage.write(object: countryList, to: Self.countryListFile)
            }
            .catch { _ in
                Just(false)
            }
            .eraseToAnyPublisher()
    }
}
