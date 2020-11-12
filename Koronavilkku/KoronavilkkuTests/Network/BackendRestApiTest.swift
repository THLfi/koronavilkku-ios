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
            XCTAssertEqual(request.url, URL(string: "http://mock/diagnosis/v1/current"))
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields, [:])
            XCTAssertEqual(request.readHttpBody(), nil)
        }, response: CurrentBatchId(current: "1000"), verifyResponse: { input, output in
            XCTAssertEqual(input.current, output.current)
        })

        testEndpoint(task: backend.getNewBatchIds(since: "123"), verifyRequest: { request in
            XCTAssertEqual(request.url, URL(string: "http://mock/diagnosis/v1/list?previous=123"))
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
            minimumRiskScore: 1,
            attenuationScores: [1, 2],
            daysSinceLastExposureScores: [4, 5],
            durationScores: [7, 8],
            transmissionRiskScores: [10, 11],
            durationAtAttenuationThresholds: [13, 14, 15],
            durationAtAttenuationWeights: [1.0, 0.5, 0.0],
            exposureRiskDuration: 16
        )

        testEndpoint(task: backend.getConfiguration(), verifyRequest: { request in
            XCTAssertEqual(request.url, URL(string: "http://mock/exposure/configuration/v1"))
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields, [:])
            XCTAssertEqual(request.readHttpBody(), nil)
        }, response: exposureConfiguration, verifyResponse: { input, output in
            XCTAssertEqual(input.minimumRiskScore, output.minimumRiskScore)
            XCTAssertEqual(input.attenuationScores, output.attenuationScores)
            XCTAssertEqual(input.daysSinceLastExposureScores, output.daysSinceLastExposureScores)
            XCTAssertEqual(input.durationScores, output.durationScores)
            XCTAssertEqual(input.transmissionRiskScores, output.transmissionRiskScores)
            XCTAssertEqual(input.durationAtAttenuationThresholds, output.durationAtAttenuationThresholds)
            XCTAssertEqual(input.durationAtAttenuationWeights, output.durationAtAttenuationWeights)
            XCTAssertEqual(input.exposureRiskDuration, output.exposureRiskDuration)
        })
        
        let diagnosisKeys = DiagnosisPublishRequest(keys: [])
        
        let uploadTask = backend.postDiagnosisKeys(publishToken: "789",
                                                   publishRequest: diagnosisKeys,
                                                   isDummyRequest: true)

        testEndpoint(task: uploadTask, verifyRequest: { request in
            XCTAssertEqual(request.url, URL(string: "http://mock/diagnosis/v1"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.allHTTPHeaderFields, [
                "KV-Fake-Request": "1",
                "Content-Length": "11",
                "KV-Publish-Token": "789",
                "Content-Type": "application/json; charset=utf-8",
            ])
            XCTAssertEqual(request.readHttpBody(), try! diagnosisKeys.toJSON())
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
