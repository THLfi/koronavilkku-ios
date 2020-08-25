import Combine
import XCTest
@testable import Koronavilkku

struct MockBackend : Backend {
    var currentBatchId: CurrentBatchId
    var newBatchIds: BatchIds
    var batchFile: Data
    var exposureConfiguration: ExposureConfiguration
    
    func getCurrentBatchId() -> AnyPublisher<CurrentBatchId, Error> {
        createPublisher(value: currentBatchId)
    }
    
    func getNewBatchIds(since: String) -> AnyPublisher<BatchIds, Error> {
        createPublisher(value: newBatchIds)
    }
    
    func getBatchFile(id: String) -> AnyPublisher<Data, Error> {
        createPublisher(value: batchFile)
    }
    
    func getConfiguration() -> AnyPublisher<ExposureConfiguration, Error> {
        createPublisher(value: exposureConfiguration)
    }
    
    func postDiagnosisKeys(publishToken: String?,
                           publishRequest: DiagnosisPublishRequest,
                           isDummyRequest: Bool) -> AnyPublisher<Data, Error> {
        createPublisher(value: Data("".utf8))
    }
    
    private func createPublisher<T>(value: T) -> AnyPublisher<T, Error> {
        Just(value).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

class BatchRepositoryTest: XCTestCase {
}
