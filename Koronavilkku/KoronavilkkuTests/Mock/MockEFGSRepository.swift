import Combine
@testable import Koronavilkku

struct MockEFGSRepository : EFGSRepository {
    var participatingCountries: Set<EFGSCountry>?
    
    func getParticipatingCountries() -> Set<EFGSCountry>? {
        participatingCountries
    }
    
    func updateCountryList(from: ExposureConfiguration) {
    }
}
