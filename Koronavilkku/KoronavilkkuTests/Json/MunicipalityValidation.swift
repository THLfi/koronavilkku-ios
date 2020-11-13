import XCTest
@testable import Koronavilkku

struct Endpoint : RestResource {
    var path: String
    var method = "GET"
    var headers: [String : String]? = nil
    func body() throws -> Data? { nil }
}

struct MockCMS : RestApi {
    typealias Resource = Endpoint

    var baseURL: URL
    var urlSession: URLSession
}

class MunicipalityJsonTests: XCTestCase {
    
    enum AssertionError: Error {
        case municipalityServiceLanguageMissing(_ municipality: Municipality)
    }
    
    private var cms: MockCMS!
    
    override func setUp() {
        let config = LocalConfiguration()
        cms = MockCMS(baseURL: URL(string: config.cmsBaseURL)!, urlSession: URLSession.shared)
    }
    
    func testProductionData() throws {
        let production = Endpoint(path: "/sites/koronavilkku/yhteystiedot.json")
        let result: Result<Municipalities, Error> = call(api: cms, endpoint: production, timeout: 5)

        switch result {
        case .failure(let error):
            throw error
        case .success(let data):
            try testMunicipalityData(data: data)
        }
    }
    
    func testStagingData() throws {
        let staging = Endpoint(path: "/sites/koronavilkku/yhteystiedot_uusi.json")
        let result: Result<Municipalities, Error> = call(api: cms, endpoint: staging, timeout: 5)
        
        switch result {
        case .failure(let error):
            throw XCTSkip(error.localizedDescription)
        case .success(let data):
            try testMunicipalityData(data: data)
        }
    }
    
    private func testMunicipalityData(data municipalities: Municipalities) throws {

        XCTAssertNotNil(municipalities)
        XCTAssertGreaterThan(municipalities.count, 0)
        
        XCTAssertNoThrow(try municipalities.forEach {
            try assertMunicipality(municipality: $0)
        })

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
}
