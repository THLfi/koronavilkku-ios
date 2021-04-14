import Combine
import XCTest
@testable import Koronavilkku

class BackendRestApiTest : XCTestCase {
    var tasks = [AnyCancellable]()
    let config = MockConfiguration()
    var urlSession: URLSession!
    
    override func setUp() {
        let urlSessionConfig = URLSessionConfiguration.ephemeral
        urlSessionConfig.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: urlSessionConfig)
    }
    
    func testEndpoints() {
        let backend = BackendRestApi(config: config, urlSession: urlSession)

        testEndpoint(task: backend.getCurrentBatchId(), verifyRequest: { request in
            XCTAssertEqual(request.url, URL(string: "http://mock/diagnosis/v1/current?en-api-version=2"))
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields, [:])
            XCTAssertEqual(request.readHttpBody(), nil)
        }, response: CurrentBatchId(current: "1000"), verifyResponse: { input, output in
            XCTAssertEqual(input.current, output.current)
        })

        testEndpoint(task: backend.getNewBatchIds(since: "123"), verifyRequest: { request in
            XCTAssertEqual(request.url, URL(string: "http://mock/diagnosis/v1/list?en-api-version=2&previous=123"))
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields, [:])
            XCTAssertEqual(request.readHttpBody(), nil)
        }, response: BatchIds(batches: ["1001", "1002"]), verifyResponse: { input, output in
            XCTAssertEqual(input.batches, output.batches)
        })

        testEndpoint(task: backend.getBatchFile(id: "456"), verifyRequest: { request in
            XCTAssertEqual(request.url, URL(string: "http://mock/diagnosis/v1/batch/456"))
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields, [:])
            XCTAssertEqual(request.readHttpBody(), nil)
        }, response: Data("batch-contents".utf8), verifyResponse: { input, output in
            XCTAssertEqual(input, output)
        })
        
        let exposureConfiguration = ExposureConfiguration(
            version: 1,
            reportTypeWeightConfirmedTest: 1.2,
            reportTypeWeightConfirmedClinicalDiagnosis: 1.3,
            reportTypeWeightSelfReport: 1.4,
            reportTypeWeightRecursive: 1.5,
            infectiousnessWeightStandard: 2.1,
            infectiousnessWeightHigh: 2.2,
            attenuationBucketThresholdDb: [60, 70, 80],
            attenuationBucketWeights: [4.0, 3.0, 2.0, 1.0],
            daysSinceExposureThreshold: 9,
            minimumWindowScore: 10.0,
            minimumDailyScore: 11,
            daysSinceOnsetToInfectiousness: [
                "-14": "NONE", "-13": "NONE", "-12": "NONE", "-11": "NONE", "-10": "NONE", "-9": "NONE", "-8": "NONE", "-7": "NONE", "-6": "NONE", "-5": "NONE", "-4": "NONE", "-3": "NONE", "-2": "NONE", "-1": "HIGH", "0": "HIGH", "1": "HIGH", "2": "HIGH", "3": "STANDARD", "4": "STANDARD", "5": "STANDARD", "6": "NONE", "7": "NONE", "8": "NONE", "9": "NONE", "10": "NONE", "11": "NONE", "12": "NONE", "13": "NONE", "14": "STANDARD",
            ],
            availableCountries: ["DE", "EE", "FI"]
        )
        
        testEndpoint(task: backend.getConfiguration(), verifyRequest: { request in
            XCTAssertEqual(request.url, URL(string: "http://mock/exposure/configuration/v2"))
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields, [:])
            XCTAssertEqual(request.readHttpBody(), nil)
        }, response: exposureConfiguration, verifyResponse: { input, output in
            XCTAssertEqual(input.version, output.version)
            XCTAssertEqual(input.reportTypeWeightConfirmedTest, output.reportTypeWeightConfirmedTest)
            XCTAssertEqual(input.reportTypeWeightConfirmedClinicalDiagnosis, output.reportTypeWeightConfirmedClinicalDiagnosis)
            XCTAssertEqual(input.reportTypeWeightSelfReport, output.reportTypeWeightSelfReport)
            XCTAssertEqual(input.reportTypeWeightRecursive, output.reportTypeWeightRecursive)
            XCTAssertEqual(input.infectiousnessWeightStandard, output.infectiousnessWeightStandard)
            XCTAssertEqual(input.infectiousnessWeightHigh, output.infectiousnessWeightHigh)
            XCTAssertEqual(input.attenuationBucketThresholdDb, output.attenuationBucketThresholdDb)
            XCTAssertEqual(input.attenuationBucketWeights, output.attenuationBucketWeights)
            XCTAssertEqual(input.daysSinceExposureThreshold, output.daysSinceExposureThreshold)
            XCTAssertEqual(input.minimumWindowScore, output.minimumWindowScore)
            XCTAssertEqual(input.minimumDailyScore, output.minimumDailyScore)
            XCTAssertEqual(input.daysSinceOnsetToInfectiousness, output.daysSinceOnsetToInfectiousness)
            XCTAssertEqual(input.availableCountries, output.availableCountries)
        })
        
        let diagnosisKeys = DiagnosisPublishRequest(keys: [], visitedCountries: ["EE": 1, "DE": 0], consentToShareWithEfgs: 1)
        
        let uploadTask = backend.postDiagnosisKeys(publishToken: "789",
                                                   publishRequest: diagnosisKeys,
                                                   isDummyRequest: true)

        testEndpoint(task: uploadTask, verifyRequest: { request in
            XCTAssertEqual(request.url, URL(string: "http://mock/diagnosis/v1"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.allHTTPHeaderFields, [
                "KV-Fake-Request": "1",
                "Content-Length": "73",
                "KV-Publish-Token": "789",
                "Content-Type": "application/json; charset=utf-8",
            ])
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            XCTAssertEqual(
                try! decoder.decode(DiagnosisPublishRequest.self, from: request.readHttpBody()!),
                diagnosisKeys,
                "The decoded body should equal to the encoded payload")
            
            
        }, response: Data("".utf8), verifyResponse: { input, output in
            XCTAssertEqual(input, output)
        })
    }
    
    func testEndpoint<Output, Input: Encodable>(task: AnyPublisher<Output, Error>,
                                                verifyRequest: @escaping (URLRequest) -> Void,
                                                response: Input,
                                                verifyResponse: @escaping (Input, Output) -> Void) {
        
        let expectation = self.expectation(description: task.description)

        MockURLProtocol.requestHandler = { request in
            verifyRequest(request)
            
            if let response = response as? Data {
                return MockResponse(body: response)
            }
            
            return try MockResponse(object: response)
        }
        
        task.sink(receiveCompletion: { status in
            if case .failure(let error) = status {
                XCTFail(error.localizedDescription)
            }
            
            expectation.fulfill()
        }, receiveValue: { value in
            verifyResponse(response, value)
        }).store(in: &tasks)
        
        wait(for: [expectation], timeout: 5)
    }
}
