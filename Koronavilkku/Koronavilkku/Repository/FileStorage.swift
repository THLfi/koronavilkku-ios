import Combine
import Foundation

protocol FileStorage {
    func `import`(batchId: String, data: Data) throws -> String
    func getFileUrls(forBatchId id: String) -> [URL]
    func deleteAllBatches()
    func write<T: Codable>(object: T, to filename: String) -> Bool
    func read<T: Codable>(from filename: String) -> T?
}

class FileStorageImpl : FileStorage {
    enum Directories {
        case batches
        case objects
        
        var url: URL {
            switch self {
            case .batches:
                return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("batches", isDirectory: true)
            case .objects:
                return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("objects", isDirectory: true)
            }
        }
    }
    
    let fileHelper = FileHelper()
    
    init() {
        try? FileManager.default.createDirectory(atPath: Directories.batches.url.path,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        try? FileManager.default.createDirectory(atPath: Directories.objects.url.path,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
    }

    func `import`(batchId: String, data: Data) throws -> String {
        guard let fileUrl = self.fileHelper.createFile(name: "\(batchId)", extension: "zip", data: data, relativeTo: Directories.batches.url) else {
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
    }

    func getFileUrls(forBatchId id: String) -> [URL] {
        if let urls = fileHelper.getListOfFileUrlsInDirectory(directoryUrl: Directories.batches.url.appendingPathComponent(id)) {
            return urls
        }
        return []
    }

    func deleteAllBatches() {
        if let files = fileHelper.getListOfFileBatchUrls(in: Directories.batches.url) {
            Log.d("Delete all batch files")
            fileHelper.deleteFiles(urls: files)
        } else {
            Log.d("Nothing to delete")
        }
    }
    
    func write<T: Codable>(object: T, to filename: String) -> Bool {
        if let data = try? JSONEncoder().encode(object) {
            if let _ = self.fileHelper.createFile(name: filename,
                                                  extension: "json",
                                                  data: data,
                                                  relativeTo: Directories.objects.url) {
                Log.d("Municipality contact info written to \(filename)")
                return true
            }
        }
        
        return false
    }
    
    func read<T: Codable>(from filename: String) -> T? {
        guard let data = fileHelper.readFile(name: filename, extension: "json", relativeTo: Directories.objects.url) else {
            return nil
        }
        
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
