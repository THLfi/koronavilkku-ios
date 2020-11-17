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
    
    func testOmaoloServices() {
        let languages = ServiceLanguages(fi: true, sv: true, en: nil)
        
        let activeSymptomsOnly = Omaolo(available: true, serviceLanguages: languages, symptomAssessmentOnly: true)
        XCTAssertTrue(activeSymptomsOnly.available(service: .SymptomAssessment))
        XCTAssertFalse(activeSymptomsOnly.available(service: .ContactRequest))
        XCTAssertEqual(activeSymptomsOnly.supportedServiceLanguageIdentifiers(), ["fi", "sv"])

        let activeAllServices = Omaolo(available: true, serviceLanguages: languages, symptomAssessmentOnly: false)
        XCTAssertTrue(activeAllServices.available(service: .SymptomAssessment))
        XCTAssertTrue(activeAllServices.available(service: .ContactRequest))

        let activeUnknownServices = Omaolo(available: true, serviceLanguages: languages, symptomAssessmentOnly: nil)
        XCTAssertTrue(activeUnknownServices.available(service: .SymptomAssessment))
        XCTAssertTrue(activeUnknownServices.available(service: .ContactRequest))

        let inactiveSymptomsOnly = Omaolo(available: false, serviceLanguages: languages, symptomAssessmentOnly: true)
        XCTAssertFalse(inactiveSymptomsOnly.available(service: .SymptomAssessment))
        XCTAssertFalse(inactiveSymptomsOnly.available(service: .ContactRequest))

        let inactiveAllServices = Omaolo(available: false, serviceLanguages: languages, symptomAssessmentOnly: false)
        XCTAssertFalse(inactiveAllServices.available(service: .SymptomAssessment))
        XCTAssertFalse(inactiveAllServices.available(service: .ContactRequest))

        let inactiveUnknownServices = Omaolo(available: false, serviceLanguages: languages, symptomAssessmentOnly: nil)
        XCTAssertFalse(inactiveUnknownServices.available(service: .SymptomAssessment))
        XCTAssertFalse(inactiveUnknownServices.available(service: .ContactRequest))
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
                XCTAssertNotNil(contact.info.sv, "\(municipality.name) has Swedish contact title \(String(describing: contact.title.sv)) but no Swedish info")
            }

            // If English title is given, require also English info
            if let _ = contact.title.en {
                XCTAssertNotNil(contact.info.en, "\(municipality.name) has English contact title \(String(describing: contact.title.en)) but no English info")
            }
        }
        
        XCTAssertNotNil(municipality.omaolo, "Omaolo element present")
        
        for service in Omaolo.Service.allCases {
            if municipality.omaolo.available(service: service) {
                XCTAssertGreaterThan(municipality.omaolo.supportedServiceLanguageIdentifiers().count,
                                     0,
                                     "At least one service language must be selected when Omaolo services are active")
            }
        }
    }
}
