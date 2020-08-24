import Combine
import Foundation

struct DiagnosisPublishRequest : Encodable {
    let keys: [TemporaryExposureKey]
}

protocol BatchRepository {
    func getNewBatches() -> AnyPublisher<String, Error>
    func ensureCurrentBatchIdDefined()
}

enum BatchError: Error {
    case writingZipFailed
    case unzippingFailed
    case noFilesFound
}

class BatchRepositoryImpl: BatchRepository {
    private let backend: Backend
    private let fileHelper: FileHelper
    private let BATCH_ID_KEY = "BATCH_ID"
    private var tasks = [AnyCancellable]()
    
    init(backend: Backend, fileHelper: FileHelper) {
        self.backend = backend
        self.fileHelper = fileHelper
    }

    func getNewBatches() -> AnyPublisher<String, Error> {
        return getCurrentBatchId()
            .flatMap { id in
                return self.getNewBatchIds(previousBatchId: id)
            }
            .flatMap { ids -> AnyPublisher<String, Error> in
                    let publishers = ids.map { id in
                        return self.getBatchFile(id: id)
                    }
                    return publishers.publisher
                        .setFailureType(to: Error.self)
                        .flatMap { $0 }
                        .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    func ensureCurrentBatchIdDefined() {
        getCurrentBatchId()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &tasks)
    }
    
    private func getCurrentBatchId() -> AnyPublisher<String, Error> {
        Log.d("Get current batch id")
        if let batchId = getLocallyStoredBatchId() {
            Log.d("Found local batch id \(batchId)")
            return Just(batchId).setFailureType(to: Error.self).eraseToAnyPublisher()
        } else {
            Log.d("Didn't find local batch id")
            return backend.call(endpoint: .getCurrentBatchId).map { (id: CurrentBatchId) in
                self.storeBatchIdLocally(id: id.current)
                return id.current
            }.eraseToAnyPublisher()
        }
    }
    
    private func getNewBatchIds(previousBatchId: String) -> AnyPublisher<[String], Error> {
        return backend.call(endpoint: .getNewBatchIds(since: previousBatchId))
            .map { (ids: BatchIds) in
                return ids.batches
            }
            .eraseToAnyPublisher()
    }
    
    private func getBatchFile(id batchId: String) -> AnyPublisher<String, Error> {
        return backend.call(endpoint: .getBatchFile(id: batchId)).tryMap { data in
            
            guard let fileUrl = self.fileHelper.createFile(name: "\(batchId)", extension: "zip", data: data) else {
                Log.e("Writing zip to disk failed")
                throw BatchError.writingZipFailed
            }
            
            guard let unzipUrl = self.fileHelper.decompressZip(fileUrl: fileUrl) else {
                Log.e("Unzipping failed")
                throw BatchError.unzippingFailed
            }
            
            guard let unzippedFileUrls = self.fileHelper.getListOfFileUrlsInDirectory(directoryUrl: unzipUrl) else {
                Log.e("Couldn't find files in directory \(unzipUrl)")
                throw BatchError.noFilesFound
            }
            
            // Rename the files based on the batch id
            unzippedFileUrls.forEach { url in
                self.fileHelper.renameFile(newName: batchId, fileUrl: url)
            }
            
            return batchId
        }.eraseToAnyPublisher()
    }
        
    private func storeBatchIdLocally(id: String) {
        Log.d("Storing batch id: \(id)")
        LocalStore.shared.nextDiagnosisKeyFileIndex = id
    }
    
    private func getLocallyStoredBatchId() -> String? {
        return LocalStore.shared.nextDiagnosisKeyFileIndex
    }
}
