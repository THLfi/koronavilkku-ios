import Combine
@testable import Koronavilkku

struct MockEFGSRepository : EFGSRepository {
    var participatingCountries: Set<EFGSCountry>?
    
    func getParticipatingCountries() -> Set<EFGSCountry>? {
        participatingCountries
    }
    
    func updateCountryList() -> AnyPublisher<Bool, Never> {
        return Just(true).eraseToAnyPublisher()
    }
}
