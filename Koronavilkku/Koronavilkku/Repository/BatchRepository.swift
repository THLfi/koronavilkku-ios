import Combine
import Foundation

struct DiagnosisPublishRequest : Encodable {
    let keys: [TemporaryExposureKey]
    
    /// Temporary static values for E2E testing
    /// - Important: These will be replaced with the actual user selected values after the feature has been implemented
    let visitedCountries: [String: Int] = ["DE": 1, "DK": 1, "LV": 0, "IT": 0, "IE": 0, "ES": 0]
    let consentToShareWithEfgs: Int = 1
}

protocol BatchRepository {
    func getNewBatches() -> AnyPublisher<String, Error>
    func getCurrentBatchId() -> AnyPublisher<String, Error>
}

protocol BatchIdCache {
    var nextDiagnosisKeyFileIndex: String? { get set }
}

enum BatchError: Error {
    case writingZipFailed
    case unzippingFailed
    case noFilesFound
}

class BatchRepositoryImpl: BatchRepository {
    private let backend: Backend
    private var cache: BatchIdCache
    private let storage: FileStorage
    
    init(backend: Backend, cache: BatchIdCache, storage: FileStorage) {
        self.backend = backend
        self.cache = cache
        self.storage = storage
    }

    func getNewBatches() -> AnyPublisher<String, Error> {
        return getCurrentBatchId()
            .flatMap { id in
                return self.getNewBatchIds(previousBatchId: id)
            }
            .flatMap { ids -> AnyPublisher<String, Error> in
                ids.publisher
                    .setFailureType(to: Error.self)
                    .flatMap(maxPublishers: .max(2)) { self.downloadBatchFile(id: $0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getCurrentBatchId() -> AnyPublisher<String, Error> {
        Log.d("Get current batch id")
        if let batchId = getLocallyStoredBatchId() {
            Log.d("Found local batch id \(batchId)")
            return Just(batchId).setFailureType(to: Error.self).eraseToAnyPublisher()
        } else {
            Log.d("Didn't find local batch id")
            return backend.getCurrentBatchId().map { id in
                self.storeBatchIdLocally(id: id.current)
                return id.current
            }.eraseToAnyPublisher()
        }
    }
    
    private func getNewBatchIds(previousBatchId: String) -> AnyPublisher<[String], Error> {
        return backend.getNewBatchIds(since: previousBatchId)
            .map { $0.batches }
            .eraseToAnyPublisher()
    }
    
    private func downloadBatchFile(id batchId: String) -> AnyPublisher<String, Error> {
        return backend.getBatchFile(id: batchId).tryMap { data in
            try self.storage.`import`(batchId: batchId, data: data)
        }.eraseToAnyPublisher()
    }
        
    private func storeBatchIdLocally(id: String) {
        Log.d("Storing batch id: \(id)")
        cache.nextDiagnosisKeyFileIndex = id
    }
    
    private func getLocallyStoredBatchId() -> String? {
        return cache.nextDiagnosisKeyFileIndex
    }
}
