import XCTest
@testable import Koronavilkku

class MunicipalityJsonTests: XCTestCase {
    
    enum AssertionError: Error {
        case municipalityServiceLanguageMissing(_ municipality: Municipality)
    }
    
    func testMunicipalitiesAccrodingToSchema() {
        let municipalities = loadData()
        XCTAssertNotNil(municipalities)
        XCTAssertGreaterThan(municipalities.count, 0)
        
        XCTAssertNoThrow(try municipalities.forEach { try assertMunicipality(municipality: $0) })
        
    }
    
    private func assertMunicipality(municipality: Municipality) throws {
        XCTAssertNotNil(municipality.code, "Code present")
        XCTAssertNotNil(municipality.name, "Name present")
        XCTAssertNotNil(municipality.contact, "Contact info present")
        XCTAssertGreaterThanOrEqual(municipality.contact.count, 0, "At least one contact")
        
        municipality.contact.forEach { contact in
            XCTAssertNotNil(contact.title, "Contact title present")
            XCTAssertNotNil(contact.phoneNumber, "Contact phone number present")
            XCTAssertNotNil(contact.info, "Contact info present")
            
            XCTAssertNotNil(contact.title.fi, "Finnish title present")
            XCTAssertNotNil(contact.info.fi, "Finnish info text present")
            
            // If Swedish title is given, require also Swedish info
            if let _ = contact.title.sv {
                XCTAssertNotNil(contact.info.sv, "\(municipality.name) has swedish contact title \(String(describing: contact.title.sv)) but no Swedish info")
            }
        }
        
        XCTAssertNotNil(municipality.omaolo, "Omaolo element present")
        
        if municipality.omaolo.available {
            // If Omaolo is available, service language info is required, for fi and sv
            XCTAssertNotNil(municipality.omaolo.serviceLanguages, "Service languages present")
            XCTAssertNotNil(municipality.omaolo.serviceLanguages?.fi)
            XCTAssertNotNil(municipality.omaolo.serviceLanguages?.sv)
        }
    }
    
    private func loadData() -> Municipalities {
        if let url = URL(string: "https://repo.thl.fi/sites/koronavilkku/yhteystiedot_uusi.json") {
            do {
                let data = try Data(contentsOf: url, options: .alwaysMapped)
                return try JSONDecoder()
                    .decode(Municipalities.self, from: data)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        else {
            fatalError("Unable to find test material from server")
        }
    }
}
